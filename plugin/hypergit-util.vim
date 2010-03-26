
" vim:fdm=marker:

fun! FindDotGit()
  let path = getcwd()
  let parts = split(path,'/')
  let paths = []
  for i in range(1,len(parts))
    cal add(paths,  '/'.join(parts,'/'))
    cal remove(parts,-1)
  endfor
  for p in paths 
    if isdirectory(p . '/.git')
      return p
    endif
  endfor
  return ""
endf



" Commit Buffers {{{
fun! GitCommitSingleBuffer(...)
  if a:0 == 0
    let target = expand('%')
  elseif a:0 == 1
    let target = a:1
  endif

  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()

  " XXX: make sure target exists, and it's in git commit list.
  let b:commit_target = target
  cal hypergit#commit#render_single(target)

  cal g:Help.reg("Git: commit " . target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf
fun! GitCommitAllBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render()

  cal g:Help.reg("Git: commit --all"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf
fun! GitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render_amend()

  cal g:Help.reg("Git: commit --amend"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf
fun! s:initGitCommitBuffer()
  setlocal nu
  setlocal nohidden

  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function

  nmap <silent><buffer> s  :cal g:gitSkipCommit()<CR>
  autocmd BufUnload <buffer> :cal g:gitDoCommit()

  setfiletype gitcommit
endf
" }}}

