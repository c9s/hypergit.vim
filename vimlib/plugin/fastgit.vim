
" Fastgit 
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 0.1
"

let s:git_sync_freq = 3   " per updatetime ( * 4sec by default )
let s:git_sync_cnt = 0

fun! s:echo(msg)
  redraw
  echomsg a:msg
endf

fun! s:git_sync_background()
  if exists('g:git_sync')
    return
  endif

  if s:git_sync_cnt < s:git_sync_freq
    let s:git_sync_cnt += 1
    return
  endif
  let s:git_sync_cnt = 0

  if isdirectory('.git')

    echo 'git: synchronizing... (background)'
    let g:git_sync = 1
    let ret = system('git push ')
    let ret = substitute(ret,'[\n\s]\+'," ",'g')
    redraw
    echomsg ret
    sleep 50m

    let ret = system('git pull')
    let ret = substitute(ret,'[\n\s]\+'," ",'g')
    redraw
    echomsg ret
    sleep 50m

    unlet g:git_sync
  endif
endf


fun! s:commit_single_file(file)
  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_buffer()
  exec printf('autocmd BufWinLeave <buffer> :cal s:single_commit("%s","%s")',commit,a:file)
  startinsert
endf

fun! s:commit_all_file()
  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_buffer()
  exec printf('autocmd BufWinLeave <buffer> :cal s:commit("%s")',commit)
  startinsert
endf


fun! s:init_buffer()
  setlocal modifiable noswapfile bufhidden=hide nobuflisted nowrap cursorline
  setlocal nu fdc=0
  setfiletype git-fast-commit
  setlocal syntax=git-fast-commit
endf

fun! s:trim_message_op(line)
  return substitute( a:line , '^\!A\s\+' , '' , '')
endf

fun! s:parse_message(msgfile)
  if ! filereadable(a:msgfile)
    return
  endif
  let lines = readfile(a:msgfile)
  for l in lines 
    if l =~ '^\!A\s\+'
      let file = s:trim_message_op(l)
      cal system('git add ' . file )
      cal s:echo( file . ' added' )
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system('git rm ' . file )   " XXX: detect fail
      cal s:echo( file . ' deleted')
    endif
  endfor
endf

fun! s:commit(msgfile)
  redraw
  if ! filereadable(a:msgfile)
    echo 'skipped.'
    return
  endif

  cal s:parse_message(a:msgfile)

  echo "committing " 
  let ret = system( printf('git commit -a -F %s ', a:msgfile ) )
  echo ret
  echo "committed"
endf

fun! s:single_commit(msgfile,file)
  redraw
  if ! filereadable(a:msgfile)
    echo 'skipped.'
    return
  endif

  echo "committing " . a:file
  let ret = system( printf('git commit -F %s %s ', a:msgfile, a:file ) )
  echo ret
  echo "committed"
endf

com! Gci :cal s:commit_single_file(expand('%'))
com! Gcia :cal s:commit_all_file()

if exists('g:git_sync')
  autocmd CursorHold *.* nested cal s:git_sync_background()
endif

fun! s:fastgit_default_mapping()

endf

if exists('g:fastgit_default_mapping')
  cal s:fastgit_default_mapping()
endif
