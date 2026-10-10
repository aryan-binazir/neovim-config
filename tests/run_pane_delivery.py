#!/usr/bin/env python3
import ast
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''
import json
import os
from pathlib import Path
import sys
import time

path = Path(os.environ['PANE_FIXTURE'])
state = json.loads(path.read_text())
args = sys.argv[1:]
state.setdefault('calls', []).append(args)
backend = Path(sys.argv[0]).name
state.setdefault('backends', []).append(backend)
sent_before = len(state.get('sent', []))
output = ''
code = 0
if backend == 'tmux':
    operation = args[0]
    if operation == 'list-panes':
        output = '\n'.join(target+'\t'+pane['tool'] for target, pane in state['panes'].items())
    elif operation == 'display-message':
        target = args[args.index('-t')+1]
        if target not in state['panes']:
            code = 1
        elif args[-1] == '#{pane_id}':
            output = target
        else:
            state['polls'] = state.get('polls', 0)+1
            if state.get('never_ready') or state['polls'] <= state.get('shell_polls', 0):
                output = 'bash'
            else:
                output = 'python3'
                state['ready_at'] = time.monotonic_ns()
    elif operation == 'split-window':
        if state.get('split_fail'):
            code = 1
            output = 'split failed'
        else:
            state['next'] += 1
            output = '%'+str(state['next'])
            state['panes'][output] = {'tool': ''}
    elif operation == 'set-option':
        if state.get('mark_fail'):
            code = 1
        else:
            state['panes'][args[args.index('-t')+1]]['tool'] = args[-1]
    elif operation == 'kill-pane':
        state['panes'].pop(args[-1], None)
    elif operation == 'send-keys':
        if state.get('send_fail'):
            code = 1
            output = 'send failed'
        else:
            state.setdefault('sent', []).append({'target': args[args.index('-t')+1], 'text': args[-1], 'kind': 'reference'})
    elif operation == 'load-buffer':
        state['buffer'] = sys.stdin.read()
    elif operation == 'paste-buffer':
        state.setdefault('sent', []).append({'target': args[-1], 'text': state.pop('buffer', ''), 'kind': 'block'})
    elif operation == 'select-pane' and '-T' not in args:
        state['focus'] = args[-1]
elif backend == 'herdr':
    kind, operation = args[:2]
    prefix = 'nvim-ai-'+os.environ['HERDR_PANE_ID']+'-'
    if (kind, operation) == ('pane', 'list'):
        panes = [dict(pane_id=target, label=prefix+pane['tool'], tab_id=pane.get('tab', 'tab')) for target, pane in state['panes'].items()]
        output = json.dumps({'result': {'panes': panes}})
    elif (kind, operation) == ('pane', 'get'):
        output = json.dumps({'result': {'pane': {'pane_id': args[2]}}}) if args[2] in state['panes'] else '{}'
    elif operation == 'split':
        if state.get('split_fail'):
            code = 1
            output = 'split failed'
        else:
            state['next'] += 1
            target = 'pane-'+str(state['next'])
            state['panes'][target] = {'tool': ''}
            output = json.dumps({'result': {'pane': {'pane_id': target}}})
    elif operation == 'rename':
        if state.get('mark_fail'):
            code = 1
        else:
            state['panes'][args[2]]['tool'] = args[3].removeprefix(prefix)
    elif operation == 'run':
        if state.get('run_fail'):
            code = 1
            output = 'run failed'
    elif operation == 'close':
        state['panes'].pop(args[2], None)
    elif (kind, operation) == ('agent', 'get'):
        state['polls'] = state.get('polls', 0)+1
        if state.get('never_ready') or state['polls'] <= state.get('shell_polls', 0):
            output = '{}'
        else:
            output = json.dumps({'result': {'agent': {'pane_id': args[2]}}})
            state['ready_at'] = time.monotonic_ns()
    elif operation == 'send-text':
        if state.get('send_fail'):
            code = 1
            output = 'send failed'
        else:
            state.setdefault('sent', []).append({'target': args[2], 'text': args[3], 'kind': 'text'})
    elif operation == 'focus':
        state['focus'] = args[2]
if len(state.get('sent', [])) > sent_before:
    state['sent_at'] = time.monotonic_ns()
path.write_text(json.dumps(state))
print(output)
sys.exit(code)
'''


def run():
    ast.parse(FIXTURE)
    failures = []
    with tempfile.TemporaryDirectory(prefix='pane-delivery-') as tmp:
        path = Path(tmp)
        runtime = path / 'runtime'
        runtime.mkdir(mode=0o700)
        for backend in ('tmux', 'herdr'):
            executable = path / backend
            executable.write_text('#!'+sys.executable+'\n'+FIXTURE)
            executable.chmod(0o755)
        for backend in ('tmux', 'herdr'):
            clean_env = {key: value for key, value in os.environ.items() if not key.startswith(('TMUX', 'HERDR'))}
            env = dict(clean_env, PATH=str(path)+os.pathsep+os.environ['PATH'],
                       PANE_FIXTURE=str(path/'state.json'), PANE_BACKEND=backend,
                       PANE_TEST_ROOT=str(ROOT), PANE_TEST_TMP=tmp,
                       HERDR_ENV='1' if backend == 'herdr' else '0',
                       HERDR_PANE_ID='source', HERDR_WORKSPACE_ID='workspace', HERDR_TAB_ID='tab',
                       XDG_CONFIG_HOME=str(path/'config'), XDG_RUNTIME_DIR=str(runtime),
                       XDG_CACHE_HOME=str(path/'cache'), XDG_STATE_HOME=str(path/'state'),
                       XDG_DATA_HOME=str(path/'data'), NVIM_LOG_FILE=str(path/'nvim.log'))
            try:
                result = subprocess.run(['nvim', '--headless', '-u', 'NONE', '-i', 'NONE', '-l', str(ROOT/'tests/pane_delivery.lua')],
                                        cwd=ROOT, env=env, check=False, timeout=100)
                if result.returncode:
                    failures.append(f'{backend}: exit {result.returncode}')
            except subprocess.TimeoutExpired:
                failures.append(f'{backend}: timeout')
    assert not failures, '; '.join(failures)
    print('PASS external CLI fixtures; temporary files removed')


if __name__ == '__main__':
    run()
