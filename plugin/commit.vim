" Commit Buffers {{{
fun! GitCommitSingleFileBuffer(...)
  if a:0 == 0
    let target = expand('%')
  elseif a:0 == 1
    let target = a:1
  endif
  call g:GitCommitBufferOpen()

  let b:commit_target = target
  cal hypergit#commit#render_single(target)

  cal g:Help.reg("Git: commit " . target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! GitCommitStashedBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render()
  call hypergit#commit#render_status()
  let b:commit_stashed = 1
  call g:Help.reg("Git: commit"," s - (skip)",1)
  call cursor(2,1)
  startinsert
endf

fun! GitCommitAllBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render()
  call hypergit#commit#render_status()
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

  " commit the stashed files
  if exists('b:commit_stashed')
    let cmd = printf('%s commit --cleanup=strip --file %s', g:GitBin , file)
    cal hypergit#shell#run(cmd)
  elseif exists('b:commit_target')
    let cmd = printf('%s commit --cleanup=strip --file %s %s', g:GitBin , file, b:commit_target )
    cal hypergit#shell#run(cmd)
  elseif exists('b:commit_amend')
    let cmd = printf('%s commit --cleanup=strip --amend --file %s' , g:GitBin , file )
    cal hypergit#shell#run(cmd)
  else
    let cmd = printf('%s commit --cleanup=strip -a --file %s', g:GitBin , file )
    cal hypergit#shell#run(cmd)
  endif
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

com! -complete=file -nargs=?  GitCommit :cal GitCommitSingleFileBuffer(<f-args>)
com! GitCommit         :cal GitCommitSingleFileBuffer()
com! GitCommitStashed  :cal GitCommitStashedBuffer()
com! GitCommitAll      :cal GitCommitAllBuffer()
com! GitCommitAmend    :cal GitCommitAmendBuffer()
