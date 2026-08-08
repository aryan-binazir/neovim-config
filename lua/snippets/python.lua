local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

-- Python snippets
ls.add_snippets("python", {
	-- Functions and classes
	s("def", {
		t("def "),
		i(1, "function_name"),
		t("("),
		i(2),
		t("):"),
		t({ "", "    " }),
		i(3, "pass"),
	}),
	s("class", {
		t("class "),
		i(1, "ClassName"),
		t("("),
		i(2, "object"),
		t("):"),
		t({ "", '    """' }),
		i(3, "Class description"),
		t({ '"""', "    ", "    def __init__(self" }),
		i(4),
		t("):"),
		t({ "", "        " }),
		i(5, "pass"),
	}),
	s("init", {
		t("def __init__(self"),
		i(1),
		t("):"),
		t({ "", "    " }),
		i(2, "pass"),
	}),

	-- Control flow
	s("if", {
		t("if "),
		i(1, "condition"),
		t(":"),
		t({ "", "    " }),
		i(2, "pass"),
	}),
	s("ife", {
		t("if "),
		i(1, "condition"),
		t(":"),
		t({ "", "    " }),
		i(2),
		t({ "", "else:", "    " }),
		i(3, "pass"),
	}),
	s("elif", {
		t("elif "),
		i(1, "condition"),
		t(":"),
		t({ "", "    " }),
		i(2, "pass"),
	}),

	-- Loops
	s("for", {
		t("for "),
		i(1, "item"),
		t(" in "),
		i(2, "iterable"),
		t(":"),
		t({ "", "    " }),
		i(3, "pass"),
	}),
	s("while", {
		t("while "),
		i(1, "condition"),
		t(":"),
		t({ "", "    " }),
		i(2, "pass"),
	}),

	-- Exception handling
	s("try", {
		t("try:"),
		t({ "", "    " }),
		i(1),
		t({ "", "except " }),
		i(2, "Exception as e"),
		t(":"),
		t({ "", "    " }),
		i(3, "pass"),
	}),
	s("except", {
		t("except "),
		i(1, "Exception as e"),
		t(":"),
		t({ "", "    " }),
		i(2, "pass"),
	}),

	-- Context managers
	s("with", {
		t("with "),
		i(1, 'open("file.txt")'),
		t(" as "),
		i(2, "f"),
		t(":"),
		t({ "", "    " }),
		i(3, "pass"),
	}),

	-- Imports
	s("from", {
		t("from "),
		i(1, "module"),
		t(" import "),
		i(2, "function"),
	}),

	-- Common patterns
	s("main", {
		t("if __name__ == '__main__':"),
		t({ "", "    " }),
		i(1, "main()"),
	}),
	-- Testing
	s("test", {
		t("def test_"),
		i(1, "function_name"),
		t("(self):"),
		t({ "", "    " }),
		i(2, "assert True"),
	}),
	s("assert", {
		t("assert "),
		i(1, "condition"),
		t(', "'),
		i(2, "Error message"),
		t('"'),
	}),
})
