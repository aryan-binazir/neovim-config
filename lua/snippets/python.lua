local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require('luasnip.extras.fmt').fmt

-- Python snippets
ls.add_snippets('python', {
  -- Functions and classes
  s('def', {
    t('def '), i(1, 'function_name'), t('('), i(2), t('):'), t({'', '    '}), i(3, 'pass')
  }),
  s('class', {
    t('class '), i(1, 'ClassName'), t('('), i(2, 'object'), t('):'), t({'', '    """'}), i(3, 'Class description'), t({'"""', '    ', '    def __init__(self'}), i(4), t('):'), t({'', '        '}), i(5, 'pass')
  }),
  s('init', {
    t('def __init__(self'), i(1), t('):'), t({'', '    '}), i(2, 'pass')
  }),

  -- Control flow
  s('if', {
    t('if '), i(1, 'condition'), t(':'), t({'', '    '}), i(2, 'pass')
  }),
  s('ife', {
    t('if '), i(1, 'condition'), t(':'), t({'', '    '}), i(2), t({'', 'else:', '    '}), i(3, 'pass')
  }),
  s('elif', {
    t('elif '), i(1, 'condition'), t(':'), t({'', '    '}), i(2, 'pass')
  }),

  -- Loops
  s('for', {
    t('for '), i(1, 'item'), t(' in '), i(2, 'iterable'), t(':'), t({'', '    '}), i(3, 'pass')
  }),
  s('while', {
    t('while '), i(1, 'condition'), t(':'), t({'', '    '}), i(2, 'pass')
  }),

  -- Exception handling
  s('try', {
    t('try:'), t({'', '    '}), i(1), t({'', 'except '}), i(2, 'Exception as e'), t(':'), t({'', '    '}), i(3, 'pass')
  }),
  s('except', {
    t('except '), i(1, 'Exception as e'), t(':'), t({'', '    '}), i(2, 'pass')
  }),

  -- Context managers
  s('with', {
    t('with '), i(1, 'open("file.txt")'), t(' as '), i(2, 'f'), t(':'), t({'', '    '}), i(3, 'pass')
  }),

  -- Imports
  s('import', {
    t('import '), i(1, 'module')
  }),
  s('from', {
    t('from '), i(1, 'module'), t(' import '), i(2, 'function')
  }),

  -- Common patterns
  s('main', {
    t('if __name__ == "__main__":'), t({'', '    '}), i(1, 'main()')
  }),
  s('print', {
    t('print('), i(1), t(')')
  }),

  -- Data structures
  s('list', {
    t('['), i(1), t(']')
  }),
  s('dict', {
    t('{'), i(1, '"key": "value"'), t('}')
  }),
  s('tuple', {
    t('('), i(1), t(',)')
  }),

  -- String operations
  s('fstr', {
    t('f"'), i(1), t('"')
  }),

  -- Testing
  s('test', {
    t('def test_'), i(1, 'function_name'), t('(self):'), t({'', '    '}), i(2, 'assert True')
  }),
  s('assert', {
    t('assert '), i(1, 'condition'), t(', "'), i(2, 'Error message'), t('"')
  }),

  -- Common variables
  s('name', t('__name__')),
  s('file', t('__file__')),
  s('doc', t('__doc__')),
})