" vim:et:sw=2:fdm=marker:fdl=0:
"
" hypergit.vim
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 2.1

if exists('g:HyperGitLoaded')
  "finish
elseif v:version < 702
  echoerr 'Ahaha. your vim seems too old , please do upgrade. i found your vim is ' . v:version . '.'
  finish
endif

let g:HyperGitLoaded = 1

fun! s:defopt(name,val)
  if !exists(a:name)
    let {a:name} = a:val
  endif
endf

fun! s:echo(msg)
  redraw
  echomsg a:msg
endf

fun! s:exec_cmd(cmd)
  let cmd_output = system(join(a:cmd," "))
  if v:shell_error
    echohl WarningMsg | echon cmd_output
    return
  endif
  redraw
  echohl GitCommandOutput | echo cmd_output | echohl None
endf

" Git Commands {{{





" Git API {{{
fun! GitCurrentBranch()
   let name = split(system("git branch | grep '^*' | cut -c3-"))
   return name[0]
endf

fun! GitDefaultBranchName()
  return GitCurrentBranch()
endf

fun! GitDefaultRemoteName()
  let names = split(system('git remote'),"\n")
  if len(names) > 0
    return names[0]
  else 
    return ''
  endif
endf
" }}}

fun! s:initGitLogBuffer()
  cal hypergit#buffer#init()
endf

fun! s:initGitRemoteBuffer()
  cal hypergit#buffer#init()
endf

fun! s:initGitStashBufferOpen()
  cal hypergit#buffer#init()
endf

cal s:defopt('g:HyperGitUntrackMode' , 'no' )
cal s:defopt('g:GitBin','git')
cal s:defopt('g:GitBufferDefaultPosition','topleft')
cal s:defopt('g:HyperGitBufferHeight' , 15 )
cal s:defopt('g:HyperGitBufferWidth' ,35 )
cal s:defopt('g:HyperGitCAbbr',1)
cal s:defopt('g:HyperGitDefaultMapping',1)
cal s:defopt('g:HyperGitBackgroundCommit',0)

com! GitConfig   :tabe ~/.gitconfig

if g:HyperGitDefaultMapping
  nmap <silent> <leader>ci   :GitCommit<CR>
  nmap <silent> <leader>ca   :GitCommitAll<CR>
  nmap <silent> <leader>ga   :GitAdd<CR>
  nmap <silent> <leader>G    :ToggleGitMenu<CR>
  nmap <silent> <leader>gp   :GitPush<CR>
  nmap <silent> <leader>gl   :GitPull<CR>
  nmap <silent> <leader>gs   :GitStatus<CR>
  nmap <silent> <leader>gh   :GitStash<CR>
endif

if g:HyperGitCAbbr
    cabbr   glog       GitLog
    cabbr   gpush      GitPush
    cabbr   gpull      GitPull
    cabbr   gmadd      GitRemoteAdd
    cabbr   gmdel      GitRemoteDel
    cabbr   gmrename   GitRemoteRename
endif

if executable('git-snapshot')
  com! GitSnapshot   :!git snapshot
  com! GitSnapshotLog :!git log refs/snapshots/HEAD -p
  cabbr gss  GitSnapshot
  cabbr gsl  GitSnapshotLog
endif

