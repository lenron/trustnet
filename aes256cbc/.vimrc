set noexpandtab "Forces the tab key to insert tabs."
set tabstop=4 "Set the tabsize to 4"
set shiftwidth=0 "Defaults to tab size"
set nu

syntax on
colorscheme default

noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>
