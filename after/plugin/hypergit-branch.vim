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

fun! s:branchDelete()
  let br = substitute( getline('.') , '^\*\?\s*' , '' , 'g')
  exec '!git branch -d ' . br
endf

fun! s:branchCheckout()
  let br = substitute( getline('.') , '^\*\?\s*' , '' , 'g')
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
  nmap <script><buffer> C  :cal <SID>branchCheckout()<CR>
  nmap <script><buffer> D  :cal <SID>branchDelete()<CR>
"   nmap <script><buffer> E  :cal <SID>splitFileFromStatusLine()<CR>
"   nmap <script><buffer> T  :cal <SID>tabeFileFromStatusLine()<CR>
"   nmap <script><buffer> R  :cal <SID>resetFileFromStatusLine()<CR>

  syn match Comment +^#.*+ 
  syn match CurrentBranch +^\*.*+
  hi link CurrentBranch Function
  cal g:Help.reg("Git Branch",
    \" D - Delete\n" .
    \" R - Rename\n" .
    \" C - Checkout\n" 
    \,1)
  setlocal nomodifiable
endf
com! GitBranch :cal s:GitBranchList()
nmap <leader>gb  :GitBranch<CR>
