
" Fastgit 
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
"

let s:git_sync_freq = 3
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



