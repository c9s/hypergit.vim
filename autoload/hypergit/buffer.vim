
fun! hypergit#buffer#init(...)
  if a:1  =~ '^v'
    let size = g:HyperGitBufferWidth
  else
    let size = g:HyperGitBufferHeight
  endif

  if a:0 == 2
    exec g:GitBufferDefaultPosition . ' ' . size . a:1 . ' ' . a:2
  elseif a:0 == 1
    exec g:GitBufferDefaultPosition . ' ' . size . a:1 
    setlocal buftype=nofile 
  endif
  setlocal noswapfile  
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
endf

fun! hypergit#buffer#next_name(prefix)
  if exists('s:bufnr')
    let s:bufnr += 1
  else
    let s:bufnr = 1
  endif
  return a:prefix . s:bufnr
endf
