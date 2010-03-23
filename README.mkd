
HyperGit Vim Plugin
===================

Screenshot
===========

    http://cloud.github.com/downloads/c9s/hypergit.vim/Screen_shot_2010-02-01_at_2.51.53_AM.png

Features
========

* Git Actions in TreeMenu 
* Commit Buffer
* Rebase (interactive) Helper. when `git rebase -i [branch]`

Tested Platforms
================

* Debian/Ubuntu Linux
* Mac OS X

Installation
============
Via rakefile:

    $ git clone git://github.com/c9s/hypergit.vim
    $ cd hypergit.vim
    $ make install

To install hypergit via Vimana from github:

    $ vimana i git:git://github.com/c9s/hypergit.vim -n hypergit.vim

To install hypergit via Vimana from www.vim.org:

    $ vimana i hypergit.vim

Add Git Menu key mapping to your ~/.vimrc:

    nmap <leader>G   :ToggleGitMenu<CR>

Default Key Mappings
============

    <leader>G    toggle hypergit menu
    <leader>ci   commit current file changes
    <leader>ca   commit all changes
    <leader>ga   add file to git repository

Commands
========

*:GitCommit*

*:GitCommitAll*

*:GitCommitAmend*

*:GitStatus*

*:GitStash*

*:GitPush*

*:GitPull*

