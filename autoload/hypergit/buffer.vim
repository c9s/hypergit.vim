
fun! hypergit#buffer#init(...)
  if a:1  == 'v'
    let size = g:hypergitBufferWidth
  else
    let size = g:hypergitBufferHeight
  endif

  if a:0 == 2
    exec g:gitbuffer_default_position . ' ' . size . a:1 . 'split ' . a:1
  elseif a:0 == 1
    exec g:gitbuffer_default_position . ' ' . size . a:1 . 'new'
    setlocal buftype=nofile 
  endif
  setlocal noswapfile  
  setlocal bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
endf
