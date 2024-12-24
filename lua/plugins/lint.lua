return {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        local lint = require 'lint'

        lint.linters_by_ft = {
            javascript = { 'eslint' },
            typescript = { 'eslint' },
            javascriptreact = { 'eslint' },
            typescriptreact = { 'eslint' },
            markdown = { 'markdownlint' },
            json = { 'jsonlint' },
        }

        -- Create autocommand which carries out the actual linting
        local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
            group = lint_augroup,
            callback = function()
                -- Only run the linter in buffers that you can modify
                if vim.opt_local.modifiable:get() then
                    lint.try_lint()
                end
            end,
        })

        -- Add a command to manually trigger linting
        vim.api.nvim_create_user_command('Lint', function()
            lint.try_lint()
        end, { desc = 'Trigger linting for current file' })
    end,
}