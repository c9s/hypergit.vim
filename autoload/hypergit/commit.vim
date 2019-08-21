fun! hypergit#commit#render_status(...)
  let lines = split(system('git status ' . join(a:000, ' ')),"\n")
  cal map(lines, '"# " . v:val')
  cal append(line('$'),  lines)
endf

fun! s:cleanup_status_path(key, val)
  return substitute(a:val, '^\s*[AMD]\s*' , '' , '')
endf

" s:dirname returns the dirname
fun! s:dirname(key, val)
  let a = fnamemodify(a:val, ":h")
  if a == '.'
    return a:val
  endif
  return a
endf

fun! s:split_path(key, val)
  return split(a:val, "/")
endf


fun! hypergit#commit#render()
  let lines = split(system('git status --short --untracked-files=no'), "\n")

  " clean up
  call map(lines, function('s:cleanup_status_path'))
  call map(lines, function('s:dirname'))
  call filter(lines, 'v:val != "."')

  let compslist = sort(lines)

  " split the paths and store them in the array, e.g.,
  " [
  "   ["a","b"],
  "   ["foo","bar"],
  "   ["Jenkinsfile"],
  " ]
  call map(compslist, function('s:split_path'))

  if len(compslist) > 0
    let common = []
    let idx = 0
    for a in compslist[0]
      for comps in compslist
        if get(comps, idx, "NONE") == a
          call add(common, a)
          let idx = idx + 1
        else
          break
        endif
      endfor
    endfor
    if len(common) > 0
      let prefix = join(common, "/")
      let prefix = substitute(prefix, '^pkg/' , '' , '') . ": "
      cal append(line(1),  prefix)
    endif
  endif

  let status = split(system('git status -u' . g:HyperGitUntrackMode ),"\n")
  cal filter(status, 'v:val =~ "^#"')
  cal append(1,  status )
endf

fun! hypergit#commit#render_single(target)
  let prefix = fnamemodify(a:target, ":h")
  if prefix == "."
    let prefix = a:target
  endif

  let prefix = substitute(prefix, '^pkg/' , '' , '') . ": "
  cal append(line(1),  prefix)

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

