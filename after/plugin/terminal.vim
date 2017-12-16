func! s:GitRunTerminalCommand(...)
  let cwd = getcwd()
  let cmd = 'git --no-pager -C ' . cwd . ' ' . join(a:000, ' ')
  exec "terminal " . cmd
  " :term
  " git --git-dir /Users/id/.vim/bundle/hypergit.vim/.git --work-tree /Users/id/.vim/bundle/hypergit.vim diff
endf
com! -nargs=* Git :cal s:GitRunTerminalCommand(<f-args>)
""" test code
" cal s:GitRunTerminalCommand('push', 'origin', 'HEAD')
