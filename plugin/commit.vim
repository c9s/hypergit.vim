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

  " move to the latest colume
  cal cursor(2,78)

  " ! is included to behave like A
  startinsert!
endf

fun! GitCommitStashedBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render()
  call hypergit#commit#render_status()
  let b:commit_stashed = 1
  call g:Help.reg("Git: commit"," s - (skip)",1)
  call cursor(2,1)
  startinsert!
endf

fun! GitCommitAllBuffer()
  call g:GitCommitBufferOpen()
  call hypergit#commit#render()
  call hypergit#commit#render_status()
  call g:Help.reg("Git: commit --all"," s - (skip)",1)
  call cursor(2,1)
  startinsert!
endf

fun! GitCommitAmendBuffer()
  call g:GitCommitBufferOpen()
  let b:commit_amend = 1
  call hypergit#commit#render_amend()

  call g:Help.reg("Git: commit --amend"," s - (skip)",1)
  call cursor(2,1)
  startinsert!
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

  nnoremap <silent><buffer> s  :cal g:GitSkipCommit()<CR>
  autocmd BufUnload <buffer> :cal g:GitCommit()

  setfiletype gitcommit
endf


fun! g:GitCommit()
  " We run from BufUnload, where vim may already have made another buffer the
  " current one, so the message file and the commit flags must be taken from
  " the buffer that is going away (<afile>/<abuf>) and not from '%'/b:.
  " Reading '%' here used to pick up the previously edited file, which made
  " `s` (skip) commit that file's contents as the commit message.
  let bufnr = str2nr(expand('<abuf>'))
  let file  = expand('<afile>')
  if bufnr == 0
    let bufnr = bufnr('%')
  endif
  if strlen(file) == 0
    let file = expand('%')
  endif

  if ! filereadable(file)
    echo "Skipped"
    return
  endif
  cal s:filterCommitMessage(file)

  let target = getbufvar(bufnr, 'commit_target', '')

  " commit the stashed files
  if getbufvar(bufnr, 'commit_stashed', 0)
    let cmd = printf('%s commit --cleanup=strip --file %s', g:GitBin , shellescape(file))
  elseif strlen(target) > 0
    let cmd = printf('%s commit --cleanup=strip --file %s -- %s', g:GitBin , shellescape(file), shellescape(target))
  elseif getbufvar(bufnr, 'commit_amend', 0)
    let cmd = printf('%s commit --cleanup=strip --amend --file %s' , g:GitBin , shellescape(file))
  else
    let cmd = printf('%s commit --cleanup=strip -a --file %s', g:GitBin , shellescape(file))
  endif

  " We are called from BufUnload, where vim forbids opening/splitting a window
  " (E1159). Defer the command so it runs once the buffer is really gone.
  cal timer_start(0, { -> hypergit#shell#run(cmd) })
endf

" s:trim_message_op strips the leading action operator ("!A " / "!D ") from a
" commit message line and returns the file name it refers to.
fun! s:trim_message_op(line)
  return substitute(a:line, '^\!\a\s\+', '', '')
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
      cal system( g:GitBin . ' add ' . shellescape(file) )
      echohl GitMsg | echo file . ' added' | echohl None
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:GitBin . ' rm ' . shellescape(file) )   " XXX: detect failure
      echohl GitMsg | echo file . ' deleted' | echohl None
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf

" }}}

" NOTE: -nargs=? already covers the no-argument case (GitCommitSingleFileBuffer
" then falls back to the current buffer). A second, argument-less :GitCommit
" definition used to follow this one and silently won, breaking `:GitCommit <file>`.
com! -complete=file -nargs=?  GitCommit :cal GitCommitSingleFileBuffer(<f-args>)
com! GitCommitStashed  :cal GitCommitStashedBuffer()
com! GitCommitAll      :cal GitCommitAllBuffer()
com! GitCommitAmend    :cal GitCommitAmendBuffer()
