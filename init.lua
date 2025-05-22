require('options')
require('keymaps')

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    }
end
vim.opt.rtp:prepend(lazypath)

-- Ensure Copilot starts disabled, enable when needed
vim.g.copilot_enabled = false
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.defer_fn(function()
            vim.cmd("Copilot disable", { silent = true })
        end, 200)
    end,
})

require('lazy').setup({
    spec = {
        { import = "plugins" },
    },
    change_detection = {
        notify = false,
    },
})
