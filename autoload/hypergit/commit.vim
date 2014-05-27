
fun! hypergit#commit#init_syntax()

endf

fun! hypergit#commit#render()
  let status = split(system('git status -u'.g:HyperGitUntrackMode ),"\n")
  cal filter(status, 'v:val =~ "^#"')
  cal append(1,  status )
endf

fun! hypergit#commit#render_single(target)
  let status = split(system('git status -u'. g:HyperGitUntrackMode . ' ' . a:target),"\n")
  cal filter(status, 'v:val =~ "^#"')
  cal append(1,  status )
endf

fun! hypergit#commit#render_amend()
  if filereadable('.git/COMMIT_EDITMSG')
    let lines = readfile('.git/COMMIT_EDITMSG')
    cal append(0,  lines )
  endif
endf



fun! hypergit#commit#commit()

endf

fun! hypergit#commit#skip()

endf
