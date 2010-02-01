" vim:fdm=marker:fdl=0:
" Author: Cornelius <cornelius.howl@gmail.com>
" Class:  MenuBuffer
" Version:    0.1
" Description: 
"         for you to create a tree menu in buffer easily 
"          (especially in terminal)

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
  syn match MenuLabelExecutable +\(^[-]-*\)\@<=[a-zA-Z0-9-()._/ ]*+
  syn match MenuLabelExpanded   +\(^[~]-*\)\@<=[a-zA-Z0-9-()._/ ]*+
  syn match MenuLabelCollapsed  +\(^[+]-*\)\@<=[a-zA-Z0-9-()._/ ]*+

  hi MenuId ctermfg=black ctermbg=black
  hi MenuPre ctermfg=darkblue

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

" =========== synopsis
let p1 = s:MenuItem.create( { 'label': 'Father' }  )
let p2 = s:MenuItem.create( { 'label': 'Father2' } )

let s1 = s:MenuItem.create( { 'label': 'Son' , 'parent': p1 } )
let s1_1 = s1.createChild({ 'label': 'SonFromSon' } )
let s1_2 = s1.createChild({ 'label': 'SonFromSon2' } )

let p2_1 = p2.createChild({ 'label': 'Father2/Son' } )

cal p1.expand()
cal p1.expandR()

vnew
let m = s:MenuBuffer.create({ 'buf_nr': bufnr('.') })
cal m.addItems([p1, p2])
cal m.render()
