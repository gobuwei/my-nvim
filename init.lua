------------------------------------------------------------
-- Vim settings
------------------------------------------------------------
vim.opt.mousemoveevent = true
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.showtabline = 2
vim.opt.signcolumn = "number" -- "yes", "no", "auto", "number"
vim.diagnostic.config({
    signs = false,            -- removes the signs in the signcolumn
    virtual_text = false,     -- removes the inline text on the right
    underline = false,        -- removes the underline on the affected code
})

------------------------------------------------------------
-- Plugin installation and setup
------------------------------------------------------------
vim.pack.add({ { src = 'https://github.com/folke/lazy.nvim' }, })

require("lazy").setup({
    -- Color schemes
    { "rktjmp/lush.nvim" },
    { "ellisonleao/gruvbox.nvim",       opts = {} },
    { "xiyaowong/transparent.nvim" },   -- :TransparentTogggle

    -- LSP
    { "neovim/nvim-lspconfig" },
    { "mason-org/mason.nvim",           opts = {} },
    { "mason-org/mason-lspconfig.nvim", opts = {} },

    -- Telescope and pickers
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "make",
            },
        },
        opts = {
            defaults = {
                layout_strategy = "vertical",
                layout_config = {
                    vertical = {
                        width = 0.8,
                        height = 0.9,
                        preview_height = 0.5,
                        preview_cutoff = 0,
                    },
                },
            },
        },
    },
    { "hallestar/nvgtags.nvim" },

    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                api.config.mappings.default_on_attach(bufnr)
                -- Disable conflict keymaps in vim-tree buffer
                vim.keymap.del("n", "<Tab>", { buffer = bufnr })
                vim.keymap.del("n", "<C-]>", { buffer = bufnr })
            end,
        }
    },
    {
        'nanozuki/tabby.nvim',
        dependencies = 'nvim-tree/nvim-web-devicons',
        config = function()
            local theme = {
                fill = 'TabLineFill',
                head = 'TabLine',
                current_tab = 'TabLineSel',
                tab = 'TabLine',
                win = 'TabLine',
                tail = 'TabLine',
            }
            require('tabby').setup({
                line = function(line)
                    return {
                        {
                            { '  ', hl = { fg = '#7FBBB3', bg = '#414B50' } },
                            line.sep('', theme.head, theme.fill),
                        },
                        line.tabs().foreach(function(tab)
                            local hl = tab.is_current() and theme.current_tab or theme.tab

                            -- remove count of wins in tab with [n+] included in tab.name()
                            local name = tab.name()
                            local index = string.find(name, "%[%d")
                            local tab_name = index and string.sub(name, 1, index - 1) or name

                            -- indicate if any of buffers in tab have unsaved changes
                            local modified = false
                            local win_ids = require('tabby.module.api').get_tab_wins(tab.id)
                            for _, win_id in ipairs(win_ids) do
                                if pcall(vim.api.nvim_win_get_buf, win_id) then
                                    local bufid = vim.api.nvim_win_get_buf(win_id)
                                    if vim.api.nvim_buf_get_option(bufid, "modified") then
                                        modified = true
                                        break
                                    end
                                end
                            end

                            return {
                                line.sep('', hl, theme.fill),
                                tab.number(),
                                tab_name,
                                modified and '',
                                tab.close_btn(''),
                                line.sep('', hl, theme.fill),
                                hl = hl,
                                margin = ' ',
                            }
                        end),
                        line.spacer(),
                        {
                            line.sep('', theme.tail, theme.fill),
                            { '  ', hl = theme.tail },
                        },
                        hl = theme.fill,
                    }
                end,
            })
        end,
    },
    {
        "akinsho/bufferline.nvim",
        enabled = false,
        opts = {
            options = {
                numbers = "buffer_id",
                -- Show close sign 'x' only when hovering on
                always_show_bufferline = false,
                hover = {
                    enabled = true,
                    reveal = { 'close' }
                },
            }
        }
    },
    { "famiu/bufdelete.nvim",  enabled = false },
    { "numtostr/comment.nvim", opts = {} },
    { "karb94/neoscroll.nvim", opts = {} },

    { "liuchengxu/vista.vim",  cmd = "Vista" },
})

-- Plugin dependent settings
vim.opt.background = "dark" -- or "light" for light mode
vim.cmd.colorscheme "gruvbox"

-- Telescope
require("telescope").load_extension("fzf")
require("telescope").load_extension('nvgtags')

------------------------------------------------------------
-- Local functions
------------------------------------------------------------

local map = vim.keymap.set
local autocmd = vim.api.nvim_create_autocmd

local function cword() return vim.fn.expand("<cword>") end
local function cfile() return vim.fn.expand("<cfile>") end

local function set_indent(width)
    vim.opt.shiftwidth = width
    vim.opt.tabstop = width
    vim.opt.expandtab = width ~= 8
end

-- Cycle tab width among 2, 4, 8
local function cycle_indent()
    local current = vim.opt.shiftwidth:get()

    local next_width
    if current == 2 then
        next_width = 4
    elseif current == 4 then
        next_width = 8
    else
        next_width = 2
    end

    set_indent(next_width)

    print("Indentation set to " .. next_width .. " (expandtab="
        .. tostring(vim.opt.expandtab:get()) .. ")")
end

local function toggle_diagnostic()
    local value = not vim.diagnostic.config().signs,
        vim.diagnostic.config({
            signs = value,
            virtual_text = value,
            underline = value,
        })
end

local function toggle_signcolumn()
    if vim.opt.signcolumn:get() == "no" then
        vim.opt.signcolumn = "number"
    else
        vim.opt.signcolumn = "no"
    end
end

local function toggle_quickfix()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        buf = vim.api.nvim_win_get_buf(win)
        buftype = vim.api.nvim_buf_get_option(buf, "buftype")
        if buftype == "quickfix" then
            vim.cmd("cclose")
            return
        end
    end
    vim.cmd("copen")
end

------------------------------------------------------------
-- Keymaps
------------------------------------------------------------

-- Highlight the word under cursor without moving to the next
map("n", "*", function()
    vim.fn.setreg("/", "\\V" .. cword())
    vim.opt.hlsearch = true
end, { noremap = true, silent = true })

-- Copy/paste from/to system clipboard
map("n", "yp", '"+p\']', { desc = "Paste from system clipboard" })
map("n", "Y", '"+yy', { desc = "Copy one line to system clipboard" })
map("v", "Y", '"+y', { desc = "Copy selected" })

-- Tabpage management
map({ "n", "v" }, "tt", "<cmd>tab split<CR>", { desc = "Split tab" })
map({ "n", "v" }, "tc", function()
    pcall(vim.cmd, vim.v.count ~= 0 and vim.v.count .. "tabclose" or "tabclose")
end, { desc = "Close tab" })
map({ "n", "v" }, "t[", function() pcall(vim.cmd, "-tabmove") end, { desc = "Move tab leftward" })
map({ "n", "v" }, "t]", function() pcall(vim.cmd, "+tabmove") end, { desc = "Move tab rightward" })
map({ "n", "v" }, "<C-[>", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map({ "n", "v" }, "<C-]>", "<cmd>tabnext<CR>", { desc = "Next tab" })


-- Window management
map("n", "<Tab>", "<C-w>w", { desc = "Next window" })
map("n", "<S-Tab>", "<C-w>W", { desc = "Previous window" })
map("n", "ss", "<C-w>s", { desc = "Split window horizontally" })
map("n", "sv", "<C-w>v", { desc = "Split window vertically" })
map("n", "sq", "<C-w>q", { desc = "Close window" })
map("n", "sh", "<C-w>H", { desc = "Move window leftward" })
map("n", "sj", "<C-w>J", { desc = "Move window downward" })
map("n", "sk", "<C-w>K", { desc = "Move window upward" })
map("n", "sl", "<C-w>L", { desc = "Move window rightward" })

-- Buffer management
map("n", "<C-k>", "<cmd>bp<CR>", { desc = "Previous buffer" })
map("n", "<C-l>", "<cmd>bn<CR>", { desc = "Next buffer" })
map("n", "<C-n>", "<cmd>cn<CR>", { desc = "Next error" })
map("n", "<C-p>", "<cmd>cp<CR>", { desc = "Previous error" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR>", { desc = "Save file" })

-- Code navigation
map("n", "e", ":pop<CR>", { silent = true })
-- map("n", "f", vim.lsp.buf.definition, {})
map("n", "gd", vim.lsp.buf.declaration, {})
-- map("n", "gr", vim.lsp.buf.references, {})
-- map("n", "gi", vim.lsp.buf.implementation, {})
-- map("n", "gt", vim.lsp.buf.type_definition, {})
map("n", "gh", vim.lsp.buf.hover, {})

-- <Space> key leading
map("n", " ti", cycle_indent, { silent = true })
map("n", " tf", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle tagbar" })
map("n", " tt", "<cmd>Vista!!<CR>", { desc = "Toggle file tree" })
map("n", " td", toggle_diagnostic, { silent = true })
map("n", " ts", toggle_signcolumn, { silent = true })
map("n", " th", function()
    vim.opt.hlsearch = not vim.opt.hlsearch:get()
end, { noremap = true, silent = true })
map("n", " tq", toggle_quickfix, { desc = "Toggle quickfix" })
map("n", " df", function() vim.diagnostic.open_float() end, {})
map("n", " dn", function() vim.diagnostic.goto_next() end, {})
map("n", " dp", function() vim.diagnostic.goto_prev() end, {})
map("n", " tr", function() vim.wo.wrap = not vim.wo.wrap end, {})

map("n", " tn", function()
    vim.opt.number = not vim.opt.number:get()
end, { desc = "Toggle line number" })
map("n", " tN", function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line number" })

map("n", " fm", function() vim.lsp.buf.format() end, {})

-- telescope.nvim plugin
local builtin = require("telescope.builtin")
map("n", " fp", builtin.builtin)
map("n", " ff", builtin.find_files)
map("n", " fg", builtin.live_grep)
map({ "n", "v" }, " fs", builtin.grep_string)
map("n", " fh", builtin.help_tags)
map("n", "f", builtin.lsp_definitions)
map("n", "gr", builtin.lsp_references)
map("n", "gi", builtin.lsp_implementations)
map("n", "gt", builtin.lsp_type_definitions)
map("n", "gc", builtin.lsp_incoming_calls)

-- comment.nvim plugin
map("n", "mm", "gcc", { remap = true, silent = true })
map("n", "mb", "gbc", { remap = true, silent = true })
map("v", "mm", "gc", { remap = true, silent = true })
map("v", "mb", "gb", { remap = true, silent = true })

-- neoscroll.nvim plugin
local neoscroll = require("neoscroll")
map({ "n", "v" }, "<C-j>", function() neoscroll.ctrl_d({ duration = 300 }) end)
map({ "n", "v" }, "<C-h>", function()
    neoscroll.scroll(3, { move_cursor = false, duration = 100 })
end)

-- nvgtags.nvim plugin
-- map('n', ' gx', "<cmd>Telescope nvgtags find_definition<CR>", {noremap=true, silent=true})
map('n', ' gd', "<cmd>Telescope nvgtags find_definition_under_cursor<CR>", { noremap = true, silent = true })
-- map('n', ' gp', "<cmd>Telescope nvgtags find_reference<CR>", {noremap=true, silent=true})
map('n', ' gr', "<cmd>Telescope nvgtags find_reference_under_cursor<CR>", { noremap = true, silent = true })

------------------------------------------------------------

-- AutoCmd
------------------------------------------------------------

-- Indentation
autocmd("FileType", {
    pattern = "sh,go,lua",
    callback = function() set_indent(4) end,
})

-- Jump to the last cursor position when reopened
autocmd("BufReadPost", {
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            vim.api.nvim_win_set_cursor(0, mark)
        end
    end,
})

-- Auto resize the heigth of quickfix window
autocmd("FileType", {
    pattern = "qf",
    callback = function()
        local n = vim.fn.line("$")
        vim.api.nvim_win_set_height(0, math.max(math.min(n, 8), 4))
    end,
})
