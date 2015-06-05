
fun! s:GitLog(...)
  if a:0 == 1
    let [since,til] = split(a:1)
  elseif a:0 == 0
    "let commit = input("Commit:","",'customlist,GitRemoteNameCompletion')
    let since = input("Since:","")
    let til = input("Til:","")
  elseif a:0 == 2
    let since = a:1
    let til = a:2
  endif
  if strlen(since) > 1 && strlen(til) > 1
    exec printf('! clear & %s log %s..%s',g:GitBin,since,til)
  elseif strlen(since) > 1 
    exec printf('! clear & %s log %s..HEAD',g:GitBin,since)
  else
    echo "..."
  endif
endf

com! -complete=customlist,GitRevCompletion        -nargs=? GitLog      :cal s:GitLog(<f-args>)
