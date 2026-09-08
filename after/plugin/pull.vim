fun! s:GitFetch(...)
  if a:0 > 0
    let remote = join(a:000, ' ')
  else
    let remotes = hypergit#remote#get_remote_names()
    if len(remotes) == 0
      redraw
      echohl WarningMsg | echo "No remote to fetch from." | echohl None
      return
    elseif len(remotes) == 1
      let remote = remotes[0]
    else
      let remote = input("Remote:",GitDefaultRemoteName(),'customlist,GitRemoteNameCompletion')
    endif
  endif

  cal hypergit#buffer#bottomright(10)
  cal hypergit#buffer#init_nofile()
  setfiletype gitconsole
  let out = system(printf('%s fetch --verbose %s', g:GitBin, remote))
  put=out
  setlocal nomodifiable
endf
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitFetch     :cal s:GitFetch(<f-args>)

fun! s:GitPullHEAD()
  let remote = GitDefaultRemoteName()
  if strlen(remote) == 0
    redraw
    echohl WarningMsg | echo "No remote to pull from." | echohl None
    return
  endif

  cal hypergit#buffer#bottomright(10)
  cal hypergit#buffer#init_nofile()
  setfiletype gitconsole

  let cmd = printf('%s pull --rebase %s %s', g:GitBin, remote, 'HEAD')
  cal setline(1, "$ " . cmd)
  cal setline(2, "==============================")

  echomsg "Running " . cmd . " ..."
  silent let out = system(cmd)
  let lines = split(out, "\n")
  cal append(line('$'),  lines)
  setlocal nomodifiable
endf
com! -nargs=? GitPullHEAD :cal s:GitPullHEAD()



fun! s:GitPull(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:",GitDefaultRemoteName(),'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear & %s pull %s %s',g:GitBin,remote,branch)
endf
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPull     :cal s:GitPull(<f-args>)
