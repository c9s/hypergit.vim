
" Fastgit 
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
"

let s:git_sync_freq = 3   " per updatetime ( * 4sec by default )
let s:git_sync_cnt = 0
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
autocmd CursorHold *.* nested cal s:git_sync_background()

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

fun! s:commit(msgfile)
  redraw
  echo "committing " 
  let ret = system( printf('git commit -a -F %s ', a:msgfile ) )
  echo ret
  echo "committed"
endf

fun! s:single_commit(msgfile,file)
  redraw
  echo "committing " . a:file
  let ret = system( printf('git commit -F %s %s ', a:msgfile, a:file ) )
  echo ret
  echo "committed"
endf

com! Gitci :cal s:commit_single_file(expand('%'))
com! Gitcia :cal s:commit_all_file()
