
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
  let menu = copy(self)
  cal extend(menu,a:options)
  cal menu.init()
  return menu
endf

fun! s:MenuBuffer.init()
  let win = self.findWindow(1)
  setfiletype MenuBuffer
  setlocal buftype=nofile bufhidden=hide
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
    exec win . 'wincmd w'
  endif
  return win
endf

fun! s:MenuBuffer.toggleCurrent()
  let id = self.getCurrentMenuId()
  let item = self.findItem(id)
  if type(item) == 4
    cal item.toggle()
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
  0put=outstr
  cal setpos('.',cur)
endf

fun! s:MenuBuffer.getCurrentLevel()
  let line = getline('.')
  let idx = stridx(line,'[')
  return idx - 1
endf

fun! s:MenuBuffer.getCurrentMenuId()
  let id = matchstr(getline('.'),'\([~+|-]\+\[\)\@<=\d\+')
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

let s:MenuItem = {'id':0, 'expanded':0 }

" Factory method
fun! s:MenuItem.create(options)
  let self.id += 1
  let item = copy(self)
  cal extend(item,a:options)
  if has_key(item,'parent')
    if has_key(item.parent,'childs')
      cal add(item.parent.childs,item)
    else
      let item.parent.childs = [ ]
      cal add(item.parent.childs,item)
    endif
  endif
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
    return op . indent . '[' . self.id . '] ' . self.label
  elseif has_key(self,'parent')
    let indent = repeat('-', lev)
    return '|' . indent . '[' . self.id . '] ' . self.label
  else
    let indent = repeat('-', lev)
    return '|' . indent . '[' . self.id . '] ' . self.label
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

fun! s:MenuItem.render( )
  let printlines = [ self.displayString()  ]
  if has_key(self,'childs') && self.expanded 
    for ch in self.childs 
      cal add( printlines, ch.render() )
    endfor
  endif
  return join(printlines,"\n")
endf

" =========== synopsis

let p1 = s:MenuItem.create( { 'label': 'Father' }  )
let p2 = s:MenuItem.create( { 'label': 'Father2' } )

let s1 = s:MenuItem.create( { 'label': 'Son' , 'parent': p1 } )
let s1_1 = s1.createChild({ 'label': 'SonFromSon' } )
let s1_2 = s1.createChild({ 'label': 'SonFromSon2' } )


let p2_1 = p2.createChild({ 'label': 'Father2/Son' } )

"echo p1.label
"echo s1.label

"echo p1
"echo s1
"echo s1.getLevel(0)
"echo p1.displayString()
"echo s1.displayString()

cal p1.expand()
"cal p1.expandR()
"cal p2.expandR()
"echo p1.render()
"echo p2.render()

vnew
let m = s:MenuBuffer.create({ 'buf_nr': bufnr('.') })
cal m.addItems([p1, p2])

cal m.render()
"echo m.findItem(3)

com! ToggleNode  :cal s:MenuBuffer.toggleCurrent()
nmap <buffer> o :ToggleNode<CR>
