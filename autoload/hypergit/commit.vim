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


" s:common_prefix takes a list of split paths and returns the components that
" all of them share, e.g. [["pkg","a"],["pkg","b"]] -> ["pkg"]. Returns an
" empty list when the paths have nothing in common.
fun! s:common_prefix(compslist)
  let common = a:compslist[0]
  for comps in a:compslist[1:]
    let n = 0
    while n < len(common) && n < len(comps) && common[n] ==# comps[n]
      let n += 1
    endwhile
    let common = n > 0 ? common[0 : n - 1] : []
    if len(common) == 0
      break
    endif
  endfor
  return common
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
    let common = s:common_prefix(compslist)
    if len(common) > 0
      let prefix = join(common, "/")
      let prefix = substitute(prefix, '^pkg/' , '' , '') . ": "
      cal append(0,  prefix)
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
  cal append(0,  prefix)

  let lines = split(system('git status ' . a:target),"\n")
  cal map(lines, '"# " . v:val')
  cal append(line('$'),  lines)
endf

fun! hypergit#commit#render_amend()
  " Ask git for the message of HEAD instead of reading .git/COMMIT_EDITMSG:
  " that path is wrong whenever we are not at the top of the work tree (and in
  " submodules and linked worktrees .git is a file, not a directory), and it is
  " stale whenever the last commit was not made from this editor.
  let out = system(g:GitBin . ' log -1 --format=%B')
  if v:shell_error
    return
  endif
  let lines = split(out, "\n")
  while len(lines) > 0 && lines[-1] =~ '^\s*$'
    cal remove(lines, -1)
  endwhile
  cal append(0,  lines )
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

