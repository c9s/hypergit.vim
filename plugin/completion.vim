

" vim:fdm=marker:
" Command Completion Functions {{{
fun! GitRevCompletion(lead,cmd,pos)
  let parts = split(a:cmd)
  if strlen(a:lead) > 0 && len(parts) > 2
    let last_part = remove(parts,-1)
  else
    let last_part = 'HEAD'
  endif
  " XXX: just use HEAD for now
  let last_part = 'HEAD'
  let revs = split(system(printf('git rev-list --max-count=%d %s',50,last_part)))
  cal filter( revs , 'v:val =~ "^' .a:lead. '"'  )
  return revs
endf

fun! GitRemoteNameCompletion(lead,cmd,pos)
  let names = split(system('git remote'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

fun! GitLocalBranchCompletion(lead,cmd,pos)
  let names = split(system('git branch | cut -c3-'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

fun! GitRemoteBranchCompletion(lead,cmd,pos)
  let names = split(system('git branch -r | cut -c3-'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

" }}}
