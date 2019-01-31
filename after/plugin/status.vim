" define GitStatus command.
" vim:fdm=marker:

fun! s:viewDiffFileFromStatusLine()
  let line = getline('.')
  if line =~ '^\s\+\(modified\|new file\):'
    let file = matchstr(line,'\(modified:\s\+\|new file:\s\+\)\@<=\S*$')
    let diff = system('git diff ' . file )
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
    redraw
    echo "No avaliable"
  endif
endf

fun! s:addFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+modified:'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    call hypergit#shell#run('git add -v ' . file)
    call s:GitStatusUpdate()
  else
    redraw
    echo "No avaliable"
  endif
endf

fun! s:commitStashFromStatusLine()
  cal GitCommitStashedBuffer()
  " call s:GitStatusUpdate()
endf

fun! s:commitFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+modified:'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    cal GitCommitSingleFileBuffer(file)
  else
    redraw
    echo "No avaliable"
  endif
endf

fun! s:viewFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+\(modified\|new file\):'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    silent exec 'split ' . file
  else
    redraw
    echo "No avaliable"
  endif
endf

fun! s:tabeFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+\(modified\|new file\):'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    silent exec 'tabe ' . file
  else
    redraw
    echo "No avaliable"
  endif
endf

fun! s:deleteFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+modified:'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    redraw
    echo system('git rm -vf ' . file)
    cal s:GitStatusUpdate()
  else
    redraw
    echo "No avaliable"
  endif
endf

fun! s:resetFileFromStatusLine()
  let line = getline('.')
  if line =~ '\s\+modified:'
    let file = matchstr(line,'\(modified:\s\+\)\@<=\S*$')
    echo system('git checkout ' . file)
    cal s:GitStatusUpdate()
  elseif line =~ '^#\s\+new file:'
    let file = matchstr(line,'\(new file:\s\+\)\@<=\S*$')
    echo system('git reset -- ' . file)
    cal s:GitStatusUpdate()
  else
    redraw
    echo "No avaliable"
  endif
endf

" FIXME: update help message
fun! s:GitStatusUpdate()
  setlocal modifiable
  1,$delete _
  cal g:Help.reg("Git Status",
    \" L - Diff\n" .
    \" C - Commit\n" .
    \" D - Delete\n" .
    \" A - Add\n" .
    \" E - Edit\n" .
    \" T - Edit in NewTab\n" .
    \" R - Revert/Reset  \n"
    \,1)
  let status = system('git status -uno')
  0,$d
  put=status
  normal 0gg
  setlocal nomodifiable
endf

fun! s:GitStatus()
  tabnew
  setlocal noswapfile
  setlocal nobuflisted nowrap cursorline nonumber fdc=0 buftype=nofile bufhidden=wipe
  let status = system('git status -uno')
  put=status
  normal ggdd
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

  cal g:Help.reg("Git Status",
    \" L - Diff\n" .
    \" C - Commit\n" .
    \" D - Delete\n" .
    \" E - Edit\n" .
    \" T - Edit in NewTab\n" .
    \" R - Revert/Reset  \n"
    \,1)
  setlocal nomodifiable
endf
com! -complete=file -nargs=?        GitStatus :cal <SID>GitStatus()
com! -complete=file -nargs=?        GitStatusUpdate :cal <SID>GitStatusUpdate()
