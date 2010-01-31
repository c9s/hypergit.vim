
fun! hypergit#buffer#init(...)
  if exists('a:1')
    exec g:gitbuffer_default_position . ' ' . g:hypergitBufferHeight . 'split ' . a:1
  else
    exec g:gitbuffer_default_position . ' ' . g:hypergitBufferHeight . 'new'
    setlocal buftype=nofile 
  endif
  setlocal noswapfile  
  setlocal bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
endf

fun! hypergit#buffer#init_v(...)
  if exists('a:1')
    exec g:gitbuffer_default_position . ' ' . g:hypergitBufferWidth . 'vsplit ' . a:1
  else
    exec g:gitbuffer_default_position . ' ' . g:hypergitBufferWidth . 'vnew'
    setlocal buftype=nofile 
  endif
  setlocal noswapfile  
  setlocal bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
endf

fun! hypergit#buffer#clean()

endf
