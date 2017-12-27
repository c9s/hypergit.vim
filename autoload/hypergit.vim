
fun! hypergit#run(cmd)
  if has("terminal")
    exec "terminal ++close ++rows=10 " . a:cmd
  else
    cal hypergit#buffer#bottomright(10)
    cal hypergit#buffer#init_nofile()
    setfiletype gitconsole

    " record the output in the buffer.
    cal setline(1, "$ " . a:cmd)
    cal setline(2, "==============================")

    echomsg "Running " . a:cmd . " ..."
    silent let out = system(a:cmd)
    let lines = split(out, "\n")
    cal append(line('$'),  lines)
    setlocal nomodifiable
  endif
endf

" Some keyword completion for commit message editing...
"
" setlocal completefunc=hypergit#commitMessageCompletion
fun! hypergit#commitMessageCompletion(findstart, base)
  if a:findstart
    " locate the start of the word
    let line = getline('.')
    let start = col('.') - 1
    while start > 0 && line[start - 1] =~ '\a'
      let start -= 1
    endwhile
    return start
  else
    " find months matching with "a:base"
    let res = []
    for m in split("FIX: REFACTOR: BUG: RELEASE:")
      if m =~ '^' . a:base
    call add(res, m)
      endif
    endfor
    return res
  endif
endfun
