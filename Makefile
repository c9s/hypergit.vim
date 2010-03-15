
# Makefile: install/uninstall/link vim plugin files.
# Author: Cornelius <cornelius.howl@gmail.com>
# Date:   一  3/15 22:49:26 2010

DIRS=autoload \
	 after \
	 doc \
	 syntax

VIMRUNTIME=~/.vim
PWD=`pwd`

all: install

init-runtime:
	find $(DIRS) -type d | while read dir ;  do \
			mkdir -p $(VIMRUNTIME)/$$dir ; done

install: init-runtime
	@echo "Installing"
	find $(DIRS) -type f | while read file ; do \
			cp -v $$file $(VIMRUNTIME)/$$file ; done

uninstall:
	@echo "Uninstalling"
	find $(DIRS) -type f | while read file ; do \
			rm -v $(VIMRUNTIME)/$$file ; done

link: init-runtime
	@echo "Linking"
	find $(DIRS) -type f | while read file ; do \
			ln -sv $(PWD)/$$file $(VIMRUNTIME)/$$file ; done
