
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
