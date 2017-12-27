
fun hypergit#shell#run(cmd)
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
