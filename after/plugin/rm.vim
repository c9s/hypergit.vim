
fun! s:GitRm(...)
  if a:0 == 0
    let file = expand('%')
  elseif a:0 == 1
    let file = a:1
  endif
  echo "Deleting File: " . file
  exec '!git rm -v ' . file
endf

com! -complete=file -nargs=?        GitRm     :cal s:GitRm(<f-args>)
