set noexpandtab "Forces the tab key to insert tabs."
set tabstop=4 "Set the tabsize to 4"
set shiftwidth=0 "Defaults to tab size"
set nu

syntax on
colorscheme default

noremap <F12> <Esc>:syntax sync fromstart<CR>
inoremap <F12> <C-o>:syntax sync fromstart<CR>


user.email=aaronbreault@gmail.com
user.name=Aaron
core.editor=vim
core.repositoryformatversion=0
core.filemode=true
core.bare=false
core.logallrefupdates=true
remote.origin.url=git@github.com:lenron/trustnet.git
remote.origin.fetch=+refs/heads/*:refs/remotes/origin/*
branch.main.remote=origin
branch.main.merge=refs/heads/main
pull.rebase=false
