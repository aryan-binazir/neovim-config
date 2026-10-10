#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
p = Path(os.environ['PANE_FIXTURE'])
s = json.loads(p.read_text())
a = sys.argv[1:]
s.setdefault('calls', []).append(a)
backend = Path(sys.argv[0]).name
s.setdefault('backends', []).append(backend)
out = ''
code = 0
if backend == 'tmux':
    op = a[0]
    if op == 'list-panes':
        out = '\n'.join(k+'\t'+v['tool'] for k,v in s['panes'].items())
    elif op == 'display-message':
        target = a[a.index('-t')+1]
        if target not in s['panes']: code = 1
        elif a[-1] == '#{pane_id}': out = target
        else:
            s['polls'] = s.get('polls',0)+1
            out = 'bash' if s.get('never_ready') or s['polls'] <= s.get('shell_polls',0) else 'python3'
    elif op == 'split-window':
        if s.get('split_fail'): code = 1; out = 'split failed'
        else:
            s['next'] += 1; out = '%'+str(s['next'])
            s['panes'][out] = {'tool':''}
    elif op == 'set-option':
        s['panes'][a[a.index('-t')+1]]['tool'] = a[-1]
        if s.get('mark_fail'): code = 1
    elif op == 'kill-pane': s['panes'].pop(a[-1],None)
    elif op == 'send-keys':
        if s.get('send_fail'): code = 1; out = 'send failed'
        else: s.setdefault('sent',[]).append({'target':a[a.index('-t')+1],'text':a[-1],'kind':'reference'})
    elif op == 'load-buffer': s['buffer'] = sys.stdin.read()
    elif op == 'paste-buffer': s.setdefault('sent',[]).append({'target':a[-1],'text':s.pop('buffer',''),'kind':'block'})
    elif op == 'select-pane' and '-T' not in a: s['focus'] = a[-1]
elif backend == 'herdr':
    kind, op = a[:2]
    if (kind,op) == ('pane','list'):
        out = json.dumps({'result':{'panes':[dict(pane_id=k, label='nvim-ai-source-'+v['tool'],tab_id=v.get('tab','tab')) for k,v in s['panes'].items()]}})
    elif (kind,op) == ('pane','get'):
        out = json.dumps({'result':{'pane':{'pane_id':a[2]}}}) if a[2] in s['panes'] else '{}'
    elif op == 'split':
        if s.get('split_fail'): code = 1; out = 'split failed'
        else:
            s['next'] += 1; target = 'pane-'+str(s['next']); s['panes'][target] = {'tool':''}
            out = json.dumps({'result':{'pane':{'pane_id':target}}})
    elif op == 'rename':
        s['panes'][a[2]]['tool'] = a[3].removeprefix('nvim-ai-source-')
        if s.get('mark_fail'): code = 1
    elif op == 'run':
        if s.get('run_fail'): code = 1; out = 'run failed'
    elif op == 'close': s['panes'].pop(a[2],None)
    elif (kind,op) == ('agent','get'):
        s['polls'] = s.get('polls',0)+1
        out = '{}' if s.get('never_ready') or s['polls'] <= s.get('shell_polls',0) else json.dumps({'result':{'agent':{'pane_id':a[2]}}})
    elif op == 'send-text':
        if s.get('send_fail'): code = 1; out = 'send failed'
        else: s.setdefault('sent',[]).append({'target':a[2],'text':a[3],'kind':'text'})
    elif op == 'focus': s['focus'] = a[2]
p.write_text(json.dumps(s))
print(out)
sys.exit(code)
'''

def run():
    with tempfile.TemporaryDirectory(prefix='pane-delivery-') as tmp:
        path = Path(tmp)
        for backend in ('tmux', 'herdr'):
            executable = path / backend
            executable.write_text('#!'+sys.executable+'\n'+FIXTURE.split('\n',1)[1])
            executable.chmod(0o755)
        for backend in ('tmux', 'herdr'):
            clean_env = {k:v for k,v in os.environ.items() if not k.startswith(('TMUX', 'HERDR'))}
            env = dict(clean_env, PATH=str(path)+os.pathsep+os.environ['PATH'],
                       PANE_FIXTURE=str(path/'state.json'), PANE_BACKEND=backend,
                       PANE_TEST_ROOT=str(ROOT), PANE_TEST_TMP=tmp,
                       HERDR_ENV='1' if backend == 'herdr' else '0',
                       HERDR_PANE_ID='source', HERDR_WORKSPACE_ID='workspace', HERDR_TAB_ID='tab',
                       XDG_CACHE_HOME=str(path/'cache'), XDG_STATE_HOME=str(path/'state'),
                       XDG_DATA_HOME=str(path/'data'), NVIM_LOG_FILE=str(path/'nvim.log'))
            subprocess.run(['nvim','--headless','-u','NONE','-i','NONE','-l',str(ROOT/'tests/pane_delivery.lua')],
                           cwd=ROOT, env=env, check=True, timeout=100)
    print('PASS external CLI fixtures; temporary files removed')

if __name__ == '__main__':
    run()
