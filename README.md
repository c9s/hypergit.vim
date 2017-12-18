hypergit.vim
===================

This git plugin provides many awesome features so that you don't need to type commands anymore..

Screenshot
===========

![ScreenShot](https://github.com/c9s/hypergit.vim/raw/master/screenshot.png)

Features
===========

* Git Actions in TreeMenu 
* Commit Buffer
* Rebase (interactive) Helper. When using `git rebase -i [branch]`, it's automatically enabled.

Tested Platforms
================

* Debian/Ubuntu Linux
* Mac OS X

Installation
=============

Via Vundle:

```vim
Plugin 'c9s/helper.vim'
Plugin 'c9s/treemenu.vim'
Plugin 'c9s/hypergit.vim'
```

Be sure to have helper.vim before hypergit.vim.

Configuration
=================

Add Git Menu key mapping to your ~/.vimrc:

    nmap <leader>G   :ToggleGitMenu<CR>

Default Key Mappings
====================

    <leader>G    toggle hypergit menu
    <leader>ci   commit current file changes
    <leader>ca   commit all changes

    <leader>ga   add file to git repository
    <leader>gb   branch manager buffer
    <leader>gs   status manager buffer
    <leader>gh   stash manager buffer

Commands
========

*:GitCommit*

*:GitCommitAll*

*:GitCommitAmend*

*:GitStatus*

*:GitStash*

*:GitPush*

*:GitPull*
