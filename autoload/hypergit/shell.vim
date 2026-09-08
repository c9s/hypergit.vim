
fun! hypergit#shell#run(cmd)
  if has("terminal")
    let winid = win_getid(winnr())
    " Hand the command to the shell as one argument: :terminal splits its own
    " command line and knows nothing about shell quoting, so an `exec
    " 'terminal ' . cmd` mangles any quoted path in it.
    cal term_start([&shell, &shellcmdflag, a:cmd],
      \ { 'term_finish': 'close', 'norestore': 1, 'term_rows': 10 })
    cal win_gotoid(winid)
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
