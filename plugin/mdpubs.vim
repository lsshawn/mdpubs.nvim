" MdPubs.nvim - Neovim plugin for MdPubs API integration
" Author: Your Name
" License: MIT

if exists('g:loaded_mdpubs')
  finish
endif
let g:loaded_mdpubs = 1

" Command to setup the plugin (for vim-plug users who don't call setup in config)
command! -nargs=0 MdPubsSetup lua require('mdpubs').setup()

" Load the plugin if Neovim supports Lua
if has('nvim-0.5')
  " Plugin will be loaded when required
else
  echohl ErrorMsg
  echom 'MdPubs.nvim requires Neovim 0.5 or later'
  echohl None
endif 