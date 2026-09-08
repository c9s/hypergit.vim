
" vim:fdm=marker:

fun! FindDotGit()
  let path = getcwd()
  let parts = split(path,'/')
  let paths = []
  for i in range(1,len(parts))
    cal add(paths,  '/'.join(parts,'/'))
    cal remove(parts,-1)
  endfor
  for p in paths 
    " a linked worktree or a submodule has a .git *file* pointing at the repo
    if isdirectory(p . '/.git') || filereadable(p . '/.git')
      return p
    endif
  endfor
  return ""
endf






fun! g:GitSkipCommit()
  let file = expand('%')
  cal delete(file)
  bw!
endf

