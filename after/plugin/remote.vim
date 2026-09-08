
fun! s:RemoteAdd(...)
  let remote = a:0 > 0 ? a:1 : ''
  if strlen(remote) == 0
    let remote = input("Remote Name:","")
  endif
  if strlen(remote) == 0
    return
  endif
  let uri = input("Git URI:",'')
  if strlen(uri) > 0
    cal system( printf('git remote add %s %s',remote ,uri))
    echo printf("Remote Added. %s => %s",remote,uri)
  endif
endf

fun! s:RemoteRm(remote)
  let ret = system( printf('git remote rm %s ',a:remote))
  let ret = substitute( ret , "\n" , "" , 'g')
  if v:shell_error
    echohl WarningMsg | echo "Can't remove remote '"  . a:remote . "': " . ret | echohl None
  else
    redraw
    echo "Remote " . a:remote . " removed."
  endif
endf

fun! s:RemoteRename(remote)
  let new_name = input("New Remote Name:","")
  let ret = system( printf('git remote rename %s %s',a:remote,new_name))
  echo ret
endf

com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitRemoteAdd :cal s:RemoteAdd( <q-args> )
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteDel :cal s:RemoteRm(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteRename :cal s:RemoteRename(<f-args>)
