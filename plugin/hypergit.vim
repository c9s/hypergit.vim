" vim:et:sw=2:fdm=marker:
"
" FastGit Plugin
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 2.03

" Plugin Guard
if exists('g:loaded_fgit')
  finish
elseif v:version < 702
  echoerr 'ahaha. your vim seems too old , please do upgrade. i found your vim is ' . v:version . '.'
  finish
endif
let g:loaded_fgit = 1

fun! s:defopt(name,val)
  if !exists(a:name)
    let {a:name} = a:val
  endif
endf

fun! s:echo(msg)
  redraw
  echomsg a:msg
endf


fun! s:init_plugin()
  hi GitCommandMsg ctermbg=yellow ctermfg=black
  hi GitMsg        ctermbg=yellow ctermfg=black
  hi GitCommandOutput ctermbg=black ctermfg=darkyellow
endf

" XXX:  if branch exists , we should jsut switch , not to create one
fun! s:switch_branch(branch)
  let opt = ''
  if a:branch =~ 'remotes/'
    let br = substitute( a:branch , 'remotes/' , '' , '' )
    let local_br = matchstr( br , '[a-zA-Z0-9-]\+$' )
    let opt .= ' -t ' . br . ' -b ' . local_br
  else
    let opt .= a:branch
  endif
  let cmd = 'git checkout ' . opt
  echohl GitCommandMsg | echo cmd | echohl None
  let out = system( cmd )
  echo out
  silent 1,$delete _
  cal s:RenderBranchBuffer()
endf

fun! s:merge_branch(branch)
  let out = system('git merge ' . a:branch )
  echo out
endfun

fun! s:RenderBranchBuffer()
  let out = system('git branch -a')
  let lines = ["HELP: o: checkout branch  p: push  l: pull  m: merge"]
  cal add(lines,'---------------------------------------')
  cal extend(lines, split( out , "\n" ))
  cal setline(1, lines )
  cal search('^\*')
endf

fun! s:close_buffer()
  bw!
endf


fun! s:open_stash_buffer()
  8new
  cal s:init_buffer()
  setlocal noswapfile  buftype=nofile bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
  file GitStashList
  setfiletype gitstashlist
  "nmap <silent> <buffer> o    :exec 'GitSwitchBranch ' . substitute(getline('.'),'^\*','','')<CR>
  "nmap <silent> <buffer> m    :exec 'GitMergeBranch ' . substitute(getline('.'),'^\*','','')<CR>
  cal s:show_stash_list()
endf

fun! s:show_stash_list()
  let out = system('git stash list')
  let lines = [""]
  cal extend(lines, split( out , "\n" ))
  cal setline(1, lines )
endf

fun! s:OpenBranchBuffer()
  12new
  cal s:init_buffer()
  setlocal noswapfile  buftype=nofile bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0

  file GitBranch
  " init syntax
  setfiletype gitbranch
  syn match RemoteBranch  "^\s\+remotes/.*$"
  syn match CurrentBranch "^\*\s.*$"
  syn match LocalBranch   "^\s\+\(remotes\)\@![a-zA-Z/_-]\+"
  hi link RemoteBranch Function 
  hi LocalBranch   ctermfg=blue
  hi CurrentBranch ctermfg=red
  nmap <silent> <buffer> o    :exec 'GitSwitchBranch ' . substitute(getline('.'),'^\*','','')<CR>
  nmap <silent> <buffer> m    :exec 'GitMergeBranch ' . substitute(getline('.'),'^\*','','')<CR>
  cal s:RenderBranchBuffer()
endf

fun! s:RenderRemoteBuffer()
  :r !git remote -v
endf

fun! s:OpenRemoteBuffer()
  12new
  cal s:init_buffer()
  setlocal noswapfile  buftype=nofile bufhidden=wipe
  setlocal nobuflisted nowrap cursorline nonumber fdc=0

  file GitRemote
  setfiletype gitremote


  cal s:RenderRemoteBuffer()
endf

fun! s:BranchBufferToggle()
  let b = bufnr('GitBranch')
  " can not found
  if b == -1 
    cal s:OpenBranchBuffer()
  else 
    " found
    exec 'silent '.b .'bw'
  endif
endf

fun! s:RemoteBufferToggle()
  let b = bufnr('Remote')
  if b == -1 
    cal s:OpenRemoteBuffer()
  else 
    exec 'silent '.b .'bw'
  endif
endf



" XXX: only do push when there are commits to push.

" sync counter
let g:git_sync_cnt = 0
fun! s:git_sync_background()
  if exists('g:fastgit_sync_lock')
    return
  endif

  " check counter
  if g:git_sync_cnt < g:fastgit_sync_freq
    let g:git_sync_cnt += 1
    return
  endif
  let g:git_sync_cnt = 0

  if ! isdirectory('.git')
    return
  endif

  echon 'git: synchronizing... '
  if g:fastgit_sync_bg
    echo '(background)'
  else
    echo
  endif

  let push_cmd = g:git_command . ' push '
  let pull_cmd = g:git_command . ' pull '

  if exists('g:fastgit_default_remote')
    " XXX: only when remtoe exists
    let push_cmd .= g:fastgit_default_remote
    let pull_cmd .= g:fastgit_default_remote
  endif

  if g:fastgit_sync_bg
    let push_cmd .= ' &'
    let pull_cmd .= ' &'
  endif

  let g:fastgit_sync_lock = 1
  let ret = system(push_cmd)
  let ret = substitute(ret,'[\n ]\+'," ",'g')
  cal s:echo(ret)
  sleep 30m

  let ret = system(pull_cmd)
  let ret = substitute(ret,'[\n ]\+'," ",'g')
  cal s:echo(ret)
  sleep 30m

  cal s:echo('git: synchronized.')
  unlet g:fastgit_sync_lock
endf


fun! s:commit_single_file(file)
  let file = a:file
  if strlen(file) == 0 
    let file = expand('%')
  endif

  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_commit_buffer()
  cal s:append_status()
  exec printf('autocmd BufWinLeave <buffer> :cal s:single_commit("%s","%s")',commit,file)
  startinsert
endf

fun! s:append_status()
  let status = split(system('git status'),"\n")
  cal filter(status, 'v:val =~ "^#"')
  cal append(line('$'),  status )
endf

fun! s:commit_all_file()
  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_commit_buffer()
  cal s:append_status()

  exec printf('autocmd BufWinLeave <buffer> :cal s:commit("%s")',commit)
  cal cursor(1,1)
  startinsert
endf

fun! s:init_diff_buffer()
  cal s:init_buffer()

endf

" XXX: use built-in git syntax
fun! s:init_commit_buffer()
  cal s:init_buffer()
  setlocal nu
  setfiletype git-status
  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function
endf

fun! s:init_buffer()
  setlocal modifiable noswapfile bufhidden=wipe nobuflisted nowrap cursorline
  setlocal fdc=0
endf

fun! s:trim_message_op(line)
  return substitute( a:line , '^\![AD]\s\+' , '' , '')
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


fun! s:save_msg(file)
  let l:id = 1
  while filereadable( 'git-commit-' . l:id )
    let l:id += 1
  endwhile
  let fname = 'git-commit-' . l:id
  cal writefile( readfile(a:file ) , fname )

  echoerr "commit message saved to '". fname ."'. "
  return fname
endf

fun! s:git_dir_found()
  let comps = split(getcwd(),'/')
  let paths = []
  let path = ''
  while len(comps) > 0 
    let p = remove(comps,0)
    let path = join( [ path , p ] , '/' )
    cal add(paths,path)
  endwhile
  cal reverse(paths)

  for f in paths 
    if isdirectory( f . '/.git') 
      return 1
    endif
  endfor

  echohl WarningMsg
  echo "\I can not found your .git directory"
  echo "Seems you are not under a git repository directory"
  echo " Then please use ':cd [path]' command to change directory"
  echo "or do you forget to initialize git repository"
  echohl None
  return 0
endf

fun! s:commit(msgfile)
  if ! s:can_commit(a:msgfile)
    return
  endif

  if ! s:git_dir_found()
    cal s:save_msg( a:msgfile )
    return
  endif

  cal s:filter_message_op(a:msgfile)
  echohl GitMsg | echo "committing " | echohl None

  if g:fastgit_background_commit
    cal system( printf('%s commit --cleanup=strip -a -F %s &', g:git_command , a:msgfile ) )
  else
    let ret = system( printf('%s commit --cleanup=strip -a -F %s ', g:git_command , a:msgfile ) )
    echo ret
    echohl GitMsg | echo "committed" | echohl None
  endif

endf

fun! s:can_commit(msgfile)
  " read file
  " grep out comment line and empty lines
  " see if there still text
  if filereadable(a:msgfile)
    let lines = readfile(a:msgfile)
    for l in lines 
      if l !~ '^#' && l !~ '^\s*$'
        return 1
      endif
    endfor
  else
    cal s:echo('skipped.')
    exec 'bw! '.a:msgfile
    return 0
  endif
endf

fun! s:single_commit(msgfile,file)
  if ! s:can_commit(a:msgfile)
    return
  endif
  
  if ! s:git_dir_found()
    cal s:save_msg( a:msgfile )
    return 
  endif

  cal s:filter_message_op(a:msgfile)

  echohl GitMsg | echo "committing " . a:file | echohl None
  if g:fastgit_background_commit
    " XXX: add a growl or libnotify hook here , so that we can know if a commit
    " success or not.
    cal system( printf('%s commit --cleanup=strip -F %s %s &', g:git_command , a:msgfile, a:file ) )
    echohl GitMsg | echo "background committing." | echohl None
  else
    let ret = system( printf('%s commit --cleanup=strip -F %s %s %s', g:git_command , a:msgfile, a:file , postargs ) )
    echo ret
    echohl GitMsg | echo "committed" | echohl None
  endif
endf

fun! s:skip_commit(file)
  if &filetype != 'git-fast-commit'
    return
  endif
  if filereadable(a:file)
    cal delete(a:file)
  endif
  bw!
  cal s:echo('skipped')
endf

fun! s:diff_window()
  exec 'leftabove 10new'
  cal s:init_diff_buffer()

endf

" XXX: refactor this
function! s:GitDiffThis(...)
  if a:0 == 1
    let rev = a:1
  else
    let rev = 'HEAD'
  endif
  let ftype = &filetype
  let prefix = system( g:git_command . " rev-parse --show-prefix")
  let thisfile = substitute(expand("%"),getcwd(),'','')
  let gitfile = substitute(prefix,'\n$','','') . thisfile

  " Check out the revision to a temp file
  let tmpfile = tempname()
  let cmd =  g:git_command . " show  " . rev . ":" . gitfile . " > " . tmpfile
  let cmd_output = system(cmd)
  if v:shell_error && cmd_output != ""
    echohl WarningMsg | echon cmd_output
    return
  endif

  setlocal bufhidden=wipe

  " Begin diff
  exe "vert diffsplit" . tmpfile
  exe "set filetype=" . ftype
  set foldmethod=diff
  wincmd l
endf

fun! s:GitChanges(...)

  if a:0 == 1
    let rev = a:1
  else
    let rev = 'HEAD'
  endif

  " Check if this file is managed by git, exit otherwise

  let prefix = system( g:git_command . " rev-parse --show-prefix")
  let thisfile = substitute(expand("%"),getcwd(),'','')
  let gitfile = substitute(prefix,'\n$','','') . thisfile

  " Reset syntax highlighting

  syntax off

  " Pipe the current buffer contents to a shell command calculating the diff
  " in a friendly parsable format

  let contents = join(getbufline("%", 1, "$"), "\n")
  let diff = system("diff -u0 <(git show " . rev . ":" . gitfile . ") <(cat;echo)", contents)

  " Parse the output of the diff command and hightlight changed, added and
  " removed lines

  for line in split(diff, '\n')

    let part = matchlist(line, '@@ -\([0-9]*\),*\([0-9]*\) +\([0-9]*\),*\([0-9]*\) @@')

    if ! empty(part)
      let old_from  = part[1]
      let old_count = part[2] == '' ? 1 : part[2]
      let new_from  = part[3]
      let new_count = part[4] == '' ? 1 : part[4]

      " Figure out if text was added, removed or changed.

      if old_count == 0
        let from  = new_from
        let to    = new_from + new_count - 1
        let group = 'DiffAdd'
      elseif new_count == 0
        let from  = new_from
        let to    = new_from + 1
        let group = 'DiffDelete'
      else
        let from  = new_from
        let to    = new_from + new_count - 1
        let group = 'DiffChange'
      endif

      " Set the actual syntax highlight

      exec 'syntax region ' . group . ' start=".*\%' . from . 'l" end=".*\%' . to . 'l"'

    endif

  endfor
endf


fun! g:get_author_cnt()
  let cmd_ret = system('git log | grep Author | perl -pe ''s{Author:\s+(\w+).*$}{$1}'' | uniq -c')
  let authorlines = split(cmd_ret,"\n")
  let authors = { }
  for a in authorlines
    let [ cnt , name ] = split( a , " " )
    let authors[ name ] = cnt
  endfor
  return authors
endf

fun! s:get_author_names()
  let config = expand('~/.gitconfig')
  if filereadable( config )
    let lines = readfile( config )
    let found_user = 0
    for l in lines 
      if l =~ '\[user\]'
        let found_user = 1
      elseif l =~ '\s\+name\s=' && found_user
        return matchstr( l , '\(name\s=\s\)\@<=\w\+' )
      endif
    endfor
  endif
  return 
endf

fun! s:GitPush(...)
  let cmd = [ g:git_command ,"push" ]
  let remote = 'all'
  if a:0 == 1
    cal add(cmd,a:1)
    let remote = '[' .  a:1 . ']'
  endif
  cal s:echo("git: push => " . remote . " (Ctrl-c to stop)")
  cal s:exec_cmd( cmd )
endf

fun! s:GitPull(...)
  let cmd = [ g:git_command ,"pull" ]
  let remote = 'all'
  if a:0 == 1
    cal add(cmd,a:1)
    let remote = '[' . a:1 . ']'
  endif
  cal s:echo("git: pull <= " . remote . " (Ctrl-c to stop)")
  cal s:exec_cmd( cmd )
endf

fun! g:get_current_branch()
  return substitute(system("git branch -a | grep '^*'|awk '{print $2}'"), "\n",'', 'g')
endf

fun! s:update_branch_name()
  let g:git_br = g:get_current_branch()
endf

fun! s:changed_lines_num()
  let ret = system("git log -p | grep '^[+-]' | wc -l")
  "return Int(ret)
endf

fun! s:set_statusline(newstl)
  exec 'set stl='.escape(a:newstl, ' \')
endf

fun! s:append_statusline(stl)
  cal s:update_branch_name()
  let g:git_ch = 0 " s:count_changes_from_yesterday()
  let l:stl = a:stl . " %=(B:%{g:git_br} C:%{g:git_ch})"
  cal s:set_statusline(l:stl)
endf

fun! s:count_changes_from_yesterday()
  let ret = system('git log -p --since="yesterday" | grep -E "^[-+]" | wc -l') 
  if strlen(ret) > 0 
    return str2nr(ret)
  else 
    return 0
  endif
endf

fun! s:create_statusline_str(opt)
  cal s:update_branch_name()
  let g:git_ch = 0 " s:count_changes_from_yesterday()
  return ' %n) %<%f %h%m%r%=%k[%{(&fenc==\"\")?&enc:&fenc}%{(&bomb?\",bom\":\"\")}] %-14.(%l,%c%v%) %p'
        \. " %=(C:%{g:git_ch}) (B:%{g:git_br}) "
endf

fun! s:toggle_statusline()
  if exists("s:old_stl")
    " recover statusline
    let s:stl =  s:old_stl
    unlet s:old_stl
  else
    " save statusline
    let s:old_stl = &stl
    let s:stl =  s:create_statusline_str({ })
  endif
  cal s:set_statusline(s:stl)
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

fun! s:RemoteAdd(remote)
  let uri = input("Git URI:",'')
  if strlen(uri) > 3 
    let ret = system( printf('git remote add %s %s',a:remote ,uri))
    let ret = substitute( ret , "\n" , "" , 'g')
    if v:shell_error
      echohl WarningMsg | echo "Can't add remote '"  . a:remote . "': " . ret | echohl None
    else
      cal s:echo( "Remote " . a:remote . " Added." )
    endif
  endif
endf

fun! s:RemoteDel(remote)
  let ret = system( printf('git remote rm %s ',a:remote))
  let ret = substitute( ret , "\n" , "" , 'g')
  if v:shell_error
    echohl WarningMsg | echo "Can't remove remote '"  . a:remote . "': " . ret | echohl None
  else
    cal s:echo( "Remote " . a:remote . " removed." )
  endif
endf

" completion functions
fun! GitRemoteNameCompletion(lead,cmd,pos)
  let names = split(system('git remote'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

fun! s:git_sync_au()
  augroup GitSyncAG
    au!
    au CursorHold *.* nested cal s:git_sync_background()
  augroup END
endf

fun! s:count_karma()
  let list = split( system( 'git log --pretty=format:%an | sort | uniq -c' ) , "\n" )
  let table = {  }
  for a in list 
    let columns = split(a,'\s\+',0)
    let cnt = remove(columns,0)
    let author = join(columns,' ')
    let table[  author  ] = cnt
  endfor
  return table
endf

" Commands {{{
" ===========================================================

com! GitBranch                     :cal s:BranchBufferToggle()
com! GitRemote                     :cal s:RemoteBufferToggle()

com! -nargs=? -complete=file GitCommit :cal s:commit_single_file(<q-args>)
com! GitCommitAll                      :cal s:commit_all_file()
com! GitCommitSkip                     :cal s:skip_commit(expand('%'))
com! GitDiff                           :cal s:diff_window()
com! GitStatusLine                     :cal s:toggle_statusline()

com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteAdd :cal s:RemoteAdd( <f-args> )
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteDel :cal s:RemoteDel( <f-args> )

com! -nargs=1 GitSwitchBranch :cal s:switch_branch(<f-args>)
com! -nargs=1 GitMergeBranch  :cal s:merge_branch(<f-args>)

com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPush     :cal s:GitPush(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPull     :cal s:GitPull(<f-args>)

com! -nargs=? GitDiffThis :cal s:GitDiffThis(<f-args>)
com! -nargs=? GitChanges  :cal s:GitChanges(<f-args>)

com! GitSyncDisable       :augroup! GitSyncAG
com! GitSyncEnable        :cal s:git_sync_au()

" ===========================================================
" }}}
" Options {{{
" ===========================================================
cal s:defopt('g:git_command','git')
cal s:defopt('g:fastgit_abbr_cmd',1)
cal s:defopt('g:fastgit_sync_freq',0)   " per updatetime ( which is 4sec by default )
cal s:defopt('g:fastgit_sync_auto',0)        " disabled by default.
cal s:defopt('g:fastgit_sync_bg',1)     " background sync , which is recommanded if you enabled auto sync
cal s:defopt('g:fastgit_default_mapping',1)
cal s:defopt('g:fastgit_statusline' , 'f' )  " f,a
cal s:defopt('g:fastgit_background_commit',1)
" ===========================================================
" }}}

if g:fastgit_default_mapping
  nmap <leader>ci  :GitCommit<CR>
  nmap <leader>ca  :GitCommitAll<CR>

  nmap <leader>gp   :GitPush<CR>
  nmap <leader>gl   :GitPull<CR>
  nmap <leader>ggdi :GitDiffThis<CR>
  nmap <leader>gb   :GitBranch<CR>
endif

if g:fastgit_abbr_cmd
  cabbr gci GitCommit
  cabbr gca GitCommitAll

  cabbr gpush GitPush
  cabbr gpull GitPull

  cabbr gpp GitPush
  cabbr gll GitPull

  cabbr gdiff GitDiffThis
  cabbr gbr   GitBranch
endif

if g:fastgit_statusline == 'f'  " full
  cal s:toggle_statusline()
elseif g:fastgit_statusline == 'a'  " append git info if we have enough space.
  let s:stl = &stl
  if strlen(s:stl) < 70
    cal s:append_statusline(s:stl)
  endif
  unlet s:stl
endif

if g:fastgit_sync_auto
  cal s:git_sync_au()
endif
cal s:init_plugin()
