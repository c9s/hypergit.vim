
fun! g:GitLogPromptByBranch()
  let branch = input("Branch:","master")
  exec printf('! clear & %s log %s', g:GitBin, branch)
endf

fun! g:GitLogPromptBetweenBranch()
  let from = input("From:","master")
  let to = input("To:","master")
  exec printf('! clear & %s log %s..%s', g:GitBin, from, to)
endf

fun! g:GitLogPromptByRange()
  let since = input("Since:","")
  let til = input("Til:","")
  if strlen(since) > 1 && strlen(til) > 1
    exec printf('! clear & %s log %s..%s',g:GitBin,since,til)
  elseif strlen(since) > 1 
    exec printf('! clear & %s log %s..HEAD',g:GitBin,since)
  endif
endf

fun! g:GitLog(...)

  " TODO: check array
  if a:0 == 1
    let [since,til] = split(a:1)
  elseif a:0 == 0
    " let commit = input("Commit:","",'customlist,GitRemoteNameCompletion')
    " let since = input("Since:","")
    " let til = input("Til:","")
    let since = ""
    let til = ""
  elseif a:0 == 2
    let since = a:1
    let til = a:2
  endif
  if strlen(since) > 1 && strlen(til) > 1
    exec printf('! clear & %s log %s..%s',g:GitBin,since,til)
  elseif strlen(since) > 1 
    exec printf('! clear & %s log %s..HEAD',g:GitBin,since)
  else
    exec printf('! clear & %s log',g:GitBin)
  endif
endf
com! -nargs=0 GitLogPromptByBranch      :cal g:GitLogPromptByBranch()
com! -complete=customlist,GitRevCompletion        -nargs=? GitLog              :cal g:GitLog(<f-args>)
