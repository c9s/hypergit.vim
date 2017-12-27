fun! hypergit#commit#render_status(...)
  let lines = split(system('git status ' . join(a:000, ' ')),"\n")
  cal map(lines, '"# " . v:val')
  cal append(line('$'),  lines)
endf

fun! hypergit#commit#render()
  let status = split(system('git status -u' . g:HyperGitUntrackMode ),"\n")
  cal filter(status, 'v:val =~ "^#"')
  cal append(1,  status )
endf

fun! hypergit#commit#render_single(target)
  let lines = split(system('git status ' . a:target),"\n")
  cal map(lines, '"# " . v:val')
  cal append(line('$'),  lines)
endf

fun! hypergit#commit#render_amend()
  if filereadable('.git/COMMIT_EDITMSG')
    let lines = readfile('.git/COMMIT_EDITMSG')
    cal append(0,  lines )
  endif
endf

" Some keyword completion for commit message editing...
"
" setlocal completefunc=hypergit#commit#messageCompletion
fun! hypergit#commit#messageCompletion(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    " find months matching with "a:base"
    let res = []
    for m in split("FIX: REFACTOR: BUG: RELEASE:")
      if m =~ '^' . a:base
    call add(res, m)
      endif
    endfor
    return res
  endif
endfun

