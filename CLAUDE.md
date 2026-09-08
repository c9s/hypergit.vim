# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`hypergit.vim` — a Vimscript plugin (vim >= 7.2) that wraps git in buffer-based UIs: a tree menu, a commit buffer, status/branch/stash/log managers, and a `git rebase -i` helper. Pure Vimscript, ~1.4k lines, no tests and no build step.

## Development workflow

There is no test suite or linter. Changes are verified by loading the plugin in vim and exercising the commands.

- The repo lives under `~/.vim/plugged/hypergit.vim` (vim-plug), which is the same directory as `~/dotfiles/_vim/plugged/hypergit.vim` — editing here is already live; just restart vim or `:source` the changed file.
- `make link` / `make install` (the generic Vimana-era Makefile) copy or symlink files into `$VIMRUNTIME` (`~/.vim`). Not needed in the vim-plug layout above. `make bundle-deps` vendors the two hard dependencies into `plugin/`.
- Do not edit `Makefile` — it is generated from a `Makefile.tpl` that isn't in this repo. Project settings live in `config.mk`.

### Runtime dependencies

`c9s/helper.vim` (provides `g:Help`) and `c9s/treemenu.vim` (provides `g:MenuBuffer` / `g:MenuItem`) must load *before* hypergit. Menu, commit, status, branch and stash buffers all call into them.

## Architecture

Load order matters and is the main organizing principle:

- `plugin/` — loads first: shared helpers (`FindDotGit`, `g:GitSkipCommit`), the completion functions (`Git*Completion`), and the commit-buffer and branch/push commands.
- `after/plugin/hypergit.vim` — loads last; sets every `g:`-option default via `s:defopt` (`g:GitBin`, `g:HyperGitUntrackMode`, `g:HyperGitBufferHeight/Width`, `g:GitBufferDefaultPosition`, …), defines the `GitCurrentBranch` / `GitDefaultRemoteName` API used across the plugin, and installs the default `<leader>` mappings and `cabbr`s. Because options are defined here, anything in `plugin/` may only *reference* them at call time, never at source time.
- `after/plugin/*.vim` — one feature per file (`menu`, `status`, `log`, `pull`, `stash`, `rebase`, `remote`, `add`, `rm`), each defining its `:Git*` command(s) plus buffer-local `nnoremap`s.
- `autoload/hypergit/` — the reusable core: `buffer.vim` (scratch-window creation, `next_name` for unique buffer names), `shell.vim` (`run()` — uses `:terminal` when available, otherwise a nofile buffer with `system()` output), `commit.vim` (commit-message rendering).
- `syntax/` — `git-status`, `git-log`, `git-diff` filetypes set by the manager buffers.

### Conventions to follow

- Every UI is a throwaway scratch buffer: `noswapfile nobuflisted buftype=nofile nomodifiable`, created through `hypergit#buffer#init()` / `#bottomright()`. Toggling/refresh is done by re-rendering the whole buffer, not patching lines.
- Feature files keep functions script-local (`s:`) and bind them with `nnoremap <script><buffer> … <SID>fn()`. Only things shared across files (the git API, completions, `GitCommit*Buffer`) are global.
- Git is invoked as a string through `g:GitBin` with `system()` or `hypergit#shell#run()`; output is parsed with `matchstr`/regex against the porcelain text.

### The commit flow (the least obvious part)

`GitCommitSingleFileBuffer` / `GitCommitAllBuffer` / `…AmendBuffer` open a buffer on a `tempname()` file, mark it with a buffer-local flag (`b:commit_target`, `b:commit_stashed`, `b:commit_amend`), and render the message body via `hypergit#commit#render*`. The actual commit fires from an `autocmd BufUnload` → `g:GitCommit()`, which picks the `git commit` variant from those flags — so *closing the buffer commits*; `s` (`g:GitSkipCommit`) deletes the temp file to abort.

Before committing, `s:filterCommitMessage()` scans the message for `!A <file>` / `!D <file>` action lines and runs `git add` / `git rm` on them. Note those two lines call the undefined `g:GitCommand` rather than `g:GitBin` — a latent bug; use `g:GitBin` if you touch them.

`hypergit#commit#render()` prefills a commit-message prefix by taking the common leading path components of the changed files (`git status --short`), stripping a leading `pkg/`, and appending `": "` — the `pkg/` stripping is Go-layout-specific and lives in both `render()` and `render_single()`.
