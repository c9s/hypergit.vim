
" vim:et:sw=2:fdm=marker:
"
" hypergit.vim
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 2.03


if exists('g:loaded_hypergit')
  "finish
elseif v:version < 702
  echoerr 'ahaha. your vim seems too old , please do upgrade. i found your vim is ' . v:version . '.'
  finish
endif

let g:loaded_hypergit = 1
let g:git_bin = 'git'
let g:hypergitBufferHeight = 8

fun! s:defopt(name,val)
  if !exists(a:name)
    let {a:name} = a:val
  endif
endf

fun! s:echo(msg)
  redraw
  echomsg a:msg
endf



fun! s:initGitStatusBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitBranchBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitLogBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitCommitBuffer()
  setlocal nu
  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function

  nmap <silent><buffer> s  :cal g:git_skip_commit()<CR>
  autocmd BufUnload <buffer> :cal g:git_do_commit()

  setfiletype gitcommit
endf

fun! s:initGitCommitSingleBuffer(target)
  let msgfile = tempname()
  cal hypergit#buffer#init(msgfile)
  cal s:initGitCommitBuffer()

  let b:commit_target = a:target
  cal hypergit#commit#render_single(a:target)

  cal g:help_register("Git: commit " . a:target ," s - (skip)",1)
endf

fun! s:initGitCommitAllBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init(msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render()

  cal g:help_register("Git: commit --all"," s - (skip)",1)
endf

fun! s:initGitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init(msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render_amend()

  cal g:help_register("Git: commit --amend"," s - (skip)",1)
endf

fun! s:filter_message_op(msgfile)
  if ! filereadable(a:msgfile)
    return
  endif
  let lines = readfile(a:msgfile)
  let idx = 0
  for l in lines
    if l =~ '^\!A\s\+'
      let file = s:trim_message_op(l)
      cal system( g:git_command . ' add ' . file )
      echohl GitMsg | echo file . ' added' | echohl None
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:git_command . ' rm ' . file )   " XXX: detect failure
      echohl GitMsg | echo file . ' deleted' | echohl None
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf

fun! g:git_skip_commit()
  let file = expand('%')
  cal delete(file)
  bw!
endf

fun! g:git_do_commit()
  let file = expand('%')
  if ! filereadable(file) 
    echo "Skipped"
    return
  endif
  cal s:filter_message_op(file)

  echohl GitMsg 
  echo "Committing..."
  if exists('b:commit_target')
    echo "Target: " . b:commit_target
    echo system( printf('%s commit --cleanup=strip -F %s %s', g:git_bin , file, b:commit_target ) )
  elseif exists('b:commit_amend')
    echo system('%s commit --cleanup=strip --amend -F %s' , g:git_bin , file )
  else
    echo system( printf('%s commit --cleanup=strip -a -F %s', g:git_bin , file ) )
  endif
  echo "Done"
  echohl None
endf

fun! s:initGitRemoteBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitStashBuffer()
  cal hypergit#buffer#init()

endf

com! GitCommit       :cal s:initGitCommitSingleBuffer(expand('%'))
com! GitCommitAll    :cal s:initGitCommitAllBuffer()
com! GitCommitAmend  :cal s:initGitCommitAmendBuffer()

nmap <leader>ci  :GitCommit<CR>
nmap <leader>ca  :GitCommitAll<CR>

"cal s:initGitCommitBuffer()
