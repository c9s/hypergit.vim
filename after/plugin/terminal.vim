func! s:GitRunTerminalCommand(...)
  let cmd = printf('%s --no-pager -C %s %s', g:GitBin, shellescape(getcwd()), join(a:000, ' '))
  cal hypergit#shell#run(cmd)
  " :term
  " git --git-dir /Users/id/.vim/bundle/hypergit.vim/.git --work-tree /Users/id/.vim/bundle/hypergit.vim diff
endf
com! -nargs=* Git :cal s:GitRunTerminalCommand(<f-args>)
""" test code
" cal s:GitRunTerminalCommand('push', 'origin', 'HEAD')
