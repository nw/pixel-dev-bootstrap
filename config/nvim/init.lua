vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "no"
vim.opt.showmode = true
vim.opt.mouse = "a"
vim.opt.scrolloff = 3
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.g.mapleader = " "

-- Use a real platform clipboard only when its bridge is actually available.
-- Termux requires the Termux:API companion app plus the termux-api package.
-- AVF Display sessions can use Wayland or X11 clipboard utilities.
if vim.fn.executable("termux-clipboard-set") == 1
    and vim.fn.executable("termux-clipboard-get") == 1 then
  vim.g.clipboard = {
    name = "Termux Android clipboard",
    copy = {
      ["+"] = "termux-clipboard-set",
      ["*"] = "termux-clipboard-set",
    },
    paste = {
      ["+"] = "termux-clipboard-get",
      ["*"] = "termux-clipboard-get",
    },
    cache_enabled = 0,
  }
  vim.opt.clipboard = "unnamedplus"
elseif vim.env.WAYLAND_DISPLAY
    and vim.fn.executable("wl-copy") == 1
    and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "Wayland clipboard",
    copy = {
      ["+"] = "wl-copy",
      ["*"] = "wl-copy",
    },
    paste = {
      ["+"] = "wl-paste --no-newline",
      ["*"] = "wl-paste --no-newline",
    },
    cache_enabled = 1,
  }
  vim.opt.clipboard = "unnamedplus"
elseif vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
  vim.g.clipboard = {
    name = "X11 clipboard",
    copy = {
      ["+"] = "xclip -quiet -i -selection clipboard",
      ["*"] = "xclip -quiet -i -selection primary",
    },
    paste = {
      ["+"] = "xclip -o -selection clipboard",
      ["*"] = "xclip -o -selection primary",
    },
    cache_enabled = 1,
  }
  vim.opt.clipboard = "unnamedplus"
end

vim.keymap.set("n", "<Leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<Leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })
