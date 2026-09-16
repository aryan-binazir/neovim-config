local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local fmt = require("luasnip.extras.fmt").fmt

-- Rust snippets
ls.add_snippets("rust", {
	-- Functions
	s("fn", fmt("fn {}({}) {{\n\t{}\n}}", { i(1, "name"), i(2), i(3) })),
	s("fnr", fmt("fn {}({}) -> {} {{\n\t{}\n}}", { i(1, "name"), i(2), i(3, "T"), i(4) })),
	s("pfn", fmt("pub fn {}({}) -> {} {{\n\t{}\n}}", { i(1, "name"), i(2), i(3, "()"), i(4) })),
	s("afn", fmt("async fn {}({}) -> {} {{\n\t{}\n}}", { i(1, "name"), i(2), i(3, "()"), i(4) })),
	s(
		"gfn",
		fmt("fn {}<T: {}>({}: T) -> {} {{\n\t{}\n}}", { i(1, "name"), i(2, "Clone"), i(3, "value"), i(4, "T"), i(5) })
	),
	s("main", fmt("fn main() {{\n\t{}\n}}", { i(1) })),
	s("mainr", fmt("fn main() -> Result<(), Box<dyn std::error::Error>> {{\n\t{}\n\tOk(())\n}}", { i(1) })),
	s("new", fmt("pub fn new({}) -> Self {{\n\tSelf {{ {} }}\n}}", { i(1), i(2) })),
	s("closure", fmt("|{}| {}", { i(1), i(2) })),
	s("where", fmt("where\n\t{}: {},", { i(1, "T"), i(2, "Clone") })),

	-- Types
	s("struct", fmt("struct {} {{\n\t{}: {},\n}}", { i(1, "Name"), i(2, "field"), i(3, "String") })),
	s("pstruct", fmt("pub struct {} {{\n\tpub {}: {},\n}}", { i(1, "Name"), i(2, "field"), i(3, "String") })),
	s("enum", fmt("enum {} {{\n\t{},\n}}", { i(1, "Name"), i(2, "Variant") })),
	s("penum", fmt("pub enum {} {{\n\t{},\n}}", { i(1, "Name"), i(2, "Variant") })),
	s("impl", fmt("impl {} {{\n\t{}\n}}", { i(1, "Type"), i(2) })),
	s("implt", fmt("impl {} for {} {{\n\t{}\n}}", { i(1, "Trait"), i(2, "Type"), i(3) })),
	s("trait", fmt("trait {} {{\n\tfn {}(&self){};\n}}", { i(1, "Name"), i(2, "method"), i(3) })),
	s("type", fmt("type {} = {};", { i(1, "Alias"), i(2, "T") })),
	s(
		"derive",
		fmt("#[derive({})]", {
			c(1, {
				t("Debug"),
				t("Debug, Clone"),
				t("Debug, Clone, PartialEq"),
				t("Debug, Clone, PartialEq, Eq, Hash"),
				t("Debug, Default"),
				i(1, "Debug"),
			}),
		})
	),
	s(
		"display",
		fmt(
			'impl std::fmt::Display for {} {{\n\tfn fmt(&self, f: &mut std::fmt::Formatter<\'_>) -> std::fmt::Result {{\n\t\twrite!(f, "{{}}", {})\n\t}}\n}}',
			{ i(1, "Type"), i(2, "self.0") }
		)
	),

	-- Control flow
	s("if", fmt("if {} {{\n\t{}\n}}", { i(1, "condition"), i(2) })),
	s("ife", fmt("if {} {{\n\t{}\n}} else {{\n\t{}\n}}", { i(1, "condition"), i(2), i(3) })),
	s("iflet", fmt("if let {} = {} {{\n\t{}\n}}", { i(1, "Some(x)"), i(2, "value"), i(3) })),
	s("letelse", fmt("let {} = {} else {{\n\t{}\n}};", { i(1, "Some(x)"), i(2, "value"), i(3, "return") })),
	s(
		"match",
		fmt("match {} {{\n\t{} => {},\n\t_ => {},\n}}", { i(1, "value"), i(2, "pattern"), i(3), i(4, "todo!()") })
	),
	s("matchopt", fmt("match {} {{\n\tSome({}) => {},\n\tNone => {},\n}}", { i(1, "value"), i(2, "x"), i(3), i(4) })),
	s(
		"matchres",
		fmt("match {} {{\n\tOk({}) => {},\n\tErr({}) => {},\n}}", { i(1, "value"), i(2, "v"), i(3), i(4, "e"), i(5) })
	),

	-- Loops
	s("for", fmt("for {} in {} {{\n\t{}\n}}", { i(1, "item"), i(2, "iter"), i(3) })),
	s("fori", fmt("for {} in 0..{} {{\n\t{}\n}}", { i(1, "i"), i(2, "n"), i(3) })),
	s("loop", fmt("loop {{\n\t{}\n}}", { i(1) })),
	s("while", fmt("while {} {{\n\t{}\n}}", { i(1, "condition"), i(2) })),
	s("whilelet", fmt("while let {} = {} {{\n\t{}\n}}", { i(1, "Some(x)"), i(2, "iter.next()"), i(3) })),

	-- Variables
	s("let", fmt("let {} = {};", { i(1, "name"), i(2, "value") })),
	s("letm", fmt("let mut {} = {};", { i(1, "name"), i(2, "value") })),
	s("lett", fmt("let {}: {} = {};", { i(1, "name"), i(2, "T"), i(3, "value") })),
	s("const", fmt("const {}: {} = {};", { i(1, "NAME"), i(2, "T"), i(3, "value") })),
	s("static", fmt("static {}: {} = {};", { i(1, "NAME"), i(2, "T"), i(3, "value") })),

	-- Option and Result
	s("ok", fmt("Ok({})", { i(1) })),
	s("err", fmt("Err({})", { i(1) })),
	s("some", fmt("Some({})", { i(1) })),
	s("result", fmt("Result<{}, {}>", { i(1, "T"), i(2, "Error") })),
	s("boxerr", t("Box<dyn std::error::Error>")),
	s("unwrapor", fmt(".unwrap_or_else(|{}| {})", { i(1, "e"), i(2) })),
	s("maperr", fmt(".map_err(|{}| {})?", { i(1, "e"), i(2) })),
	s("okor", fmt(".ok_or({})?", { i(1, "error") })),

	-- Macros
	s("pl", fmt('println!("{{}}", {});', { i(1) })),
	s("pld", fmt('println!("{{:?}}", {});', { i(1) })),
	s("pls", fmt('println!("{}");', { i(1) })),
	s("epl", fmt('eprintln!("{{}}", {});', { i(1) })),
	s("dbg", fmt("dbg!({})", { i(1) })),
	s("fmts", fmt('format!("{}", {})', { i(1), i(2) })),
	s("vec", fmt("vec![{}]", { i(1) })),
	s("panic", fmt('panic!("{}")', { i(1, "message") })),
	s("todo", t("todo!()")),
	s("unimpl", t("unimplemented!()")),

	-- Collections and iterators
	s("hashmap", fmt("let mut {} = HashMap::new();", { i(1, "map") })),
	s("iter", fmt(".iter().map(|{}| {}).collect::<{}>()", { i(1, "x"), i(2), i(3, "Vec<_>") })),
	s("collect", fmt(".collect::<{}>()", { i(1, "Vec<_>") })),

	-- Modules and attributes
	s("mod", fmt("mod {} {{\n\t{}\n}}", { i(1, "name"), i(2) })),
	s("pmod", fmt("pub mod {};", { i(1, "name") })),
	s("use", fmt("use {};", { i(1) })),
	s("allow", fmt("#[allow({})]", { i(1, "dead_code") })),
	s("cfg", fmt("#[cfg({})]", { i(1, "test") })),
	s("doc", fmt("/// {}", { i(1, "Documentation") })),

	-- Testing
	s("test", fmt("#[test]\nfn {}() {{\n\t{}\n}}", { i(1, "name"), i(2) })),
	s(
		"testmod",
		fmt("#[cfg(test)]\nmod tests {{\n\tuse super::*;\n\n\t#[test]\n\tfn {}() {{\n\t\t{}\n\t}}\n}}", {
			i(1, "it_works"),
			i(2),
		})
	),
	s("assert", fmt("assert!({});", { i(1, "condition") })),
	s("asserteq", fmt("assert_eq!({}, {});", { i(1, "left"), i(2, "right") })),
})
