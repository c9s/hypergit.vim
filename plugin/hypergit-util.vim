
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
    if isdirectory(p . '/.git')
      return p
    endif
  endfor
  return ""
endf




fun! s:filterMessage(msgfile)
  if ! filereadable(a:msgfile)
    return
  endif
  let lines = readfile(a:msgfile)
  let idx = 0
  for l in lines
    if l =~ '^\!A\s\+'
      let file = s:trim_message_op(l)
      cal system( g:GitCommand . ' add ' . file )
      echohl GitMsg | echo file . ' added' | echohl None
      let lines[ idx ] = ''
    elseif l =~ '^\!D\s\+'
      let file = s:trim_message_op(l)
      cal system( g:GitCommand . ' rm ' . file )   " XXX: detect failure
      echohl GitMsg | echo file . ' deleted' | echohl None
      let lines[ idx ] = ''
    endif
    let idx += 1
  endfor
  cal writefile(lines,a:msgfile)
endf


fun! g:GitSkipCommit()
  let file = expand('%')
  cal delete(file)
  bw!
endf

fun! g:GitDoCommit()
  let file = expand('%')
  if ! filereadable(file) 
    echo "Skipped"
    return
  endif
  cal s:filterMessage(file)

  echohl GitMsg 
  echo "Committing..."
  if exists('b:commit_target')
    echo "Target: " . b:commit_target
    let cmd = printf('%s commit --cleanup=strip -F %s %s', g:GitBin , file, b:commit_target )
    if g:HyperGitBackgroundCommit
      cal system(cmd)
    else
      echo system(cmd)
    endif
  elseif exists('b:commit_amend')
    echo system('%s commit --cleanup=strip --amend -F %s' , g:GitBin , file )
  else
    let cmd = printf('%s commit --cleanup=strip -a -F %s', g:GitBin , file )
    if g:HyperGitBackgroundCommit
      cal system(cmd)
    else
      echo system(cmd)
    endif
  endif
  echo "Done"
  echohl None
endf
