local luasnip = require('luasnip')

luasnip.snippets.javascript = {
  s("jsdoc", {
    i {
      "/**",
      " * ${1:Description}",
      " * @param {${2:type}} ${3:name} - ${4:Description of parameter}",
      " * @return {${5:type}} ${6:Description of return value}",
      " */"
    },
  })
}
