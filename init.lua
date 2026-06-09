------------------------------------------------------------
-- Vim settings
------------------------------------------------------------
vim.g.mapleader = " "
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
    { "xiyaowong/transparent.nvim" }, -- :TransparentTogggle

    -- LSP
    { "neovim/nvim-lspconfig" },
    { "mason-org/mason.nvim",           opts = {} },
    { "mason-org/mason-lspconfig.nvim", opts = {} },

    {
        'nvim-treesitter/nvim-treesitter',
        disabled = true,
        lazy = false,
        build = ':TSUpdate',
        ensure_installed = { "c", "bash", "rust", "lua" },
        highlight = {
            enable = true,
        },
    },

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
    {
        "dhananjaylatkar/cscope_maps.nvim",
        dependencies = { "nvim-telescope/telescope.nvim" },
        opts = {
            disable_maps = false,     -- set true to define your own keymaps
            skip_input_prompt = true, -- dont ask for input, use word under cursor
            prefix = "<leader>c",     -- keymap prefix
            cscope = {
                exec = "gtags-cscope",
                picker = "telescope",
                skip_picker_for_single_result = true, -- jump directly if one result
            },
            project_rooter = {
                enable = true,     -- "true" or "false"
                -- change cwd to where db_file is located
                change_cwd = true, -- "true" or "false"
            },
        },
    },
    {
        "nvim-tree/nvim-tree.lua",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            tab = {
                sync = {
                    open = true,  -- open nvim-tree in new tabs automatically
                    close = true, -- close nvim-tree in all tabs when closed in one
                },
            },
            on_attach = function(bufnr)
                local api = require("nvim-tree.api")
                local opts = { buffer = bufnr, noremap = true, silent = true }

                -- default mappings
                api.config.mappings.default_on_attach(bufnr)

                vim.keymap.set("n", "o", api.node.open.no_window_picker, opts)

                -- Disable conflict keymaps in vim-tree buffer
                vim.keymap.del("n", "<Tab>", opts)
                vim.keymap.del("n", "<C-]>", opts)
            end,
        }
    },

    -- tabline, statusline
    {
        'nvim-lualine/lualine.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            theme = 'gruvbox',
            extensions = {
                'quickfix', 'nvim-tree',
            },
        }
    },
    {
        'kdheepak/tabline.nvim',
        dependencies = { 'nvim-lualine/lualine.nvim' },
        opts = {
            options = {
                show_filename_only = true,
                show_devicons = false,
                modified_italic = false,
            },
        }
    },

    {
        'nvim-mini/mini.comment',
        opts = {
            mappings = {
                comment = 'm',        -- Toggle comment
                comment_line = 'mm',  -- Toggle comment on current line
                comment_visual = 'm', -- Toggle comment in visual mode
            }
        }
    },
    { "karb94/neoscroll.nvim", opts = {} },

    { "liuchengxu/vista.vim",  cmd = "Vista" },
})

-- Plugin dependent settings
vim.opt.background = "dark" -- or "light" for light mode
vim.cmd.colorscheme "gruvbox"

-- Telescope
require("telescope").load_extension("fzf")

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
    local value = not vim.diagnostic.config().signs
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

local use_lsp_keymap = true
if vim.system({ "global", "-p" }):wait().code == 0 then
    use_lsp_keymap = false
end

-- Toggle keymap scheme for tag navigation
local function toggle_keymap()
    if use_lsp_keymap == true then
        -- Telescope LSP keymaps
        local tel = require("telescope.builtin")
        map("n", "f", tel.lsp_definitions)
        map("n", "gr", tel.lsp_references)
        map("n", "gt", tel.lsp_type_definitions)
        map("n", "gc", tel.lsp_incoming_calls)
        map("n", "gi", tel.lsp_implementations)
        print("LSP keymaps used")
    else
        -- Cscope keymaps
        map("n", "f", "<cmd>Cs find g<cr>", { desc = "Find global definitions" })
        map("n", "gr", "<cmd>Cs find s<cr>", { desc = "Find refereces" })
        map("n", "gc", "<cmd>Cs find c<cr>", { desc = "Find all incoming calls" })
        map({ "n", "v" }, "ge", "<cmd>Cs find e<cr>", { desc = "Egrep search" })
        map("n", "gf", "<cmd>Cs find f<cr>", { desc = "Open file" })
        map("n", "gi", "<cmd>Cs find i<cr>", { desc = "Find files that includes the file" })
        print("Cscope keymaps used")
    end
    use_lsp_keymap = not use_lsp_keymap
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

-- <Space> key leading
map("n", " ti", cycle_indent, { silent = true })
map("n", " tf", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle tagbar" })
map("n", " tt", "<cmd>Vista!!<CR>", { desc = "Toggle file tree" })
map("n", " tq", toggle_quickfix, { desc = "Toggle quickfix" })
map("n", " tk", toggle_keymap, {})
map("n", " td", toggle_diagnostic, { silent = true })
map("n", " ts", toggle_signcolumn, { silent = true })
map("n", " th", function()
    vim.opt.hlsearch = not vim.opt.hlsearch:get()
end, { noremap = true, silent = true })
map("n", " df", function() vim.diagnostic.open_float() end, {})
map("n", " dn", function() vim.diagnostic.goto_next() end, {})
map("n", " dp", function() vim.diagnostic.goto_prev() end, {})

map("n", " tn", function()
    vim.opt.number = not vim.opt.number:get()
end, { desc = "Toggle line number" })
map("n", " tN", function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
end, { desc = "Toggle relative line number" })

map("n", " fm", function() vim.lsp.buf.format() end, {})

-- neoscroll.nvim plugin
local neoscroll = require("neoscroll")
map({ "n", "v" }, "<C-j>", function() neoscroll.ctrl_d({ duration = 300 }) end)
map({ "n", "v" }, "<C-h>", function()
    neoscroll.scroll(3, { move_cursor = false, duration = 100 })
end)

-- tabline.nvim plugin
-- To set show_all_buffers = false in tabline.lua
map("n", " tb", "<cmd>TablineToggleShowAllBuffers<cr>", {})

------------------------------------------------------------
-- Token location
------------------------------------------------------------

map("n", "e", ":pop<CR>", { silent = true })

-- telescope.nvim plugin
local tel = require("telescope.builtin")
map("n", " gp", tel.builtin, { desc = "Builtin Pickers" })
map("n", " gf", tel.find_files)
map("n", " gg", tel.live_grep)
map("n", " gh", tel.help_tags)
map({ "n", "v" }, " gw", tel.grep_string, { desc = "Find word under cursor" })
map({ "n", "v" }, "gw", tel.grep_string, { desc = "Find word under cursor" })
map("n", " gd", tel.lsp_definitions)
map("n", " gr", tel.lsp_references)
map("n", " gt", tel.lsp_type_definitions)
map("n", " gc", tel.lsp_incoming_calls)
map("n", " gi", tel.lsp_implementations)

toggle_keymap()

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
