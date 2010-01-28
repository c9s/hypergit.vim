
" synopsis:
"
"   call register_help at begining,
"
fun! g:help_register(brief,fulltext)
  let b:help_brief = a:brief . ' | Press ? For Help.'
  let b:help_brief_height = 0

  let b:help_fulltext = "Press ? To Hide Help\n" . a:fulltext
  let b:help_fulltext_height = 0

  nnoremap <silent> <buffer>  ?   :cal g:help_toggle_fulltext()<CR>

  cal s:help_show_brief()
  cal s:help_init_syntax()
endf

fun! g:help_toggle_fulltext()
  if exists('b:help_fulltext_on')
    cal s:help_hide_fulltext()
  else
    cal s:help_show_fulltext()
  endif
endf

fun! s:help_show_brief()
  let lines = split(b:help_brief,"\n")
  let b:help_brief_height = len(lines)
  cal map(lines,"'\" ' . v:val")
  cal append( 0 , lines  )
endf

fun! s:help_init_syntax()
  syn match BufferHelp +^"\s.*$+
  hi link BufferHelp Comment
endf

fun! s:help_hide_brief()
  exec 'silent 1,'.b:help_brief_height.'delete _'
endf

fun! s:help_show_fulltext()
  let b:help_fulltext_on = 1

  cal s:help_hide_brief()

  let lines = split(b:help_fulltext,"\n")
  cal map(lines,"'\" ' . v:val")

  let b:help_fulltext_height = len(lines)
  cal append( 0 , lines  )
endf

fun! s:help_hide_fulltext()
  unlet b:help_fulltext_on
  exec 'silent 1,'.b:help_fulltext_height.'delete _'
  cal s:help_show_brief()
endf

