return {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        local lint = require 'lint'

        -- Helper function to check if a command exists
        local function command_exists(cmd)
            local handle = io.popen('command -v ' .. cmd .. ' >/dev/null 2>&1 && echo "true" || echo "false"')
            if handle then
                local result = handle:read("*a")
                handle:close()
                return result:match("true") ~= nil
            end
            return false
        end

        -- Only enable linters that are installed
        local linters = {}
        if command_exists('eslint') then
            linters.javascript = { 'eslint' }
            linters.typescript = { 'eslint' }
            linters.javascriptreact = { 'eslint' }
            linters.typescriptreact = { 'eslint' }
        end
        if command_exists('markdownlint') then
            linters.markdown = { 'markdownlint' }
        end
        if command_exists('jsonlint') then
            linters.json = { 'jsonlint' }
        end

        lint.linters_by_ft = linters

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

        -- Add a command to check linter status
        vim.api.nvim_create_user_command('LintStatus', function()
            local ft = vim.bo.filetype
            if not linters[ft] then
                print("No linters configured for " .. ft)
            else
                print("Configured linters for " .. ft .. ": " .. table.concat(linters[ft], ", "))
            end
        end, { desc = 'Show linter status for current filetype' })
    end,
}