" vim:fdm=marker:
" Git rebase helper {{{
"   git rebase --interactive
"
"   L   - view commit log
"   p   - pick
"   e   - edit
"   s   - squash
"   r   - reword
"   D   - delete
"
"       Cornelius <cornelius.howl@gmail.com>
fun! s:RebaseLog()
  let line = getline('.')
  let hash = matchstr(line,'\(^\w\+\s\)\@<=\w*')
  botright vnew
  setlocal noswapfile
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  "let output = system(printf('git show -p %s', hash ))
  let output = system(printf('git log -p %s^1..%s', hash,hash ))
  silent 0,$delete
  silent put=output
  setlocal nomodifiable
  setfiletype git
  nmap <silent><buffer> q <C-w>q
  nmap <silent><buffer> Q <C-w>q
endf

fun! s:RebaseAction(name)
  exec 's/^\w\+/'.a:name.'/'
endf

fun! s:initGitRebase()
  nnoremap <script><silent><buffer> L :cal <SID>RebaseLog()<CR>
  nnoremap <script><silent><buffer> p :cal <SID>RebaseAction('pick')<CR>
  nnoremap <script><silent><buffer> f :cal <SID>RebaseAction('fixup')<CR>
  nnoremap <script><silent><buffer> s :cal <SID>RebaseAction('squash')<CR>
  nnoremap <script><silent><buffer> e :cal <SID>RebaseAction('edit')<CR>
  nnoremap <script><silent><buffer> r :cal <SID>RebaseAction('reword')<CR>
  nnoremap <script><silent><buffer> ? :cal <SID>showHelp()<CR>
  nnoremap <script><silent><buffer> D dd
  setlocal cursorline
endf
fun! s:showHelp()
  redraw
  echo " Git rebase helper:"
  echo "   L   - view commit log"
  echo "   p   - pick"
  echo "   e   - edit"
  echo "   s   - squash"
  echo "   r   - reword"
  echo "   f   - fixup"
  echo "   D   - delete"
endf
aug GitRebase
  au!
  autocmd filetype gitrebase :cal s:initGitRebase()
aug END
" }}}
