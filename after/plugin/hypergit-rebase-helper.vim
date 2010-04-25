
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
  vnew
  setlocal noswapfile  
  setlocal nobuflisted nowrap cursorline nonumber fdc=0
  setlocal buftype=nofile 
  setlocal bufhidden=wipe
  "let output = system(printf('git show -p %s', hash ))
  let output = system(printf('git log -p %s^1..%s', hash,hash ))
  silent put=output
  silent normal ggdd
  setlocal nomodifiable
  setfiletype git
  nmap <silent><buffer> L <C-w>q
endf
fun! s:RebaseAction(name)
  exec 's/^\w\+/'.a:name.'/'
endf
fun! s:initGitRebase()
  nmap <script><silent><buffer> L :cal <SID>RebaseLog()<CR>
  nmap <script><silent><buffer> p :cal <SID>RebaseAction('pick')<CR>
  nmap <script><silent><buffer> s :cal <SID>RebaseAction('squash')<CR>
  nmap <script><silent><buffer> e :cal <SID>RebaseAction('edit')<CR>
  nmap <script><silent><buffer> r :cal <SID>RebaseAction('reword')<CR>
  nmap <script><silent><buffer> ? :cal <SID>showHelp()<CR>
  nmap <script><silent><buffer> D dd
endf
fun! s:showHelp()
  redraw
  echo " Git rebase helper:"
  echo "   L   - view commit log"
  echo "   p   - pick"
  echo "   e   - edit"
  echo "   s   - squash"
  echo "   r   - reword"
  echo "   D   - delete"
endf
aug GitRebase
  au!
  autocmd filetype gitrebase :cal s:initGitRebase()
aug END
" }}}
