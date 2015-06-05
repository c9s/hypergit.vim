" Commit Buffers {{{
fun! GitCommitSingleBuffer(...)
  if a:0 == 0
    let target = expand('%')
  elseif a:0 == 1
    let target = a:1
  endif

  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:GitCommitBufferInit()

  " XXX: make sure target exists, and it's in git commit list.
  let b:commit_target = target
  cal hypergit#commit#render_single(target)

  autocmd BufWinLeave <buffer> GitStatusUpdate

  cal g:Help.reg("Git: commit " . target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! GitCommitAllBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:GitCommitBufferInit()
  cal hypergit#commit#render()

  cal g:Help.reg("Git: commit --all"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! GitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:GitCommitBufferInit()
  cal hypergit#commit#render_amend()

  cal g:Help.reg("Git: commit --amend"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:GitCommitBufferInit()
  setlocal nu
  setlocal nohidden

  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function

  nmap <silent><buffer> s  :cal g:GitSkipCommit()<CR>
  autocmd BufUnload <buffer> :cal g:GitDoCommit()

  setfiletype gitcommit
endf

" }}}

com! -complete=file -nargs=?        GitCommit :cal GitCommitSingleBuffer(<f-args>)
com! GitCommitAll    :cal GitCommitAllBuffer()
com! GitCommitAmend  :cal GitCommitAmendBuffer()
