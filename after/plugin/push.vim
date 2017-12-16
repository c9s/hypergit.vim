

fun! s:GitPushHEAD()
  cal hypergit#buffer#bottomright(10)
  cal hypergit#buffer#init_nofile()
  setfiletype gitconsole

  let remote = GitDefaultRemoteName()
  let cmd = printf('%s push -u %s %s', g:GitBin, remote, 'HEAD')
  cal setline(1, "$ " . cmd)
  cal setline(2, "==============================")

  echomsg "Running " . cmd . " ..."
  silent let out = system(cmd)
  let lines = split(out, "\n")
  cal append(line('$'),  lines)
  setlocal nomodifiable
endf
com! -nargs=? GitPushHEAD :cal s:GitPushHEAD()
" test code
" :GitPushHEAD


fun! s:GitPush(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:",GitDefaultRemoteName(),'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear & %s push %s %s',g:GitBin,remote,branch)
endf

com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPush     :cal s:GitPush(<f-args>)


function! s:RunShellCommand(cmdline)
  let isfirst = 1
  let words = []
  for word in split(a:cmdline)
    if isfirst
      let isfirst = 0  " don't change first word (shell command)
    else
      if word[0] =~ '\v[%#<]'
        let word = expand(word)
      endif
      let word = shellescape(word, 1)
    endif
    call add(words, word)
  endfor
  let expanded_cmdline = join(words)
  botright new
  setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
  call setline(1, 'You entered:  ' . a:cmdline)
  call setline(2, 'Expanded to:  ' . expanded_cmdline)
  call append(line('$'), substitute(getline(2), '.', '=', 'g'))
  silent execute '$read !'. expanded_cmdline
  1
endfunction
command! -complete=shellcmd -nargs=+ Shell call s:RunShellCommand(<q-args>)


