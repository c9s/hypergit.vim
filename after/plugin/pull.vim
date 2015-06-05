
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
