" vim:et:sw=2:fdm=marker:fdl=0:
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
let g:hypergitBufferHeight = 15
let g:hypergitBufferWidth = 35

fun! s:defopt(name,val)
  if !exists(a:name)
    let {a:name} = a:val
  endif
endf

fun! s:echo(msg)
  redraw
  echomsg a:msg
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
" Menu {{{

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

  syn match MenuId +\[\d\+\]$+
  syn match MenuPre  "^[-+~|]\+"
  syn match MenuLabel +\(^[-+~|]\+\)\@<=[a-zA-Z0-9_/ ]*+
  hi MenuId ctermfg=black ctermbg=black
  hi MenuPre ctermfg=darkblue
  hi MenuLabel ctermfg=yellow

  let b:_menu = self

  " XXX: whcih is not seperated explicit , FIXME
  com! -buffer ToggleNode  :cal b:_menu.toggleCurrent()
  com! -buffer ToggleNodeR  :cal b:_menu.toggleCurrentR()

  nnoremap <silent><buffer> o :cal b:_menu.toggleCurrent()<CR>
  nnoremap <silent><buffer> O :cal b:_menu.toggleCurrentR()<CR>
  nnoremap <silent><buffer> <Enter>  :cal b:_menu.execCurrent()<CR>
endf

fun! s:MenuBuffer.setBufNr(nr)
  let self.buf_nr = a:nr
endf

fun! s:MenuBuffer.addItem(item)
  cal add(self.items,a:item)
endf

fun! s:MenuBuffer.addItems(items)
  cal extend(self.items,a:items)
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
    elseif has_key(item,'exec_func')
      exec 'cal ' . item.exec_func . '()' 
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

let s:MenuItem = {'id':0, 'expanded':0 }

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

" Object method
fun! s:MenuItem.createChild(options)
  let child = s:MenuItem.create({ 'parent': self })
  cal extend(child,a:options)
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
    return '|' . indent . self.label . '[' . self.id . ']'
  else
    let indent = repeat('-', lev)
    return '|' . indent . self.label . '[' . self.id . ']'
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

fun! s:initGitStatusBuffer()
  cal hypergit#buffer#init()

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
  cal hypergit#buffer#init(msgfile)
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
  cal hypergit#buffer#init(msgfile)
  cal s:initGitCommitBuffer()
  cal hypergit#commit#render()

  cal s:Help.reg("Git: commit --all"," s - (skip)",1)
  cal cursor(2,1)
  startinsert
endf

fun! s:initGitCommitAmendBuffer()
  let msgfile = tempname()
  cal hypergit#buffer#init(msgfile)
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
let g:git_cmds = [ ]
"cal add(g:git_cmds, { 'label': 'reset (hard)' , 'cmd': '!clear && git reset --hard'  }
"cal add(g:git_cmds, { 'label': 'push to origin' , 'cmd': '!clear && git push origin' }
"cal add(g:git_cmds, { 'label': 'pull from origin', 'cmd': '!clear && git pull origin' }
"cal add(g:git_cmds, { 'label': 'diff'            , 'cmd': '!clear && git diff' }
"cal add(g:git_cmds, { 'label': 'log (patch)'           , 'cmd': '!clear && git log -p' }
"cal add(g:git_cmds, { 'label': 'show'                  , 'cmd': '!clear && git show' }
" let g:git_cmds[ "* List Branchs" ] = "!clear && git branch -a"
" let g:git_cmds[ "* Checkout"     ] = "!clear && git checkout "


fun! DrawGitMenuHelp()
  cal s:Help.redraw()
endf

fun! s:initGitMenuBuffer()
  cal hypergit#buffer#init_v()
  cal s:Help.reg("Git Menu"," <Enter> - (execute item)",1)

  let m = s:MenuBuffer.create({ 'buf_nr': bufnr('.') })
  cal m.addItem(s:MenuItem.create({ 'label': 'diff' , 'exec_cmd': '!clear && git diff' , 'childs': [ { 'label': 'diff to ..' , 'exec_cmd': '' } ] }))

  cal m.addItem(s:MenuItem.create({ 'label': 'push' , 'exec_cmd': '!clear && git push' , 
    \ 'childs': [
    \  { 'label': 'push to origin' , 'exec_cmd': '!clear && git push origin' },
    \  { 'label': 'push to ..' , 'exec_cmd': '' }
    \] }))

  cal m.addItem(s:MenuItem.create({ 'label': 'pull' , 'exec_cmd': '!clear && git pull' , 
    \ 'childs': [
    \  { 'label': 'pull to origin' , 'exec_cmd': '!clear && git pull origin' },
    \  { 'label': 'pull to ..' , 'exec_cmd': '' }
    \] }))

  let m.after_render = function("DrawGitMenuHelp")
  cal m.render()

  file GitMenu

  " reset cursor position
  cal cursor(2,1)
endf

fun! s:GitMenuBufferToggle()
  if bufnr("GitMenu") != -1
    if bufnr('.') != bufnr("GitMenu")
      let wnr = bufwinnr( bufnr("GitMenu") )
      if wnr != -1
        exe (wnr-1) . "wincmd w"
        :bw!
      else
        exec bufnr("GitMenu") . 'bw!'
      endif
    else
      :bw!
    endif
  else
    cal s:initGitMenuBuffer()
  endif
endf


com! GitCommit       :cal s:initGitCommitSingleBuffer(expand('%'))
com! GitCommitAll    :cal s:initGitCommitAllBuffer()
com! GitCommitAmend  :cal s:initGitCommitAmendBuffer()
com! GitMenuToggle   :cal s:GitMenuBufferToggle()

nmap <leader>ci  :GitCommit<CR>
nmap <leader>ca  :GitCommitAll<CR>
nmap <leader>gg  :GitMenu<CR>
