" vim:et:sw=2:fdm=marker:fdl=0:
"
" hypergit.vim
"
" Author: Cornelius
" Email:  cornelius.howl@gmail.com
" Web:    http://oulixe.us/
" Version: 2.06


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

" Help {{{

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

fun! s:Help.redraw()
  cal s:Help.show_brief()
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
" TreeMenu {{{

" MenuBuffer Class {{{
let s:MenuBuffer = { 'buf_nr' : -1 , 'items': [  ] }

fun! s:MenuBuffer.create(options)
  let menu_obj = copy(self)
  let menu_obj.items = [ ]
  cal extend(menu_obj,a:options)
  cal menu_obj.init_buffer()
  return menu_obj
endf

fun! s:MenuBuffer.init_buffer()
  let win = self.findWindow(1)
  setfiletype MenuBuffer
  setlocal buftype=nofile bufhidden=hide nonu nohls
  setlocal fdc=0
  setlocal cursorline

  syn match MenuId +\[\d\+\]$+
  syn match MenuPre  "^[-+~|]\+"
  syn match MenuLabelExecutable +\(^[-]-*\)\@<=[a-zA-Z0-9-()._/ ]*+
  syn match MenuLabelExpanded   +\(^[~]-*\)\@<=[a-zA-Z0-9-()._/ ]*+
  syn match MenuLabelCollapsed  +\(^[+]-*\)\@<=[a-zA-Z0-9-()._/ ]*+

  hi MenuId ctermfg=black ctermbg=black
  hi MenuPre ctermfg=darkblue
  hi CursorLine cterm=underline

  hi MenuLabelExpanded ctermfg=blue
  hi MenuLabelCollapsed ctermfg=yellow
  hi MenuLabelExecutable ctermfg=white

  let b:_menu = self

  nnoremap <silent><buffer> o :cal b:_menu.toggleCurrent()<CR>
  nnoremap <silent><buffer> O :cal b:_menu.toggleCurrentR()<CR>
  nnoremap <silent><buffer> <Enter>  :cal b:_menu.execCurrent()<CR>
endf

fun! s:MenuBuffer.setBufNr(nr)
  let self.buf_nr = a:nr
endf

fun! s:MenuBuffer.addItem(item)
  cal add(self.items,a:item)
  return a:item
endf

fun! s:MenuBuffer.addItems(items)
  cal extend(self.items,a:items)
  return a:items
endf

fun! s:MenuBuffer.findWindow(switch)
  let win = bufwinnr( self.buf_nr )
  if win != -1 && a:switch
    exec (win-1) . 'wincmd w'
  endif
  return win
endf

fun! s:MenuBuffer.execCurrent()
  let id = self.getCurrentMenuId()
  let item = self.findItem(id)
  if type(item) == 4
    if has_key(item,'exec_cmd')
      exec item.exec_cmd
      if item.close
        close
      endif
    elseif has_key(item,'exec_func')
      exec 'cal ' . item.exec_func . '()' 
      if item.close
        close
      endif
    else
      echo "Can't execute!"
    endif
  endif
endf

fun! s:MenuBuffer.toggleCurrent()
  let id = self.getCurrentMenuId()
  let item = self.findItem(id)
  if type(item) == 4
    cal item.toggle()
  endif
  cal self.render()
endf

" FIXME:
fun! s:MenuBuffer.toggleCurrentR()
  let id = self.getCurrentMenuId()
  let item = self.findItem(id)
  if type(item) == 4
    cal item.toggleR()
  endif
  cal self.render()
endf

fun! s:MenuBuffer.render()
  let cur = getpos('.')
  let win = self.findWindow(1)
  let out = [  ]
  for item in self.items
    cal add(out,item.render())
  endfor

  setlocal modifiable
  if line('$') > 1 
    silent 1,$delete _
  endif
  let outstr=join(out,"\n")

  if has_key(self,'before_render')
    cal self.before_render()
  endif

  silent 0put=outstr

  if has_key(self,'after_render')
    cal self.after_render()
  endif

  cal setpos('.',cur)
  setlocal nomodifiable
endf

fun! s:MenuBuffer.getCurrentLevel()
  let line = getline('.')
  let idx = stridx(line,'[')
  return idx - 1
endf

fun! s:MenuBuffer.getCurrentMenuId()
  let id = matchstr(getline('.'),'\(\[\)\@<=\d\+\(\)\@>')
  return str2nr(id)
endf

fun! s:MenuBuffer.findItem(id)
  for item in self.items
    let l:ret = item.findItem(a:id)
    if type(l:ret) == 4
      return l:ret
    endif
    unlet l:ret
  endfor
  return -1
endf
" }}}
" MenuItem Class {{{

let s:MenuItem = {'id':0, 'expanded':0 , 'close':1 }

" Factory method
fun! s:MenuItem.create(options)
  let opt = a:options
  let self.id += 1
  let item = copy(self)

  if has_key(opt,'childs')
    let child_options = remove(opt,'childs' )
  else
    let child_options = [ ]
  endif

  cal extend(item,opt)
  if has_key(item,'parent')
    if has_key(item.parent,'childs')
      cal add(item.parent.childs,item)
    else
      let item.parent.childs = [ ]
      cal add(item.parent.childs,item)
    endif
  endif

  for ch in child_options
    cal item.createChild(ch)
  endfor
  return item
endf

fun! s:MenuItem.appendSeperator(text)
  cal self.createChild({ 'label' : '--- ' . a:text . ' ---' })
endf

" Object method
fun! s:MenuItem.createChild(options)
  let opt = a:options
  let child = s:MenuItem.create({ 'parent': self })

  if has_key(opt,'childs')
    let child_options = remove(opt,'childs' )
  else
    let child_options = [ ]
  endif

  cal extend(child,opt)

  for ch in child_options
    cal child.createChild(ch)
  endfor
  return child
endf

fun! s:MenuItem.findItem(id)
  if self.id == a:id
    return self
  else 
    if has_key(self,'childs')
      for ch in self.childs 
        let l:ret = ch.findItem(a:id)
        if type(l:ret) == 4
          return l:ret
        endif
        unlet l:ret
      endfor
    endif
    return -1
  endif
endf

fun! s:MenuItem.getLevel(lev)
  let level = a:lev
  if has_key(self,'parent')
    let level +=1
    return self.parent.getLevel(level)
  else 
    return level
  endif
endf

fun! s:MenuItem.displayString()
  let lev = self.getLevel(0)

  if has_key(self,'childs')
    if self.expanded 
      let op = '~'
    else
      let op = '+'
    endif
    let indent = repeat('-', lev)
    return op . indent . self.label . '[' . self.id . ']'
  elseif has_key(self,'parent')
    let indent = repeat('-', lev)
    return '-' . indent . self.label . '[' . self.id . ']'
  else
    let indent = repeat('-', lev)
    return '-' . indent . self.label . '[' . self.id . ']'
  endif
endf

fun! s:MenuItem.expandR()
  let self.expanded = 1
  if has_key(self,'childs')
    for ch in self.childs
      cal ch.expandR()
    endfor
  endif
endf

fun! s:MenuItem.collapseR()
  let self.expanded = 0
  if has_key(self,'childs')
    for ch in self.childs
      cal ch.collapseR()
    endfor
  endif
endf

fun! s:MenuItem.expand()
  let self.expanded = 1
endf

fun! s:MenuItem.collapse()
  let self.expanded = 0
endf

fun! s:MenuItem.toggle()
  if self.expanded == 1
    cal self.collapse()
  else
    cal self.expand()
  endif
endf

fun! s:MenuItem.toggleR()
  if self.expanded == 1
    cal self.collapseR()
  else
    cal self.expandR()
  endif
endf

fun! s:MenuItem.render( )
  let printlines = [ self.displayString()  ]
  if has_key(self,'childs') && self.expanded 
    for ch in self.childs 
      cal add( printlines, ch.render() )
    endfor
  endif
  return join(printlines,"\n")
endf

" }}}

" }}}
" Git Commands {{{

fun! s:GitCurrentBranch()
   let name = split(system("git branch | grep '^*' | cut -c3-"))
   return name[0]
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
    exec printf('! clear && %s log %s..%s',g:git_bin,since,until)
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
  exec printf('! clear && %s push %s %s',g:git_bin,remote,branch)
endf

fun! s:GitPull(...)
  if a:0 == 1
    let remote = a:1
  else
    let remote = input("Remote:","",'customlist,GitRemoteNameCompletion')
  endif
  let branch = input('Branch:', s:GitCurrentBranch() ,'customlist,GitLocalBranchCompletion')
  exec printf('! clear && %s pull %s %s',g:git_bin,remote,branch)
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

fun! s:initGitCommitSingleBuffer(target)
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()


  " XXX: make sure a:target exists, and it's in git commit list.
  let b:commit_target = a:target
  cal hypergit#commit#render_single(a:target)

  cal s:Help.reg("Git: commit " . a:target ," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:initGitCommitAllBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render()

  cal s:Help.reg("Git: commit --all"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:initGitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init('new',msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render_amend()

  cal s:Help.reg("Git: commit --amend"," s - (skip)",1)
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
  cal s:Help.redraw()
endf

fun! s:initGitMenuBuffer(bufn)
  let target_file = expand('%')


  cal hypergit#buffer#init('vnew',a:bufn)
  cal s:Help.reg("Git Menu",join([
        \" <Enter> - execute item",
        \" o       - open node",
        \" O       - open node recursively",
        \],"\n"),1)

  let m = s:MenuBuffer.create({ 'buf_nr': bufnr('.') })

  if strlen(target_file) > 0
    let m_fs = s:MenuItem.create({ 'label': "File Specific" , 'expanded': 1 })
    cal m_fs.createChild({ 
        \'label': printf('Commit "%s"', target_file ) ,
        \'close':0,
        \'exec_cmd': 'GitCommit ' . target_file })
    cal m_fs.createChild({ 
      \'label': printf('Add "%s"' , target_file ) ,
      \'exec_cmd': 'echo system("git add -v ' . target_file . '")' }) 
    cal m_fs.createChild({ 
      \'label': printf('Diff "%s"' , target_file ) ,
      \'exec_cmd': '!clear && git diff ' . target_file }) 
    cal m.addItem( m_fs )
  endif

  cal m.addItem( s:MenuItem.create({ 
    \'label': 'Commit All',
    \'close': 0,
    \'exec_cmd': 'GitCommitAll' }) )

  cal m.addItem(s:MenuItem.create({ 'label': 'Diff' , 'exec_cmd': '!clear && git diff' , 'childs': [
          \{ 'label': 'Diff to ..' , 'exec_cmd': '' } ] }))

  cal m.addItem(s:MenuItem.create({ 'label': 'Show' , 'exec_cmd': '!clear && git show' } ))

  " Push {{{
  let push_menu = m.addItem(s:MenuItem.create({ 'label': 'Push (all)' ,
    \ 'exec_cmd': '!clear && git push' , 
    \ 'expanded': 1,
    \ 'childs': [ { 'label': 'Push to ..' , 'exec_cmd': '' } ] }))

  " XXX: refactor this
  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
    cal push_menu.createChild({ 'label': 'Push to ' . rm_name , 'exec_cmd': '!clear && git push ' . rm_name })
  endfor
  "}}}

  " Pull {{{
  let pull_menu = m.addItem(s:MenuItem.create({ 'label': 'Pull (all)' , 
    \ 'exec_cmd': '!clear && git pull' , 
    \ 'expanded': 1,
    \ 'childs': [ { 'label': 'Pull from ..' , 'exec_cmd': '' } ] }))

  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
    cal pull_menu.createChild({ 'label': 'Pull from ' . rm_name , 'exec_cmd': '!clear && git pull ' . rm_name })
  endfor
  " }}}

  let menu_chkout= s:MenuItem.create({ 'label': 'Checkout Local Branch' })
  cal menu_chkout.createChild({ 'label': 'Checkout ..' , 'exec_cmd': '' })
  let local_branches = split(system('git branch | cut -c3-'),"\n")
  for br in local_branches
    cal menu_chkout.createChild({ 'label': 'Checkout ' . br ,
      \'exec_cmd': '!clear && git checkout ' . br })
  endfor
  cal m.addItem( menu_chkout )

  let menu_chkout2= s:MenuItem.create({ 'label': 'Checkout Remote Branch' })
  cal menu_chkout2.createChild({ 'label': 'Checkout ..' , 'exec_cmd': '' })
  let remote_branches = split(system('git branch -r | cut -c3-'),"\n")
  for br in remote_branches
    cal menu_chkout2.createChild({ 'label': 'Checkout ' . br ,
      \'exec_cmd': '!clear && git checkout -t ' . br })
  endfor
  cal m.addItem( menu_chkout2 )

  " Log {{{
  let menu_log= s:MenuItem.create({ 'label': 'Log' , 'expanded': 1 })
  cal menu_log.createChild({ 'label': 'Log' , 'exec_cmd': '!clear && git log ' })
  cal menu_log.createChild({ 'label': 'Log (patch)' , 'exec_cmd': '!clear && git log -p' })
  cal menu_log.createChild({ 
      \'label': 'Log (patch) since..until' , 
      \'exec_cmd': 'GitLog' })
  cal m.addItem( menu_log )
  " }}}

  " Remote {{{
  let menu_remotes= s:MenuItem.create({ 'label': 'Remotes' })
  cal menu_remotes.createChild({ 'label': 'Add ..' , 'exec_cmd': '' })
  cal menu_remotes.createChild({ 'label': 'List' , 'exec_cmd': '!clear && git remote -v ' })

  let remotes = split(system('git remote'),"\n")
  for rm_name in remotes
      cal menu_remotes.createChild( { 'label': rm_name , 'childs': [ 
            \{ 'label': 'Rename' , 'exec_cmd': 'echo "Not ready yet!" ' },
            \{ 'label': 'Prune' , 'exec_cmd': '!clear && git remote prune ' . rm_name },
            \{ 'label': 'Remove' , 'exec_cmd': '!clear && git remote rm ' . rm_name }
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

cal s:defopt('g:git_bin','git')
cal s:defopt('g:gitbuffer_default_position','topleft')
cal s:defopt('g:hypergitBufferHeight' , 15 )
cal s:defopt('g:hypergitBufferWidth' ,35 )
cal s:defopt('g:hypergitCAbbr',1)

com! -complete=file -nargs=1 GitCommit       :cal s:initGitCommitSingleBuffer(<q-args>)
com! GitCommitAll    :cal s:initGitCommitAllBuffer()
com! GitCommitAmend  :cal s:initGitCommitAmendBuffer()
com! ToggleGitMenu   :cal s:GitMenuBufferToggle()

com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPush     :cal s:GitPush(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=? GitPull     :cal s:GitPull(<f-args>)
com! -complete=customlist,GitRevCompletion        -nargs=? GitLog      :cal s:GitLog(<f-args>)
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteAdd :cal s:RemoteAdd( <f-args> )
com! -complete=customlist,GitRemoteNameCompletion -nargs=1 GitRemoteDel :cal s:RemoteRm( <f-args> )

nmap <silent> <leader>ci  :exec 'GitCommit ' . expand('%')<CR>
nmap <silent> <leader>ca  :GitCommitAll<CR>
nmap <silent> <leader>g   :ToggleGitMenu<CR>

if g:hypergitCAbbr
  cabbr glog GitLog
  cabbr gpush GitPush
  cabbr gpull GitPull
  cabbr gmadd GitRemoteAdd
  cabbr gmdel GitRemoteDel
endif
