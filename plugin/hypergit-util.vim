
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

fun! s:filterMessage(msgfile)
  if ! filereadable(a:msgfile)
    return
  endif
  let lines = readfile(a:msgfile)
  let idx = 0
  for l in lines
    if l =~ '^\!A\s\+'
      let file = s:trim_message_op(l)
      cal system( g:git_command . ' add ' . file )
      echohl GitMsg | echo file . ' added' | echohl None
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:git_command . ' rm ' . file )   " XXX: detect failure
      echohl GitMsg | echo file . ' deleted' | echohl None
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf


fun! g:gitSkipCommit()
  let file = expand('%')
  cal delete(file)
  bw!
endf

fun! g:gitDoCommit()
  let file = expand('%')
  if ! filereadable(file) 
    echo "Skipped"
    return
  endif
  cal s:filterMessage(file)

  echohl GitMsg 
  echo "Committing..."
  if exists('b:commit_target')
    echo "Target: " . b:commit_target
    let cmd = printf('%s commit --cleanup=strip -F %s %s', g:git_bin , file, b:commit_target )
    if g:hypergitBackgroundCommit
      cal system(cmd)
    else
      echo system(cmd)
    endif
  elseif exists('b:commit_amend')
    echo system('%s commit --cleanup=strip --amend -F %s' , g:git_bin , file )
  else
    let cmd = printf('%s commit --cleanup=strip -a -F %s', g:git_bin , file )
    if g:hypergitBackgroundCommit
      cal system(cmd)
    else
      echo system(cmd)
    endif
  endif
  echo "Done"
  echohl None
endf
