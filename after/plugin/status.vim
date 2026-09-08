" define GitStatus command.
" vim:fdm=marker:

" s:fileFromStatusLine extracts the path from the `git status` line under the
" cursor. git used to prefix these lines with `#`; it stopped doing so in 1.8,
" and both shapes are accepted here.
fun! s:fileFromStatusLine()
  return matchstr(getline('.'),
    \ '^\s*\%(#\s*\)\?\%(modified\|new file\|deleted\):\s\+\zs.\{-}\s*$')
endf

fun! s:noFileUnderCursor()
  redraw
  echo "No avaliable"
endf

fun! s:viewDiffFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    let diff = system(g:GitBin . ' diff -- ' . shellescape(file))
    botright new
    setlocal noswapfile
    setlocal nobuflisted nowrap cursorline nonumber fdc=0 buftype=nofile bufhidden=wipe
    silent put=diff
    normal ggdd
    setfiletype git
    exec 'file Diff-' . file
    nmap <buffer> L  <C-w>q
    exec 'nmap <leader>ci    :cal GitCommitSingleFileBuffer("'.file.'")<CR>'
    setlocal nomodifiable
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:addFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    call hypergit#shell#run(g:GitBin . ' add -v -- ' . shellescape(file))
    call s:GitStatusUpdate()
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:commitStashFromStatusLine()
  cal GitCommitStashedBuffer()
  " call s:GitStatusUpdate()
endf

fun! s:commitFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    cal GitCommitSingleFileBuffer(file)
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:viewFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    silent exec 'split ' . fnameescape(file)
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:tabeFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    silent exec 'tabe ' . fnameescape(file)
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:deleteFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) > 0
    redraw
    echo system(g:GitBin . ' rm -vf -- ' . shellescape(file))
    cal s:GitStatusUpdate()
  else
    cal s:noFileUnderCursor()
  endif
endf

fun! s:resetFileFromStatusLine()
  let file = s:fileFromStatusLine()
  if strlen(file) == 0
    cal s:noFileUnderCursor()
    return
  endif
  if getline('.') =~ 'new file:'
    echo system(g:GitBin . ' reset -q -- ' . shellescape(file))
  else
    echo system(g:GitBin . ' checkout -- ' . shellescape(file))
  endif
  cal s:GitStatusUpdate()
endf

fun! s:statusHelp()
  return
    \ " v - Diff\n" .
    \ " c - Commit file\n" .
    \ " C - Commit staged changes\n" .
    \ " a - Add\n" .
    \ " D - Delete\n" .
    \ " E - Edit\n" .
    \ " T - Edit in NewTab\n" .
    \ " R - Revert/Reset\n" .
    \ " u - Update\n"
endf

fun! s:GitStatusUpdate()
  setlocal modifiable
  silent 0,$delete _
  let status = system(g:GitBin . ' status -uno')
  silent put=status
  silent normal! ggdd
  " Help.reg prepends its header, so it has to run after the buffer is filled
  cal g:Help.reg("Git Status", s:statusHelp(), 1)
  normal! gg
  setlocal nomodifiable
endf

fun! s:GitStatus()
  tabnew
  setlocal noswapfile
  setlocal nobuflisted nowrap cursorline nonumber fdc=0 buftype=nofile bufhidden=wipe
  let status = system(g:GitBin . ' status -uno')
  put=status
  normal! ggdd
  setfiletype git-status
  silent file GitStatus
  nnoremap <script><buffer> v  :cal <SID>viewDiffFileFromStatusLine()<CR>
  nnoremap <script><buffer> c  :cal <SID>commitFileFromStatusLine()<CR>
  nnoremap <script><buffer> C  :cal <SID>commitStashFromStatusLine()<CR>
  nnoremap <script><buffer> a  :cal <SID>addFileFromStatusLine()<CR>

  nnoremap <script><buffer> D  :cal <SID>deleteFileFromStatusLine()<CR>
  nnoremap <script><buffer> E  :cal <SID>viewFileFromStatusLine()<CR>
  nnoremap <script><buffer> T  :cal <SID>tabeFileFromStatusLine()<CR>
  nnoremap <script><buffer> R  :cal <SID>resetFileFromStatusLine()<CR>
  nnoremap <script><buffer> u  :cal <SID>GitStatusUpdate()<CR>

  cal g:Help.reg("Git Status", s:statusHelp(), 1)
  setlocal nomodifiable
endf
com! -complete=file -nargs=?        GitStatus :cal <SID>GitStatus()
com! -complete=file -nargs=?        GitStatusUpdate :cal <SID>GitStatusUpdate()
