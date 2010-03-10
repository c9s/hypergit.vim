" vim:et:sw=2:fdm=marker:fdl=0:
"
" hypergit.vim
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 2.1


if exists('g:loaded_hypergit')
  "finish
elseif v:version < 702
  echoerr 'ahaha. your vim seems too old , please do upgrade. i found your vim is ' . v:version . '.'
  finish
endif

let g:loaded_hypergit = 1

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

fun! s:GitCurrentBranch()
   let name = split(system("git branch | grep '^*' | cut -c3-"))
   return name[0]
endf

fun! s:GitRm(...)
  if a:0 == 0
    let file = expand('%')
  elseif a:0 == 1
    let file = a:1
  endif
  echo "Deleting File: " . file
  exec '!git rm -v ' . file
endf

fun! s:GitAdd(...)
  if a:0 == 0
    let file = expand('%')
  elseif a:0 == 1
    let file = a:1
  endif
  echo "Adding File: " . file
  exec '!git add -v ' . file
endf

fun! s:GitLog(...)
  if a:0 == 1
    let [since,until] = split(a:1)
  else
    "let commit = input("Commit:","",'customlist,GitRemoteNameCompletion')
    let since = input("Since:","")
    let until = input("Until:","")
  endif
  if strlen(since) && strlen(until)
    exec printf('! clear & %s log %s..%s',g:git_bin,since,until)
  else
    echo "..."
  endif
endf

fun! s:GitPush(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:","",'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', s:GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear & %s push %s %s',g:git_bin,remote,branch)
endf

fun! s:GitPull(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:","",'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', s:GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear & %s pull %s %s',g:git_bin,remote,branch)
endf

fun! s:RemoteAdd(...)
  if a:0 == 1
    let remote = input("Remote Name:","")
  elseif a:0 == 2
    let remote = a:1
  endif
  let uri = input("Git URI:",'')
  if strlen(uri) > 0
    cal system( printf('git remote add %s %s',remote ,uri))
    echo printf("Remote Added. %s => %s",remote,uri)
  endif
endf

fun! s:RemoteRename(remote)
  let newname = input("New Remote Name:",'')
  if strlen(newname) > 0
    cal system(printf('git remote rename %s %s',a:remote ,newname))
    echo printf("Remote renamed. %s => %s",a:remote,newname)
  endif
endf

fun! s:RemoteRm(remote)
  let ret = system( printf('git remote rm %s ',a:remote))
  let ret = substitute( ret , "\n" , "" , 'g')
  if v:shell_error
    echohl WarningMsg | echo "Can't remove remote '"  . a:remote . "': " . ret | echohl None
  else
    cal s:echo( "Remote " . a:remote . " removed." )
  endif
endf

fun! s:RemoteRename(remote)
  let new_name = input("New Remote Name:","")
  let ret = system( printf('git remote rename %s %s',a:remote,new_name))
  echo ret
endf

" }}}

fun! s:initGitStatusBuffer()
  cal hypergit#buffer#init('GitCommit')
endf

fun! s:initGitBranchBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitLogBuffer()
  cal hypergit#buffer#init()
endf

fun! s:initGitRemoteBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitStashBuffer()
  cal hypergit#buffer#init()
endf

" Commit Buffers 
fun! s:initGitCommitBuffer()
  setlocal nu
  syntax match GitAction '^\![AD] .*'
  hi link GitAction Function

  nmap <silent><buffer> s  :cal g:git_skip_commit()<CR>
  autocmd BufUnload <buffer> :cal g:git_do_commit()

  setfiletype gitcommit
endf

fun! s:initGitCommitSingleBuffer(...)
  if a:0 == 0
    let target = expand('%')
  elseif a:0 == 1
    let target = a:1
  endif

  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()

  " XXX: make sure target exists, and it's in git commit list.
  let b:commit_target = target
  cal hypergit#commit#render_single(target)

  cal g:Help.reg("Git: commit " . target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:initGitCommitAllBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render()

  cal g:Help.reg("Git: commit --all"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:initGitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render_amend()

  cal g:Help.reg("Git: commit --amend"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
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
" 

" Git Menu 


fun! DrawGitMenuHelp()
  cal g:Help.redraw()
endf

fun! s:initGitMenuBuffer(bufn)
  let target_file = expand('%')


  cal hypergit#buffer#init('vnew',a:bufn)
  cal g:Help.reg("Git Menu",join([
        \" <Enter> - execute item",
        \" o       - open node",
        \" O       - open node recursively",
        \],"\n"),1)

  let m = g:MenuBuffer.create({ 'buf_nr': bufnr('.') })

  if strlen(target_file) > 0
    let m_fs = g:MenuItem.create({ 'label': "File Specific" , 'expanded': 1 })
    cal m_fs.createChild({ 
        \'label': printf('Commit "%s"', target_file ) ,
        \'close':0,
        \'exec_cmd': 'GitCommit ' . target_file })
    cal m_fs.createChild({ 
        \'label': printf('Add "%s"' , target_file ) ,
        \'exec_cmd': 'echo system("git add -v ' . target_file . '")' }) 
    cal m_fs.createChild({ 
        \'label': printf('Diff "%s"' , target_file ) ,
        \'exec_cmd': '!clear & git diff ' . target_file }) 
    cal m.addItem( m_fs )
  endif

  cal m.addItem( g:MenuItem.create({ 
    \'label': 'Edit Git Config',
    \'close': 0,
    \'exec_cmd': 'GitConfig' }) )

  cal m.addItem( g:MenuItem.create({ 
    \'label': 'Commit All',
    \'close': 0,
    \'exec_cmd': 'GitCommitAll' }) )

  cal m.addItem(g:MenuItem.create({ 'label': 'Diff' , 'exec_cmd': '!clear & git diff' , 'childs': [
          \{ 'label': 'Diff to ..' , 'exec_cmd': '' } ] }))

  cal m.addItem(g:MenuItem.create({ 'label': 'Show' , 'exec_cmd': '!clear & git show' } ))

  " Push {{{
  let push_menu = m.addItem(g:MenuItem.create({ 'label': 'Push (all)' ,
    \ 'exec_cmd': '!clear & git push' , 
    \ 'expanded': 1,
    \ 'childs': [ { 'label': 'Push to ..' , 'exec_cmd': '' } ] }))

  " XXX: refactor this
  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
    cal push_menu.createChild({ 'label': 'Push to ' . rm_name , 'exec_cmd': '!clear & git push ' . rm_name })
  endfor
  "}}}

  " Pull {{{
  let pull_menu = m.addItem(g:MenuItem.create({ 'label': 'Pull (all)' , 
    \ 'exec_cmd': '!clear & git pull' , 
    \ 'expanded': 1,
    \ 'childs': [ { 'label': 'Pull from ..' , 'exec_cmd': '' } ] }))

  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
    cal pull_menu.createChild({ 'label': 'Pull from ' . rm_name , 'exec_cmd': '!clear & git pull ' . rm_name })
  endfor
  " }}}

  let menu_chkout= g:MenuItem.create({ 'label': 'Checkout Local Branch' })
  cal menu_chkout.createChild({ 'label': 'Checkout ..' , 'exec_cmd': '' })
  let local_branches = split(system('git branch | cut -c3-'),"\n")
  for br in local_branches
    cal menu_chkout.createChild({ 'label': 'Checkout ' . br ,
      \'exec_cmd': '!clear & git checkout ' . br })
  endfor
  cal m.addItem( menu_chkout )

  let menu_chkout2= g:MenuItem.create({ 'label': 'Checkout Remote Branch' })
  cal menu_chkout2.createChild({ 'label': 'Checkout ..' , 'exec_cmd': '' })
  let remote_branches = split(system('git branch -r | cut -c3-'),"\n")
  for br in remote_branches
    cal menu_chkout2.createChild({ 'label': 'Checkout ' . br ,
      \'exec_cmd': '!clear & git checkout -t ' . br })
  endfor
  cal m.addItem( menu_chkout2 )

  " Log {{{
  let menu_log= g:MenuItem.create({ 'label': 'Log' , 'expanded': 1 })
  cal menu_log.createChild({ 'label': 'Log' , 'exec_cmd': '!clear & git log ' })
  cal menu_log.createChild({ 'label': 'Log (patch)' , 'exec_cmd': '!clear & git log -p' })
  cal menu_log.createChild({ 
      \'label': 'Log (patch) since..until' , 
      \'exec_cmd': 'GitLog' })
  cal m.addItem( menu_log )
  " }}}

  " Remote {{{
  let menu_remotes= g:MenuItem.create({ 'label': 'Remotes' })
  cal menu_remotes.createChild({ 
      \'label': 'Add ..' , 
      \'exec_cmd': 'GitRemoteAdd' })
  cal menu_remotes.createChild({ 'label': 'List' , 'exec_cmd': '!clear & git remote -v ' })

  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
      cal menu_remotes.createChild( { 'label': rm_name , 'childs': [ 
            \{ 'label': 'Rename' , 'exec_cmd': 'GitRemoteRename ' . rm_name  },
            \{ 'label': 'Prune'  , 'exec_cmd':  '  ' },
            \{ 'label': 'Remove' , 'exec_cmd': 'GitRemoteDel ' . rm_name }
            \]} )
  endfor
  cal m.addItem( menu_remotes )
  " }}}

  let m.after_render = function("DrawGitMenuHelp")
  cal m.render()

  " Initialize Help Syntax
  syntax match HelpComment +^#.*+
  syntax match String      +".\{-}"+
  hi HelpComment ctermfg=blue
  hi String      ctermfg=red

  " reset cursor position
  cal cursor(2,1)
endf




fun! s:GitMenuBufferToggle()
  if bufname('%') =~ '^GitMenu'
    close
    return
  endif

  for wn in range(1,winnr('$'))
    if bufname(winbufnr(wn)) =~ '^GitMenu'
      let bufnr = winbufnr(wn)
      let bufname = bufname(bufnr)
      break
    endif
  endfor

  " found gitmenu in current tab
  if exists('bufnr') && exists('bufname')
      if exists('b:HypergitMenuBuffer') && bufname == b:HypergitMenuBuffer
          exec bufwinnr(bufnr) . "wincmd w"
          return
      else
          let pbufname = bufname('%')
          " XXX: hate , there is no command for hide a specified buffer or
          " window directlry
          exec bufwinnr(bufnr) . 'wincmd w'
          close
          exec bufwinnr(bufnr(pbufname)) . "wincmd w"
      endif
  endif

  " find my gitmenu
  if exists('b:HypergitMenuBuffer') && bufnr(b:HypergitMenuBuffer) != -1
      cal hypergit#buffer#init('vsplit',b:HypergitMenuBuffer)
      return
  endif
  let b:HypergitMenuBuffer = hypergit#buffer#next_name('GitMenu')
  cal s:initGitMenuBuffer(b:HypergitMenuBuffer)
endf

" Command Completion Functions {{{
fun! GitRevCompletion(lead,cmd,pos)
  let parts = split(a:cmd)
  if strlen(a:lead) > 0 && len(parts) > 2
    let last_part = remove(parts,-1)
  else
    let last_part = 'HEAD'
  endif
  " XXX: just use HEAD for now
  let last_part = 'HEAD'
  let revs = split(system(printf('git rev-list --max-count=%d %s',50,last_part)))
  cal filter( revs , 'v:val =~ "^' .a:lead. '"'  )
  return revs
endf

fun! GitRemoteNameCompletion(lead,cmd,pos)
  let names = split(system('git remote'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

fun! GitLocalBranchCompletion(lead,cmd,pos)
  let names = split(system('git branch | cut -c3-'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf

fun! GitRemoteBranchCompletion(lead,cmd,pos)
  let names = split(system('git branch -r | cut -c3-'),"\n")
  cal filter( names , 'v:val =~ "^' .a:lead. '"'  )
  return names
endf
" }}}

cal s:defopt('g:hypergitUntrackMode' , 'no' )
cal s:defopt('g:git_bin','git')
cal s:defopt('g:gitbuffer_default_position','topleft')
cal s:defopt('g:hypergitBufferHeight' , 15 )
cal s:defopt('g:hypergitBufferWidth' ,35 )
cal s:defopt('g:hypergitCAbbr',1)
cal s:defopt('g:hypergitDefaultMapping',1)

com! -complete=file -nargs=?        GitAdd    :cal s:GitAdd(<f-args>)
com! -complete=file -nargs=?        GitRm     :cal s:GitRm(<f-args>)
com! -complete=file -nargs=?        GitCommit :cal s:initGitCommitSingleBuffer(<f-args>)
com! GitCommitAll    :cal s:initGitCommitAllBuffer()
com! GitCommitAmend  :cal s:initGitCommitAmendBuffer()
com! ToggleGitMenu   :cal s:GitMenuBufferToggle()

com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPush     :cal s:GitPush(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPull     :cal s:GitPull(<f-args>)
com! -complete=customlist,GitRevCompletion        -nargs=? GitLog      :cal s:GitLog(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitRemoteAdd :cal s:RemoteAdd( <q-args> )
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteDel :cal s:RemoteRm(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteRename :cal s:RemoteRename(<f-args>)

com! GitConfig   :tabe ~/.gitconfig

if g:hypergitDefaultMapping
  nmap <silent> <leader>ci   :GitCommit<CR>
  nmap <silent> <leader>ca   :GitCommitAll<CR>
  nmap <silent> <leader>ga   :GitAdd<CR>
  nmap <silent> <leader>G    :ToggleGitMenu<CR>
  nmap <silent> <leader>gp   :GitPush<CR>
  nmap <silent> <leader>gl   :GitPull<CR>
endif

if g:hypergitCAbbr
    cabbr   glog       GitLog
    cabbr   gpush      GitPush
    cabbr   gpull      GitPull
    cabbr   gmadd      GitRemoteAdd
    cabbr   gmdel      GitRemoteDel
    cabbr   gmrename   GitRemoteRename
endif
