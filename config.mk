
NAME=hypergit.vim
VIMRUNTIME=~/.vim
VERSION=0.7

bundle-deps:
	$(call fetch_github,c9s,treemenu.vim,master,plugin/treemenu.vim,plugin/treemenu.vim)
	$(call fetch_github,c9s,helper.vim,master,plugin/helper.vim,plugin/helper.vim)
