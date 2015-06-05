" define GitStatus command.
" vim:fdm=marker:
fun! s:GitBranchListRefresh()
  setlocal modifiable
  1,$delete _
  let list = system('git branch')
  put=list
  normal ggdd
  setlocal nomodifiable
endf

fun! s:getSelectedBranchName()
  let br = substitute( getline('.') , '^\*\?\s*' , '' , 'g')
  return br
endf


fun! GitListRemote(A,L,P)
  return system('git remote')
endf

fun! s:promptRemote()
  cal inputsave()
  let remote = input('Remote:','','custom,GitListRemote')
  cal inputrestore()
  return remote
endf
" echo s:promptRemote()

fun! s:getRemoteName()
  let remotes =  split(GitListRemote('','',''))
  if len( remotes ) == 1
    return remotes[0]
  else
    return s:promptRemote()
  endif
endf
" echo s:getRemoteName()

fun! s:branchPull()
  let br = s:getSelectedBranchName()
  let remote = s:getRemoteName()
  exec printf('!git pull %s %s',remote,br)
endf

fun! s:branchPush()
  let br = s:getSelectedBranchName()
  let remote = s:getRemoteName()
  exec printf('!git push %s %s',remote,br)
endf

fun! s:branchDelete(force)
  let br = s:getSelectedBranchName()
  if a:force
    exec '!git branch -D ' . br
  else
    exec '!git branch -d ' . br
  endif
endf

fun! s:branchCheckout()
  let br = s:getSelectedBranchName()
  exec '!git checkout ' . br
endf

fun! s:GitBranchList()
  tabnew
  setlocal noswapfile  
  setlocal nobuflisted nowrap cursorline nonumber fdc=0 buftype=nofile bufhidden=wipe
  let branch = system('git branch -a | grep -v HEAD')
  put=branch
  normal ggdd
  setfiletype git-branch
  silent file GitBranch
"   nmap <script><buffer> L  :cal <SID>diffFileFromStatusLine()<CR>
  nnoremap <script><buffer> C     :cal <SID>branchCheckout()<CR>
  nnoremap <script><buffer> D     :cal <SID>branchDelete(0)<CR>
  nnoremap <script><buffer> <C-D> :cal <SID>branchDelete(1)<CR>
  nnoremap <script><buffer> L     :cal <SID>branchPull()<CR>
  nnoremap <script><buffer> P     :cal <SID>branchPush()<CR>
"   nmap <script><buffer> E  :cal <SID>splitFileFromStatusLine()<CR>
"   nmap <script><buffer> T  :cal <SID>tabeFileFromStatusLine()<CR>
"   nmap <script><buffer> R  :cal <SID>resetFileFromStatusLine()<CR>

  syn match Comment +^#.*+ 
  syn match CurrentBranch +^\*.*+
  hi link CurrentBranch Function
  cal g:Help.reg("Git Branch",
    \" P - Push\n" .
    \" L - Pull\n" .
    \" D - Delete\n" .
    \" R - Rename\n" .
    \" C - Checkout\n" 
    \,1)
  setlocal nomodifiable
endf
com! GitBranch :cal s:GitBranchList()
nmap <leader>gb  :GitBranch<CR>
