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
  echoerr 'Ahaha. your vim seems too old , please do upgrade. i found your vim is ' . v:version . '.'
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
    let [since,til] = split(a:1)
  elseif a:0 == 0
    "let commit = input("Commit:","",'customlist,GitRemoteNameCompletion')
    let since = input("Since:","")
    let til = input("Til:","")
  elseif a:0 == 2
    let since = a:1
    let til = a:2
  endif
  if strlen(since) > 1 && strlen(til) > 1
    exec printf('! clear & %s log %s..%s',g:git_bin,since,til)
  elseif strlen(since) > 1 
    exec printf('! clear & %s log %s..HEAD',g:git_bin,since)
  else
    echo "..."
  endif
endf

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

fun! s:GitPush(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:",GitDefaultRemoteName(),'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear & %s push %s %s',g:git_bin,remote,branch)
endf

fun! s:GitPull(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:",GitDefaultRemoteName(),'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
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

fun! s:initGitLogBuffer()
  cal hypergit#buffer#init()
endf

fun! s:initGitRemoteBuffer()
  cal hypergit#buffer#init()

endf

fun! s:initGitStashBuffer()
  cal hypergit#buffer#init()
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

  let m = g:MenuBuffer.create({ 'rootLabel': 'Git' , 'buf_nr': bufnr('.') })

  if strlen(FindDotGit()) > 0
    if strlen(target_file) > 0
      let m_fs = g:MenuItem.create({ 'label': "File Specific" , 'expanded': 1 })
      cal m_fs.createChild({ 
          \'label': printf('Commit "%s"', target_file ) ,
          \'close':0,
          \'exe': 'GitCommit ' . target_file })
      cal m_fs.createChild({ 
          \'label': printf('Add "%s"' , target_file ) ,
          \'exe': 'echo system("git add -v ' . target_file . '")' }) 
      cal m_fs.createChild({ 
          \'label': printf('Diff "%s"' , target_file ) ,
          \'exe': '!clear & git diff ' . target_file }) 
      cal m.addItem( m_fs )
    endif

    cal m.createChild({ 
      \'label': 'Commit All',
      \'close': 0,
      \'exe': 'GitCommitAll' })

    " extended features
    " =================
    if executable('git-snapshot')
      let s = m.createChild({'label': 'Snapshot'})
      cal s.createChild( {'label': 'Snapshot', 'exe': '!git snapshot'})
      cal s.createChild( {'label': 'Check Log', 'exe': '!git log refs/snapshots/HEAD -p'})
    endif
    if executable('github-import')
      cal m.createChild({'label': 'Import to Github' , 'exe': '!github-import'})
    endif

    cal m.createChild({ 'label': 'Clone ...' , 'exe': '!git clone ' , 'inputs':[
                  \['From:','']]})

    cal m.createChild({ 'label': 'Pull ...' , 'exe': '!git pull ' , 'inputs':[
                \ ['Remote:' , function('GitDefaultRemoteName') , 'customlist,GitRemoteNameCompletion']  , 
                \ ['Branch:' , function('GitDefaultBranchName') , 'customlist,GitLocalBranchCompletion' , 0 ] 
                  \]})

    cal m.createChild({ 'label': 'Push ...' , 'exe': '!git push ' , 'inputs':[
                \ ['Remote:' , function('GitDefaultRemoteName') , 'customlist,GitRemoteNameCompletion']  , 
                \ ['Branch:' , function('GitDefaultBranchName') , 'customlist,GitLocalBranchCompletion' , 0 ]
                  \]})


    cal m.createChild({ 'label': 'Diff (all)' , 'exe': '!clear & git diff' , 'childs': [
            \   { 'label': 'Diff to file'   , 'exe': '!clear & git diff' , 'inputs': [ ['File to diff:'   , '' , 'file'] ] }
            \ , { 'label': 'Diff to dir'    , 'exe': '!clear & git diff' , 'inputs': [ ['Dir to diff:'    , '' , 'dir' ] ] }
            \ , { 'label': 'Diff to buffer' , 'exe': '!clear & git diff' , 'inputs': [ ['Buffer to diff:' , '' , 'buffer' ] ] }
            \ ] })

    cal m.createChild({ 'label': 'Show' , 'exe': '!clear & git show' } )



    let push_menu = m.createChild({ 'label': 'Push' , 'expanded': 1 })
    cal push_menu.createChild({ 'label': 'Push all' , 'exe': '!clear & git push --all' })

    let pull_menu = m.createChild({ 'label': 'Pull' , 'expanded': 1 })
    let remotes = split(system('git remote'),"\n")

    for rm_name in remotes
      cal pull_menu.createChild({ 'label': 'Pull from ' . rm_name , 'exe': '!clear & git pull ' . rm_name })
      cal push_menu.createChild({ 'label': 'Push to ' . rm_name , 'exe': '!clear & git pull ' . rm_name })
    endfor

    let br_item = m.createChild({ 'label': 'Branch' })
    cal br_item.createChild({ 'label': 'Create branch' , 'exe': '!git branch', 'inputs':[['Branch Name:',''] ], 'refresh':1 })
    cal br_item.createChild({ 'label': 'Create branch from' , 'exe': '!git branch', 'inputs':[['Branch Name:',''],['From Branch',function('GitDefaultBranchName'),'customlist,GitLocalBranchCompletion']], 'refresh':1 })

    " Local Branch Checkout {{{
    let menu_chkout= g:MenuItem.create({ 'label': 'Checkout Local Branch' })
    cal menu_chkout.createChild({ 'label': 'Checkout ..' , 'exe': '!git checkout ' , 'inputs': [['Branch:','','customlist,GitLocalBranchCompletion']] })

    let local_branches = split(system('git branch | cut -c3-'),"\n")
    for br in local_branches
      cal menu_chkout.createChild({ 'label': 'Checkout ' . br ,
        \'exe': '!clear & git checkout ' . br })
    endfor
    cal br_item.addItem( menu_chkout )
    " }}}

    " Remote Branch Checkout {{{
    let menu_chkout2= g:MenuItem.create({ 'label': 'Checkout Remote Branch' })
    cal menu_chkout2.createChild({ 'label': 'Checkout ..' , 'exe': '!git checkout -t ', 'inputs': [ ['Branch:','','customlist,GitRemoteBranchCompletion'] ] })
    let remote_branches = split(system('git branch -r | cut -c3-'),"\n")
    for br in remote_branches
      cal menu_chkout2.createChild({ 'label': 'Checkout ' . br ,
        \'exe': '!clear & git checkout -t ' . br })
    endfor
    cal br_item.addItem( menu_chkout2 )
    " }}}
    " Log {{{
    let menu_log= g:MenuItem.create({ 'label': 'Log' , 'expanded': 1 })
    cal menu_log.createChild({ 
          \ 'label': 'Log' , 'exe': '!clear & git log ' }) 
    cal menu_log.createChild({ 'label': 'Log (patch)' , 'exe': '!clear & git log -p' }) 
    cal menu_log.createChild({ 
          \'label': 'Log (patch) since..til' , 
          \'exe': 'GitLog' , 'inputs':[ ['Since:','','',0], ['Til:',''] ] }) 
    cal m.addItem( menu_log )
    " }}}
    " Remote {{{
    let menu_remotes= g:MenuItem.create({ 'label': 'Remotes' })
    cal menu_remotes.createChild({ 
        \'label': 'Add ..' , 
        \'exe': 'GitRemoteAdd' })
    cal menu_remotes.createChild({ 'label': 'List' , 'exe': '!clear & git remote -v ' })

    let remotes = split(system('git remote'),"\n")
    for rm_name in remotes
        cal menu_remotes.createChild( { 'label': rm_name , 'childs': [ 
              \{ 'label': 'Rename' , 'exe': 'GitRemoteRename ' . rm_name  },
              \{ 'label': 'Prune'  , 'exe': '!git remote prune' , 'inputs': [ 
                \ ['Remote:' , function('GitDefaultRemoteName') , 'customlist,GitRemoteNameCompletion'] ]},
              \{ 'label': 'Remove' , 'exe': 'GitRemoteDel ' . rm_name }
              \]} )
    endfor
    cal m.addItem( menu_remotes )
    " }}}

  else
    cal m.createChild({ 'label': 'Create Repository Here' ,'exe': '!git init' , 'refresh':1 })
  endif

  " Global Items
  cal m.createChild({ 
    \'label': 'Edit Git Config',
    \'close': 0,
    \'exe': 'GitConfig' })

  " support for git sync
  if executable('git-sync') 
    let gc_config = m.createChild({'label': 'Sync'})
    let gitconfig = readfile(expand('~/.gitconfig'))
    for line in gitconfig
      if line =~ '^\[sync'
        let category = substitute(line,'\[sync\s\+[''"]\(.*\)[''"]\]','\1','')
        cal gc_config.createChild({ 'label':  'Sync ' . category , 'exe': '!git sync ' . category })
      endif
    endfor
  endif


  let m.after_render = function("DrawGitMenuHelp")
  cal m.render()

  " Initialize Help Syntax
  syntax match HelpComment +^#.*+
  syntax match String      +".\{-}"+

  hi HelpComment guibg=darkblue guifg=gold ctermbg=blue ctermfg=yellow
  hi String      ctermfg=red

  " reset cursor position
  cal cursor(2,1)
endf



" Menu Buffer Toggle:
"   this buffer toggle function find a git menu buffer of current buffer.  if
"   buffer is not loaded, then hide current git menu buffer(if found), and
"   create/reload one.
"
"   depends on current buffer.
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
          \ && bufexists( b:HypergitMenuBuffer )
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
      \ && bufexists( b:HypergitMenuBuffer )
      cal hypergit#buffer#init('vsplit',b:HypergitMenuBuffer)
      return
  endif
  let b:HypergitMenuBuffer = hypergit#buffer#next_name('GitMenu')
  cal s:initGitMenuBuffer(b:HypergitMenuBuffer)
endf


" Stash {{{
fun! s:showFromStashBuffer()
  let line = getline('.')
  let stashname = matchstr(line,'^\S*\(:\)\@=')
  let output = system( 'git stash show -v ' . stashname )
  botright new
  setlocal noswapfile nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile bufhidden=wipe
  silent put=output
  silent normal ggdd
  setfiletype git
  setlocal nomodifiable
endf

fun! s:dropFromStashBuffer()
  let stashname = matchstr( getline('.') ,'^\S*\(:\)\@=')
  echo system( 'git stash drop ' . stashname )
  bw
  cal s:GitStashBuffer()
endf

fun! s:applyFromStashBuffer()
  let stashname = matchstr( getline('.') ,'^\S*\(:\)\@=')
  let output = system( 'git stash apply ' . stashname )
  new
  setlocal noswapfile nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile bufhidden=wipe
  silent put=output
  silent normal ggdd
  setfiletype git-status
  setlocal nomodifiable
endf

fun! s:GitStashBuffer()
  tabnew
  setlocal noswapfile nobuflisted nowrap cursorline nonumber 
  setlocal fdc=0 buftype=nofile bufhidden=wipe
  let output = system('git stash list')
  put=output
  normal ggdd
  setfiletype git-stash
  silent file GitStashList

  nmap <script><buffer> S  :cal <SID>showFromStashBuffer()<CR>
  nmap <script><buffer> D  :cal <SID>dropFromStashBuffer()<CR>
  nmap <script><buffer> A  :cal <SID>applyFromStashBuffer()<CR>

  cal g:Help.reg("Git Stash",
    \" S - Show\n" .
    \" D - Drop\n" .
    \" A - Apply\n"
    \,1)
  setlocal nomodifiable
endf
com! -nargs=?        GitStash :cal s:GitStashBuffer()
" }}}

cal s:defopt('g:hypergitUntrackMode' , 'no' )
cal s:defopt('g:git_bin','git')
cal s:defopt('g:gitbuffer_default_position','topleft')
cal s:defopt('g:hypergitBufferHeight' , 15 )
cal s:defopt('g:hypergitBufferWidth' ,35 )
cal s:defopt('g:hypergitCAbbr',1)
cal s:defopt('g:hypergitDefaultMapping',1)
cal s:defopt('g:hypergitBackgroundCommit',0)

com! -complete=file -nargs=?        GitAdd    :cal s:GitAdd(<f-args>)
com! -complete=file -nargs=?        GitRm     :cal s:GitRm(<f-args>)
com! -complete=file -nargs=?        GitCommit :cal GitCommitSingleBuffer(<f-args>)

com! GitCommitAll    :cal GitCommitAllBuffer()
com! GitCommitAmend  :cal GitCommitAmendBuffer()

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
  nmap <silent> <leader>gs   :GitStatus<CR>
  nmap <silent> <leader>gh   :GitStash<CR>
endif

if g:hypergitCAbbr
    cabbr   glog       GitLog
    cabbr   gpush      GitPush
    cabbr   gpull      GitPull
    cabbr   gmadd      GitRemoteAdd
    cabbr   gmdel      GitRemoteDel
    cabbr   gmrename   GitRemoteRename
endif
