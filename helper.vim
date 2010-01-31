
" vim:fdm=marker:fdl=0:
" Class: Helper
" Author: Cornelius  <cornelius.howl@gmail.com>
" Description: 
"    render help message for plugin.

" Help Class {{{
"   call register_help at begining,
let s:Help = {}
fun! s:Help.reg(brief,fulltext,show_brief)
  let b:help_brief = a:brief . ' | Press ? For Help.'
  let b:help_brief_height = 0
  let b:help_show_brief_on = a:show_brief

  let b:help_fulltext = "Press ? To Hide Help\n" . a:fulltext
  let b:help_fulltext_height = 0

  nmap <script>  <Plug>showHelp   :cal <SID>toggle_fulltext()<CR>
  nmap <buffer> ? <Plug>showHelp

  if b:help_show_brief_on
    cal s:Help.show_brief()
  endif
  cal s:Help.init_syntax()
endf

fun! s:toggle_fulltext()
  if exists('b:help_fulltext_on')
    cal s:Help.hide_fulltext()
  else
    cal s:Help.show_fulltext()
  endif
endf

fun! s:Help.show_brief()
  let lines = split(b:help_brief,"\n")
  let b:help_brief_height = len(lines)
  cal map(lines,"'# ' . v:val")
  cal append( 0 , lines  )
endf

fun! s:Help.init_syntax()

endf

fun! s:Help.hide_brief()
  exec 'silent 1,'.b:help_brief_height.'delete _'
endf

fun! s:Help.show_fulltext()
  let b:help_fulltext_on = 1

  if b:help_show_brief_on
    cal s:Help.hide_brief()
  endif

  let lines = split(b:help_fulltext,"\n")
  cal map(lines,"'# ' . v:val")

  let b:help_fulltext_height = len(lines)
  cal append( 0 , lines  )
endf

fun! s:Help.hide_fulltext()
  unlet b:help_fulltext_on
  exec 'silent 1,'.b:help_fulltext_height.'delete _'
  if b:help_show_brief_on
    cal s:Help.show_brief()
  endif
endf
" }}}
" Test Code {{{ 

fun! s:Test()
" test code:
  vnew
  cal s:Help.reg('orz','ORZ',1)
endf
" cal s:Test()
" }}}
