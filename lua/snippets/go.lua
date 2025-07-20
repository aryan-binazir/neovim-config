local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local fmt = require('luasnip.extras.fmt').fmt

-- Go snippets
ls.add_snippets('go', {
  -- Error handling (the famous Go pattern!)
  s('iferr', fmt('if err != nil {{\n\t{}\n}}', { 
    c(1, {
      t('return err'),
      t('return nil, err'),
      t('log.Fatal(err)'),
      t('panic(err)'),
      t('log.Println(err)'),
      i(1, 'return')
    })
  })),
  
  s('errcheck', fmt('if err := {}; err != nil {{\n\t{}\n}}', { i(1), i(2, 'return err') })),

  -- Functions
  s('fn', fmt('func {}({}) {} {{\n\t{}\n}}', { i(1, 'name'), i(2), i(3, 'error'), i(4) })),
  s('fnv', fmt('func {}({}) {{\n\t{}\n}}', { i(1, 'name'), i(2), i(3) })),
  s('main', fmt('func main() {{\n\t{}\n}}', { i(1) })),
  s('init', fmt('func init() {{\n\t{}\n}}', { i(1) })),

  -- Method
  s('method', fmt('func ({} {}) {}({}) {} {{\n\t{}\n}}', { 
    i(1, 'r'), i(2, 'Receiver'), i(3, 'MethodName'), i(4), i(5, 'error'), i(6) 
  })),

  -- Structs and interfaces
  s('struct', fmt('type {} struct {{\n\t{} {}\n}}', { i(1, 'Name'), i(2, 'field'), i(3, 'string') })),
  s('interface', fmt('type {} interface {{\n\t{}({}) {}\n}}', { 
    i(1, 'Name'), i(2, 'Method'), i(3), i(4, 'error') 
  })),

  -- Control flow
  s('if', fmt('if {} {{\n\t{}\n}}', { i(1, 'condition'), i(2) })),
  s('ife', fmt('if {} {{\n\t{}\n}} else {{\n\t{}\n}}', { i(1, 'condition'), i(2), i(3) })),
  s('switch', fmt('switch {} {{\ncase {}:\n\t{}\ndefault:\n\t{}\n}}', { i(1), i(2), i(3), i(4) })),
  s('select', fmt('select {{\ncase {}:\n\t{}\ndefault:\n\t{}\n}}', { i(1), i(2), i(3) })),

  -- Loops
  s('for', fmt('for {} {{\n\t{}\n}}', { i(1, 'condition'), i(2) })),
  s('fori', fmt('for {} := {}; {} < {}; {}++ {{\n\t{}\n}}', { 
    i(1, 'i'), i(2, '0'), f(function(args) return args[1][1] end, {1}), i(3, 'len'), 
    f(function(args) return args[1][1] end, {1}), i(4) 
  })),
  s('forr', fmt('for {}, {} := range {} {{\n\t{}\n}}', { i(1, 'i'), i(2, 'v'), i(3), i(4) })),
  s('forkv', fmt('for {}, {} := range {} {{\n\t{}\n}}', { i(1, 'key'), i(2, 'value'), i(3), i(4) })),

  -- Goroutines and channels
  s('go', fmt('go func() {{\n\t{}\n}}()', { i(1) })),
  s('gof', fmt('go {}({})', { i(1, 'function'), i(2) })),
  s('ch', fmt('make(chan {})', { i(1, 'int') })),
  s('chb', fmt('make(chan {}, {})', { i(1, 'int'), i(2, '1') })),
  s('close', fmt('close({})', { i(1, 'ch') })),

  -- Defer
  s('defer', fmt('defer func() {{\n\t{}\n}}()', { i(1) })),
  s('deferf', fmt('defer {}({})', { i(1, 'function'), i(2) })),

  -- Variables and constants
  s('var', fmt('var {} {}', { i(1, 'name'), i(2, 'type') })),
  s('const', fmt('const {} = {}', { i(1, 'name'), i(2, 'value') })),
  s(':=', fmt('{} := {}', { i(1, 'name'), i(2, 'value') })),

  -- Package and imports
  s('package', fmt('package {}', { i(1, 'main') })),
  s('import', fmt('import "{}"', { i(1) })),
  s('imports', fmt('import (\n\t"{}"\n)', { i(1) })),

  -- Common patterns
  s('make', fmt('make({}, {})', { i(1, 'map[string]int'), i(2, '0') })),
  s('new', fmt('new({})', { i(1, 'Type') })),
  s('append', fmt('append({}, {})', { i(1, 'slice'), i(2, 'item') })),
  s('len', fmt('len({})', { i(1) })),
  s('cap', fmt('cap({})', { i(1) })),

  -- Testing
  s('test', fmt('func Test{}(t *testing.T) {{\n\t{}\n}}', { i(1, 'Name'), i(2) })),
  s('bench', fmt('func Benchmark{}(b *testing.B) {{\n\tfor i := 0; i < b.N; i++ {{\n\t\t{}\n\t}}\n}}', { 
    i(1, 'Name'), i(2) 
  })),

  -- HTTP
  s('http', fmt('http.HandleFunc("/{}", {})', { i(1, 'path'), i(2, 'handler') })),
  s('handler', fmt('func {}(w http.ResponseWriter, r *http.Request) {{\n\t{}\n}}', { 
    i(1, 'handler'), i(2) 
  })),

  -- JSON
  s('json', fmt('`json:"{}"`', { i(1, 'field_name') })),
  s('marshal', fmt('json.Marshal({})', { i(1) })),
  s('unmarshal', fmt('json.Unmarshal({}, &{})', { i(1, 'data'), i(2, 'v') })),

  -- Context
  s('ctx', fmt('ctx context.Context', {})),
  s('ctxval', fmt('ctx.Value({})', { i(1, 'key') })),
  s('ctxcancel', fmt('ctx, cancel := context.WithCancel({})', { i(1, 'context.Background()') })),
  s('ctxtimeout', fmt('ctx, cancel := context.WithTimeout({}, {})', { 
    i(1, 'context.Background()'), i(2, 'time.Second*30') 
  })),
})