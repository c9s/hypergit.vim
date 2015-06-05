
" Stash {{{
fun! s:GitStashShowFromBuffer()
  let line = getline('.')
  let stashname = matchstr(line,'^\S*\(:\)\@=')
  let output = system( 'git stash show -v ' . stashname )
  botright new
  setlocal noswapfile nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile bufhidden=wipe
  silent put=output
  silent normal ggdd
  setfiletype git
  setlocal nomodifiable
endf

fun! s:GitStashDropFromBuffer()
  let stashname = matchstr( getline('.') ,'^\S*\(:\)\@=')
  echo system( 'git stash drop ' . stashname )
  bw
  cal s:GitStashBufferOpen()
endf

fun! s:GitStashApplyFromBuffer()
  let stashname = matchstr( getline('.') ,'^\S*\(:\)\@=')
  let output = system( 'git stash apply ' . stashname )
  new
  setlocal noswapfile nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile bufhidden=wipe
  silent put=output
  silent normal ggdd
  setfiletype git-status
  setlocal nomodifiable
endf

fun! g:GitStashBufferOpen()
  tabnew
  setlocal noswapfile nobuflisted nowrap cursorline nonumber 
  setlocal fdc=0 buftype=nofile bufhidden=wipe
  let output = system('git stash list')
  put=output
  normal ggdd
  setfiletype git-stash
  silent file GitStashList

  nmap <script><buffer> S  :cal <SID>GitStashShowFromBuffer()<CR>
  nmap <script><buffer> D  :cal <SID>GitStashDropFromBuffer()<CR>
  nmap <script><buffer> A  :cal <SID>GitStashApplyFromBuffer()<CR>

  cal g:Help.reg("Git Stash",
    \" S - Show\n" .
    \" D - Drop\n" .
    \" A - Apply\n"
    \,1)
  setlocal nomodifiable
endf
com! -nargs=?        GitStash :cal g:GitStashBufferOpen()
" }}}
