


fun! hypergit#commitMessageCompletion(findstart,base)
  if a:findstart

  else
    return [ 'FIX:' , 'REFACTOR:' , 'BUG:' ]
  endif
endf
