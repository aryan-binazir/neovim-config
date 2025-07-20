return {
    "windwp/nvim-ts-autotag",
    event = "InsertEnter",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = true,
        filetypes = {
            -- HTML and XML
            'html',
            'xml',
            
            -- JavaScript/TypeScript
            'javascript',
            'typescript',
            
            -- JSX/TSX files
            'javascriptreact', -- .jsx files
            'typescriptreact', -- .tsx files
            'jsx',
            'tsx',
            
            -- Markdown (for HTML in markdown)
            'markdown',
            
            -- Other supported filetypes (commented for reference)
            -- 'vue',         -- Vue components
            -- 'svelte',      -- Svelte components
            -- 'php',         -- PHP with HTML
            -- 'astro',       -- Astro components
            -- 'eruby',       -- Ruby ERB templates
            -- 'ejs',         -- Embedded JS templates
            -- 'heex',        -- Phoenix/Elixir templates
        },
    },
}
