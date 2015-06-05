" Commit Buffers {{{
fun! GitCommitSingleBuffer(...)
  if a:0 == 0
    let target = expand('%')
  elseif a:0 == 1
    let target = a:1
  endif

  call g:GitCommitBufferOpen()

  " XXX: make sure target exists, and it's in git commit list.
  let b:commit_target = target
  cal hypergit#commit#render_single(target)

  autocmd BufWinLeave <buffer> GitStatusUpdate

  cal g:Help.reg("Git: commit " . target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! GitCommitAllBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render()

  call g:Help.reg("Git: commit --all"," s - (skip)",1)
  call cursor(2,1)
  startinsert
endf

fun! GitCommitAmendBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render_amend()

  call g:Help.reg("Git: commit --amend"," s - (skip)",1)
  call cursor(2,1)
  startinsert
endf

fun! g:GitCommitBufferOpen()
  let msgfile = tempname()
  call hypergit#buffer#init('new',msgfile)
  call g:GitCommitBufferInit()
  return msgfile
endf

fun! g:GitCommitBufferInit()
  setlocal nu
  setlocal nohidden

  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function

  nmap <silent><buffer> s  :cal g:GitSkipCommit()<CR>
  autocmd BufUnload <buffer> :cal g:GitCommit()

  setfiletype gitcommit
endf

fun! g:GitCommit()
  let file = expand('%')
  if ! filereadable(file) 
    echo "Skipped"
    return
  endif
  cal s:filterCommitMessage(file)

  echohl GitMsg 
  echon "Committing..."
  if exists('b:commit_target')
    echo "Target: " . b:commit_target
    let cmd = printf('%s commit --cleanup=strip -F %s %s', g:GitBin , file, b:commit_target )
    if g:HyperGitBackgroundCommit
      cal system(cmd)
    else
      echo system(cmd)
    endif
  elseif exists('b:commit_amend')
    echo system('%s commit --cleanup=strip --amend -F %s' , g:GitBin , file )
  else
    let cmd = printf('%s commit --cleanup=strip -a -F %s', g:GitBin , file )
    if g:HyperGitBackgroundCommit
      call system(cmd)
    else
      let output = system(cmd)
      if v:shell_error
        echoerr output
        sleep 1
      else
        echon "Committed!"
      endif
    endif
  endif
  echohl None
endf

fun! s:filterCommitMessage(msgfile)
  if ! filereadable(a:msgfile)
    return
  endif
  let lines = readfile(a:msgfile)
  let idx = 0
  for l in lines
    if l =~ '^\!A\s\+'
      let file = s:trim_message_op(l)
      cal system( g:GitCommand . ' add ' . file )
      echohl GitMsg | echo file . ' added' | echohl None
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:GitCommand . ' rm ' . file )   " XXX: detect failure
      echohl GitMsg | echo file . ' deleted' | echohl None
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf

" }}}

com! -complete=file -nargs=?        GitCommit :cal GitCommitSingleBuffer(<f-args>)
com! GitCommitAll    :cal GitCommitAllBuffer()
com! GitCommitAmend  :cal GitCommitAmendBuffer()
