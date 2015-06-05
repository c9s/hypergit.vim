
fun! s:GitAdd(...)
  if a:0 == 0
    let file = expand('%')
  elseif a:0 == 1
    let file = a:1
  endif
  echo "Adding File: " . file
  exec '!git add -v ' . file
endf

com! -complete=file -nargs=?        GitAdd    :cal s:GitAdd(<f-args>)
