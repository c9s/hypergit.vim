" vim:et:sw=2:
"
" Fastgit
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 1.7
"


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

fun! s:close_buffer()
  bw!
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
  echo cmd
  let out = system( cmd )
  echo out

  silent 1,$delete _
  cal s:refresh_branch_buffer()
endf

fun! s:merge_branch(branch)
  let out = system('git merge ' . a:branch )
  echo out
endfun

fun! s:refresh_branch_buffer()
  let out = system('git branch -a')
  let lines = ["HELP: o: checkout branch  p: push  l: pull  m: merge"]
  cal add(lines,'---------------------------------------')
  cal extend(lines, split( out , "\n" ))
  cal setline(1, lines )
  cal search('^\*')
endf

com! -nargs=1 GitSwitchBranch  :cal s:switch_branch(<f-args>)
com! -nargs=1 GitMergeBranch   :cal s:merge_branch(<f-args>)

fun! s:open_stash_buffer()
  8new
  cal s:init_buffer()
  setlocal noswapfile  buftype=nofile bufhidden=hide
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
  file GitStashList
  setfiletype gitstashlist
  autocmd BufWinLeave <buffer>   :cal s:close_buffer()
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

fun! s:open_branch_switch_buffer()
  8new
  cal s:init_buffer()
  setlocal noswapfile  buftype=nofile bufhidden=hide
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
  file GitBranchList
  " init syntax
  setfiletype gitbranchlist
  syn match RemoteBranch  "^\s\+remotes/.*$"
  syn match CurrentBranch "^\*\s.*$"
  syn match LocalBranch   "^\s\+\(remotes\)\@![a-zA-Z/_-]\+"
  hi link RemoteBranch Function 
  hi LocalBranch   ctermfg=blue
  hi CurrentBranch ctermfg=red
  autocmd BufWinLeave <buffer>   :cal s:close_buffer()
  nmap <silent> <buffer> o    :exec 'GitSwitchBranch ' . substitute(getline('.'),'^\*','','')<CR>
  nmap <silent> <buffer> m    :exec 'GitMergeBranch ' . substitute(getline('.'),'^\*','','')<CR>
  cal s:refresh_branch_buffer()
endf

fun! s:branch_list_toggle()
  let b = bufnr('BranchList')
  if b == -1 
    cal s:open_branch_switch_buffer()
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
  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_commit_buffer()
  exec printf('autocmd BufWinLeave <buffer> :cal s:single_commit("%s","%s")',commit,a:file)
  startinsert
endf

fun! s:commit_all_file()
  let commit = tempname()
  exec 'rightbelow 6split' . commit
  cal s:init_commit_buffer()
  exec printf('autocmd BufWinLeave <buffer> :cal s:commit("%s")',commit)
  startinsert
endf

fun! s:init_diff_buffer()
  cal s:init_buffer()

endf

" XXX: use built-in git syntax
fun! s:init_commit_buffer()
  cal s:init_buffer()
  setlocal nu
  setlocal syntax=git-fast-commit
  setfiletype git-fast-commit
  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function
endf

fun! s:init_buffer()
  setlocal modifiable noswapfile bufhidden=hide nobuflisted nowrap cursorline
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
      cal s:echo( file . ' added' )
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:git_command . ' rm ' . file )   " XXX: detect failure
      cal s:echo( file . ' deleted')
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf

fun! s:commit(msgfile)
  if ! s:can_commit(a:msgfile)
    return
  endif

  cal s:filter_message_op(a:msgfile)

  echo "committing "
  let ret = system( printf('%s commit -a -F %s ', g:git_command , a:msgfile ) )
  echo ret
  echo "committed"
endf

fun! s:can_commit(msgfile)
  if ! filereadable(a:msgfile)
    exec 'bw '.a:msgfile
    cal s:echo('skipped.')
    return 0
  else
    return 1
  endif
endf

fun! s:single_commit(msgfile,file)
  if ! s:can_commit(a:msgfile)
    return
  endif

  cal s:filter_message_op(a:msgfile)

  echo "committing " . a:file
  let ret = system( printf('%s commit -F %s %s ', g:git_command , a:msgfile, a:file ) )
  echo ret
  echo "committed"
endf

fun! s:skip_commit(file)
  if &filetype != 'git-fast-commit'
    return
  endif
  if filereadable(a:file)
    cal delete(a:file)
  endif
  bw
  cal s:echo('skipped')
endf

fun! s:diff_window()
  exec 'leftabove 10new'
  cal s:init_diff_buffer()

endf

" XXX: refactor this
function! s:git_diff_this(...)
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

  " Begin diff
  exe "vert diffsplit" . tmpfile
  exe "set filetype=" . ftype
  set foldmethod=diff
  wincmd l
endf

fun! s:git_changes(...)

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

fun! s:git_push(...)
  let cmd = [ g:git_command ,"push" ]
  if a:0 == 1
    cal add(cmd,a:1)
  endif
  cal s:echo("git: pushing (Ctrl-c to stop)")
  cal s:exec_cmd( cmd )
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

fun! s:git_pull(...)
  let cmd = [ g:git_command ,"pull" ]
  if a:0 == 1
    cal add(cmd,a:1)
  endif
  cal s:echo("git: pulling (Ctrl-c to stop)")
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
  let g:git_ch = s:count_changes_from_yesterday()
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
  echo cmd_output
endf

com! Gbranchtoggle      :cal s:branch_list_toggle()
com! Gci                :cal s:commit_single_file(expand('%'))
com! Gcommmit           :cal s:commit_single_file(expand('%'))
com! Gca                :cal s:commit_all_file()
com! Gccommitall        :cal s:commit_all_file()
com! Gskip              :cal s:skip_commit(expand('%'))
com! Gdi                :cal s:diff_window()
com! Gstl               :cal s:toggle_statusline()

com! -nargs=? Gpush     :cal s:git_push(<f-args>)
com! -nargs=? Gpull     :cal s:git_pull(<f-args>)
com! -nargs=? Gdiffthis :cal s:git_diff_this(<f-args>)
com! -nargs=? Gdithis   :cal s:git_diff_this(<f-args>)
com! -nargs=? Gchanges  :cal s:git_changes(<f-args>)

fun! s:fastgit_default_mapping()
  nmap <leader>ci  :Gci<CR>
  nmap <leader>ca  :Gca<CR>

  " git prefix mapping
  nmap <leader>gp   :Gpush<CR>
  nmap <leader>gl   :Gpull<CR>
  nmap <leader>ggdi :Gdiffthis<CR>
  nmap <leader>gb   :Gbranchtoggle<CR>
endf

" Options
cal s:defopt('g:git_command','git')
cal s:defopt('g:fastgit_sync_freq',0)   " per updatetime ( 4sec by default )
cal s:defopt('g:fastgit_sync',1)
cal s:defopt('g:fastgit_sync_bg',1)
cal s:defopt('g:fastgit_default_mapping',1)
cal s:defopt('g:fastgit_statusline' , 'f' )  " f,a

if g:fastgit_default_mapping
  cal s:fastgit_default_mapping()
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

augroup GitSyncAG
  au!
  au CursorHold *.* nested cal s:git_sync_background()
augroup END

com! GitSyncDisable   :augroup! GitSyncAG
com! GitSyncEnable    :augroup GitSyncAG

if g:fastgit_sync
  :GitSyncEnable
endif
