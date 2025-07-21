local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local fmt = require('luasnip.extras.fmt').fmt

-- JavaScript snippets
ls.add_snippets('javascript', {
  -- Console logs
  s('cl', fmt('console.log({})', { i(1) })),
  s('ce', fmt('console.error({})', { i(1) })),
  s('cw', fmt('console.warn({})', { i(1) })),
  s('cd', fmt('console.debug({})', { i(1) })),
  s('ct', fmt('console.table({})', { i(1) })),
  s('ctime',
    fmt('console.time("{}");\n{}\nconsole.timeEnd("{}")',
      { i(1, 'timer'), i(2), f(function(args) return args[1][1] end, { 1 }) })),

  -- Functions
  s('fn', fmt('function {}({}) {{\n  {}\n}}', { i(1, 'name'), i(2), i(3) })),
  s('af', fmt('const {} = ({}) => {{\n  {}\n}}', { i(1, 'name'), i(2), i(3) })),
  s('afn', fmt('const {} = ({}) => {}', { i(1, 'name'), i(2), i(3) })),
  s('iife', fmt('(function({}) {{\n  {}\n}})({})', { i(1), i(2), i(3) })),

  -- Variables
  s('const', fmt('const {} = {}', { i(1), i(2) })),
  s('let', fmt('let {} = {}', { i(1), i(2) })),

  -- Control flow
  s('if', fmt('if ({}) {{\n  {}\n}}', { i(1), i(2) })),
  s('ife', fmt('if ({}) {{\n  {}\n}} else {{\n  {}\n}}', { i(1), i(2), i(3) })),
  s('ei', fmt('else if ({}) {{\n  {}\n}}', { i(1), i(2) })),
  s('ter', fmt('{} ? {} : {}', { i(1), i(2), i(3) })),
  s('switch', fmt('switch ({}) {{\n  case {}:\n    {}\n    break;\n  default:\n    {}\n}}', { i(1), i(2), i(3), i(4) })),
  s('case', fmt('case {}:\n  {}\n  break;', { i(1), i(2) })),

  -- Loops
  s('for',
    fmt('for (let {} = 0; {} < {}; {}++) {{\n  {}\n}}',
      { i(1, 'i'), f(function(args) return args[1][1] end, { 1 }), i(2), f(function(args) return args[1][1] end, { 1 }),
        i(3) })),
  s('forin', fmt('for (const {} in {}) {{\n  {}\n}}', { i(1, 'key'), i(2), i(3) })),
  s('forof', fmt('for (const {} of {}) {{\n  {}\n}}', { i(1, 'item'), i(2), i(3) })),
  s('while', fmt('while ({}) {{\n  {}\n}}', { i(1), i(2) })),
  s('do', fmt('do {{\n  {}\n}} while ({})', { i(1), i(2) })),

  -- Array methods
  s('map', fmt('{}.map(({}) => {})', { i(1), i(2, 'item'), i(3) })),
  s('filter', fmt('{}.filter(({}) => {})', { i(1), i(2, 'item'), i(3) })),
  s('reduce', fmt('{}.reduce(({}, {}) => {}, {})', { i(1), i(2, 'acc'), i(3, 'item'), i(4), i(5) })),
  s('find', fmt('{}.find(({}) => {})', { i(1), i(2, 'item'), i(3) })),
  s('forEach', fmt('{}.forEach(({}) => {{\n  {}\n}})', { i(1), i(2, 'item'), i(3) })),
  s('some', fmt('{}.some(({}) => {})', { i(1), i(2, 'item'), i(3) })),
  s('every', fmt('{}.every(({}) => {})', { i(1), i(2, 'item'), i(3) })),

  -- Promises and async
  s('promise', fmt('new Promise(({}, {}) => {{\n  {}\n}})', { i(1, 'resolve'), i(2, 'reject'), i(3) })),
  s('then', fmt('.then(({}) => {{\n  {}\n}})', { i(1, 'result'), i(2) })),
  s('catch', fmt('.catch(({}) => {{\n  {}\n}})', { i(1, 'error'), i(2) })),
  s('async', fmt('async function {}({}) {{\n  {}\n}}', { i(1, 'name'), i(2), i(3) })),
  s('await', fmt('await {}', { i(1) })),
  s('trycatch', fmt('try {{\n  {}\n}} catch ({}) {{\n  {}\n}}', { i(1), i(2, 'error'), i(3) })),

  -- Classes
  s('class',
    fmt('class {} {{\n  constructor({}) {{\n    {}\n  }}\n\n  {}({}) {{\n    {}\n  }}\n}}',
      { i(1, 'ClassName'), i(2), i(3), i(4, 'method'), i(5), i(6) })),
  s('constructor', fmt('constructor({}) {{\n  {}\n}}', { i(1), i(2) })),
  s('method', fmt('{}({}) {{\n  {}\n}}', { i(1, 'methodName'), i(2), i(3) })),

  -- Objects
  s('obj', fmt('const {} = {{\n  {}: {},\n}}', { i(1, 'obj'), i(2, 'key'), i(3, 'value') })),
  s('objm', fmt('{}({}) {{\n  {}\n}}', { i(1, 'methodName'), i(2), i(3) })),

  -- Imports/Exports
  s('imp', fmt("import {} from '{}'", { i(1), i(2) })),
  s('impd', fmt("import {{ {} }} from '{}'", { i(1), i(2) })),
  s('impa', fmt("import * as {} from '{}'", { i(1), i(2) })),
  s('exp', fmt('export const {} = {}', { i(1), i(2) })),
  s('expd', fmt('export default {}', { i(1) })),
  s('rexp', fmt('module.exports = {}', { i(1) })),
  s('req', fmt("const {} = require('{}')", { i(1), i(2) })),

  -- JSDoc
  s('jsdoc', fmt([[
/**
 * {}
 * @param {{{}}} {} - {}
 * @returns {{{}}} {}
 */]],
    { i(1, 'Description'), i(2, 'type'), i(3, 'param'), i(4, 'Parameter description'), i(5, 'type'), i(6,
      'Return description') })),

  -- React specific
  s('useState', fmt('const [{}, set{}] = useState({})', {
    i(1, 'state'),
    f(function(args) return args[1][1]:sub(1, 1):upper() .. args[1][1]:sub(2) end, { 1 }),
    i(2, 'initialValue')
  })),
  s('useEffect', fmt('useEffect(() => {{\n  {}\n}}, [{}])', { i(1), i(2) })),
  s('useContext', fmt('const {} = useContext({})', { i(1), i(2) })),
  s('useCallback', fmt('const {} = useCallback(() => {{\n  {}\n}}, [{}])', { i(1, 'memoizedCallback'), i(2), i(3) })),
  s('useMemo', fmt('const {} = useMemo(() => {{\n  return {}\n}}, [{}])', { i(1, 'memoizedValue'), i(2), i(3) })),
  s('useRef', fmt('const {} = useRef({})', { i(1, 'ref'), i(2, 'null') })),

  s('fc',
    fmt('const {} = ({}) => {{\n  {}\n  return (\n    {}\n  )\n}}',
      { i(1, 'ComponentName'), i(2, 'props'), i(3), i(4, '<div></div>') })),
  s('rfc',
    fmt('import React from "react"\n\nconst {} = ({}) => {{\n  {}\n  return (\n    {}\n  )\n}}\n\nexport default {}', {
      i(1, 'ComponentName'),
      i(2, 'props'),
      i(3),
      i(4, '<div></div>'),
      f(function(args) return args[1][1] end, { 1 })
    })),

  -- Modern ES2020+ features
  s('opt', fmt('{}?.{}', { i(1, 'obj'), i(2, 'prop') })),
  s('optcall', fmt('{}?.{}?.({})', { i(1, 'obj'), i(2, 'method'), i(3) })),
  s('nullish', fmt('{} ?? {}', { i(1, 'value'), i(2, 'defaultValue') })),
  s('dynimp', fmt('const {} = await import("{}")', { i(1, 'module'), i(2, './module') })),
  s('private', fmt('#{}', { i(1, 'fieldName') })),

  -- Enhanced destructuring
  s('destren', fmt('const {{ {}: {} }} = {}', { i(1, 'oldName'), i(2, 'newName'), i(3, 'obj') })),
  s('destnest', fmt('const {{ {}: {{ {} }} }} = {}', { i(1, 'prop'), i(2, 'nested'), i(3, 'obj') })),
  s('destdef', fmt('const {{ {} = {} }} = {}', { i(1, 'prop'), i(2, 'defaultValue'), i(3, 'obj') })),
  s('destrest', fmt('const {{ {}, ...{} }} = {}', { i(1, 'first'), i(2, 'rest'), i(3, 'obj') })),
  s('arrdes', fmt('const [{}, {}] = {}', { i(1, 'first'), i(2, 'second'), i(3, 'array') })),
  s('arrrest', fmt('const [{}, ...{}] = {}', { i(1, 'first'), i(2, 'rest'), i(3, 'array') })),

  -- Common patterns
  s('desc', fmt('const {{ {} }} = {}', { i(1), i(2) })),
  s('nf', fmt('const {} = ({}) => null', { i(1, 'ComponentName'), i(2, 'props') })),
  s('ret', fmt('return {}', { i(1) })),
  s('rett', fmt('return (\n  {}\n)', { i(1) })),
})

-- Visual selection snippets (for wrapping selected text)
ls.add_snippets('javascript', {
  s({ trig = 'waf', name = 'Wrap in arrow function', dscr = 'Wrap selection in arrow function' }, 
    fmt('({}) => {{\n  {}\n}}', { i(1, 'param'), d(1, function(_, snip) return sn(nil, { t(snip.env.LS_SELECT_RAW) }) end) }), 
    { condition = function() return vim.fn.mode() == 'v' or vim.fn.mode() == 'V' end }
  ),
  s({ trig = 'wfn', name = 'Wrap in function', dscr = 'Wrap selection in function' }, 
    fmt('function {}({}) {{\n  {}\n}}', { i(1, 'name'), i(2), d(1, function(_, snip) return sn(nil, { t(snip.env.LS_SELECT_RAW) }) end) }), 
    { condition = function() return vim.fn.mode() == 'v' or vim.fn.mode() == 'V' end }
  ),
  s({ trig = 'wcl', name = 'Wrap in console.log', dscr = 'Wrap selection in console.log' }, 
    fmt('console.log({})', { d(1, function(_, snip) return sn(nil, { t(snip.env.LS_SELECT_RAW) }) end) }), 
    { condition = function() return vim.fn.mode() == 'v' or vim.fn.mode() == 'V' end }
  ),
  s({ trig = 'wtry', name = 'Wrap in try/catch', dscr = 'Wrap selection in try/catch' }, 
    fmt('try {{\n  {}\n}} catch ({}) {{\n  {}\n}}', { 
      d(1, function(_, snip) return sn(nil, { t(snip.env.LS_SELECT_RAW) }) end),
      i(1, 'error'),
      i(2, 'console.error(error)')
    }), 
    { condition = function() return vim.fn.mode() == 'v' or vim.fn.mode() == 'V' end }
  ),
  s({ trig = 'wif', name = 'Wrap in if', dscr = 'Wrap selection in if statement' }, 
    fmt('if ({}) {{\n  {}\n}}', { 
      i(1, 'condition'), 
      d(1, function(_, snip) return sn(nil, { t(snip.env.LS_SELECT_RAW) }) end) 
    }), 
    { condition = function() return vim.fn.mode() == 'v' or vim.fn.mode() == 'V' end }
  ),
}, { type = "autosnippets" })

-- Also add the same snippets for TypeScript with type annotations
ls.add_snippets('typescript', {
  -- All JavaScript snippets work in TypeScript
})

-- TypeScript specific snippets
ls.add_snippets('typescript', {
  -- Types and interfaces
  s('interface', fmt('interface {} {{\n  {}: {};\n}}', { i(1, 'InterfaceName'), i(2, 'property'), i(3, 'type') })),
  s('type', fmt('type {} = {}', { i(1, 'TypeName'), i(2, 'string') })),
  s('enum', fmt('enum {} {{\n  {} = "{}",\n}}', { i(1, 'EnumName'), i(2, 'VALUE'), i(3, 'value') })),

  -- Typed functions
  s('tfn', fmt('function {}({}): {} {{\n  {}\n}}', { i(1, 'name'), i(2, 'param: type'), i(3, 'returnType'), i(4) })),
  s('taf', fmt('const {} = ({}): {} => {{\n  {}\n}}', { i(1, 'name'), i(2, 'param: type'), i(3, 'returnType'), i(4) })),
  s('tafn', fmt('const {} = ({}): {} => {}', { i(1, 'name'), i(2, 'param: type'), i(3, 'returnType'), i(4) })),

  -- Generic types
  s('generic', fmt('<{}>{}', { i(1, 'T'), i(2) })),
  s('gfn', fmt('function {}<{}>({}) {{\n  {}\n}}', { i(1, 'name'), i(2, 'T'), i(3, 'param: T'), i(4) })),

  -- React TypeScript
  s('tfc',
    fmt(
    'interface {}Props {{\n  {}: {};\n}}\n\nconst {}: React.FC<{}Props> = ({{ {} }}) => {{\n  {}\n  return (\n    {}\n  )\n}}',
      {
        i(1, 'Component'),
        i(2, 'prop'),
        i(3, 'string'),
        f(function(args) return args[1][1] end, { 1 }),
        f(function(args) return args[1][1] end, { 1 }),
        f(function(args) return args[2][1] end, { 2 }),
        i(4),
        i(5, '<div></div>')
      })),

  s('props', fmt('interface Props {{\n  {}: {};\n}}', { i(1, 'prop'), i(2, 'string') })),

  -- Utility types
  s('partial', fmt('Partial<{}>', { i(1) })),
  s('required', fmt('Required<{}>', { i(1) })),
  s('readonly', fmt('Readonly<{}>', { i(1) })),
  s('record', fmt('Record<{}, {}>', { i(1, 'string'), i(2, 'any') })),
  s('pick', fmt('Pick<{}, {}>', { i(1), i(2) })),
  s('omit', fmt('Omit<{}, {}>', { i(1), i(2) })),
})

-- Copy JavaScript snippets to TypeScript as well
for _, snippet in ipairs(ls.get_snippets('javascript')) do
  ls.add_snippets('typescript', { snippet })
end

-- Also add snippets for JSX/TSX files
ls.add_snippets('javascriptreact', ls.get_snippets('javascript'))
ls.add_snippets('typescriptreact', ls.get_snippets('typescript'))

