" vim: set sw=2 ts=2 sts=2 foldmethod=marker:

call plug#begin()

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'

Plug 'webdevel/tabulous'
Plug 'catppuccin/nvim', { 'as': 'catppuccin' }

Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'sshklifov/debug'

call plug#end()

packadd cfilter

""""""""""""""""""""""""""""Plugin settings"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Tabulous
let tabulousLabelLeftStr = ' ['
let tabulousLabelRightStr = '] '
let tabulousLabelNumberStr = ':'
let tabulousLabelNameDefault = 'Empty'
let tabulousCloseStr = ''

" Netrw
let g:netrw_hide = 1
let g:netrw_banner = 0

" sshklifov/debug
let g:termdebug_capture_msgs = 1

" tpope/vim-eunuch
function! Move(arg)
  if a:arg == ""
    echo "Did not move file"
    return
  endif

  let oldname = expand("%:p")
  let newname = a:arg . "/" . expand("%:t")
  
  let lua_str = 'lua vim.lsp.util.rename("' . oldname . '", "' . newname . '")'
  exe lua_str
endfunction

command! -nargs=1 -complete=dir Move call Move(<q-args>)

function! Rename(arg)
  if a:arg == ""
    echo "Did not rename file"
    return
  endif

  let oldname = expand("%:p")
  if stridx(a:arg, "/") < 0
    let dirname = expand("%:p:h")
    let newname = dirname . "/" . a:arg
  else
    let newname = a:arg
  endif

  let lua_str = 'lua vim.lsp.util.rename("' . oldname . '", "' . newname . '")'
  exe lua_str
endfunction

command! -nargs=1 -complete=file Rename call Rename(<q-args>)

function! Delete(bang)
  try
    let file = expand("%:p")
    exe "bw" . a:bang
    call delete(file)
  catch
    echoerr "No write since last change. Add ! to override."
  endtry
endfunction

command! -nargs=0 -bang Delete call Delete('<bang>')

" tpope/vim-commentary
autocmd BufEnter,BufNew *.fish setlocal commentstring=#\ %s
autocmd FileType vim setlocal commentstring=\"\ %s
autocmd FileType cpp setlocal commentstring=\/\/\ %s

" tpope/vim-fugitive
set diffopt-=horizontal
set diffopt+=vertical
"}}}

""""""""""""""""""""""""""""Everything else"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cabbr Gd lefta Gdiffsplit
cabbr Gl Gclog!
cabbr Gb Git blame
cabbr Gdt Git! difftool
cabbr Gmt Git mergetool

" Git commit style settings
autocmd FileType gitcommit set spell
autocmd FileType gitcommit set tw=90

" Capture <Esc> in termal mode
tnoremap <Esc> <C-\><C-n>

" Indentation settings
set expandtab
set shiftwidth=4
set tabstop=4
set softtabstop=0
set cinoptions=L0,l1,b1,g0,t0,(s,U1,

" Display line numbers
set number
set relativenumber
set cc=101

" Smart searching with '/'
set ignorecase
set smartcase
set hlsearch
nnoremap <silent> <Space> :nohlsearch <bar> LspCxxHighlight<cr>

" Typos
command! -bang Q q<bang>
command! -bang W w<bang>
command! -bang Qa qa<bang>

" Annoying quirks
set sessionoptions-=blank
set shortmess+=I
au FileType * setlocal fo-=cro
nnoremap <C-w>t <C-w>T
let mapleader = "\\"
autocmd SwapExists * let v:swapchoice = "e"

" Command completion
set wildchar=9
set wildcharm=9
set wildignore=*.o,*.out
set wildignorecase
set wildmode=full
cnoremap <expr> <Up> pumvisible() ? "\<C-p>" : "\<Up>"
cnoremap <expr> <Down> pumvisible() ? "\<C-n>" : "\<Down>"
cnoremap <expr> <Right> pumvisible() ? "\<Down>" : "\<Right>"

set scrolloff=4
set noautoread
set splitright
set nottimeout
set notimeout
set foldmethod=manual
set shell=/bin/bash

" Display better the currently selected entry in quickfix
autocmd FileType qf setlocal cursorline
" }}}

""""""""""""""""""""""""""""Quickfix"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:findExcludePaths = {}

function! s:GetExcludePaths(dir)
  for [key, value] in items(g:findExcludePaths)
    if stridx(a:dir, key) >= 0
      return value
    endif
  endfor
  " Default result
  return ["ccls-cache", ".git", "Debug", "Release", ".ccls"]
endfunction

function! s:OldFiles(read_shada)
  if a:read_shada
    rsh!
  endif

  let items = deepcopy(v:oldfiles)
  let items = map(items, {_, f -> {"filename": f, "lnum": 1, 'text': fnamemodify(f, ":t")}})
  call setqflist([], ' ', {'title': 'Oldfiles', 'items': items})
  copen
endfunction

command -nargs=0 -bang Old call s:OldFiles(<bang>0)

function! s:Grep(regex, ...)
  call setqflist([], ' ', {'title' : 'Grep', 'items' : []})

  function! OnEvent(id, data, event)
    let matches = filter(a:data, {i, d -> !empty(d)})
    function! s:GetGrepItem(index, match)
      let sp = split(a:match, ":")
      if len(sp) < 3
        return {}
      endif
      if !filereadable(sp[0])
        return {}
      endif
      " Apply filter. Bang means to force more results and not take into accound exclude paths.
      if exists('s:grep_exclude_paths') && s:bang != "!"
        for exclude_path in s:grep_exclude_paths
          if stridx(sp[0], exclude_path) >= 0
            return {}
          endif
        endfor
      endif
      if !(sp[1] =~ '^[0-9]\+$')
        return {}
      endif
      return {"filename": sp[0], "lnum": sp[1], 'text': join(sp[2:-1], ":")}
    endfunction
    let items = filter(map(matches, function("<SID>GetGrepItem")), {_, o -> !empty(o)})
    call setqflist([], 'a', {'items' : items})
  endfunction

  let cmd = ['grep']
  " Apply 'smartcase' to the regex
  if a:regex !~# "[A-Z]"
    let cmd = cmd + ['-i']
  endif
  let cmd = cmd + ['-I', '-H', '-n', a:regex]

  let what = get(a:, 1, getcwd())
  if type(what) == v:t_string && isdirectory(what)
    let cmd = cmd + ['-R', what]
    let s:grep_exclude_paths = s:GetExcludePaths(what)
    let s:bang = get(a:, 2, "")
    let id = jobstart(cmd, {'on_stdout': function('OnEvent') } )
  else
    let cmd = ['xargs'] + cmd
    let id = jobstart(cmd, {'on_stdout': function('OnEvent') } )
    call chansend(id, what)
  endif

  call chanclose(id, 'stdin')
  call jobwait([id]) " Need to know length of items
  if exists("s:grep_exclude_paths")
    unlet s:grep_exclude_paths
  endif
  if exists("s:bang")
    unlet s:bang
  endif

  let n = len(getqflist())
  if n == 0
    echo "No results"
  else
    copen
  endif
endfunction

function! s:GrepQuickfixFiles(regex)
  let files = map(getqflist(), {_, e -> expand("#" . e["bufnr"] . ":p")})
  let files = uniq(sort(files))
  call <SID>Grep(a:regex, files)
endfunction

" Current buffer
command! -nargs=1 -bang Bgrep call <SID>Grep(<q-args>, [expand("%:p")])
" All files in quickfix
command! -nargs=1 -bang Cgrep call <SID>GrepQuickfixFiles(<q-args>)
" Current path
command! -nargs=1 -bang Rgrep call <SID>Grep(<q-args>, getcwd(), "<bang>")

function! s:DeleteQfEntries(a, b)
  let qflist = filter(getqflist(), {i, _ -> i+1 < a:a || i+1 > a:b})
  call setqflist([], ' ', {'title': 'Cdelete', 'items': qflist})
endfunction

autocmd FileType qf command! -buffer -range Cdelete call <SID>DeleteQfEntries(<line1>, <line2>)

function! s:OpenJumpList()
  let jl = deepcopy(getjumplist())
  let entries = jl[0]
  let idx = jl[1]

  for i in range(len(entries))
    if !bufloaded(entries[i]['bufnr'])
      let entries[i] = #{text: "Not loaded"}
    else
      let lines = getbufline(entries[i]['bufnr'], entries[i]['lnum'])
      if len(lines) > 0
        let entries[i]['text'] = lines[0]
      endif
    endif
  endfor

  call setqflist([], 'r', {'title': 'Jump', 'items': entries})
  " Open quickfix at the relevant position
  if idx < len(entries)
    exe "keepjumps crewind " . (idx + 1)
  endif
  " Keep the same window focused
  let nr = winnr()
  keepjumps copen
  exec "keepjumps " . nr . "wincmd w"
endfunction

function! s:Jump(scope)
  if s:IsBufferQf()
    return
  endif

  " Pass 1 to normal so vim doesn't interpret ^i as a TAB (they use the same keycode of 9)
  if a:scope == "i"
    exe "normal! 1" . "\<c-i>"
  elseif a:scope == "o"
    exe "normal! 1" . "\<c-o>"
  endif

  " Refresh jump list
  if s:IsQfOpen()
    let title = getqflist({'title': 1})['title']
    if title == "Jump"
      call s:OpenJumpList()
    endif
  endif
endfunction

nnoremap <silent> <leader>ju :call <SID>OpenJumpList()<CR>
nnoremap <silent> <c-i> :call <SID>Jump("i")<CR>
nnoremap <silent> <c-o> :call <SID>Jump("o")<CR>

function! s:ShowBuffers()
  let nrs = filter(range(1, bufnr('$')), {_, n -> buflisted(n) && filereadable(bufname(n))})

  function! s:GetBufferItem(_, n)
    let bufinfo = getbufinfo(a:n)[0]
    let text = "" . a:n
    if bufinfo["changed"]
      let text = text . " (modified)"
    endif
    return {"bufnr": a:n, "text": text, "lnum": bufinfo["lnum"]}
  endfunction

  let items = map(nrs, function("s:GetBufferItem"))
  call setqflist([], 'r', {'title' : 'Buffers', 'items' : items})
  copen
endfunction

nnoremap <silent> <leader>buf :call <SID>ShowBuffers()<CR>

command! -nargs=1 -bar Buffer call <SID>ShowBuffers() | Cfilter <q-args>

function! s:SwitchCompl(A, L, P)
  let pat = ".*" . a:A . ".*"
  let case = pat =~# "[A-Z]"
  function! BufferFilter(_, n) closure
    if !buflisted(a:n) || !bufloaded(a:n) || len(win_findbuf(a:n)) <= 0
      return 0
    endif
    let name = bufname(a:n)
    if !filereadable(name)
      return 0
    endif
    if (case && name !~# pat) || (!case && name !~? pat)
      return 0
    endif
    return 1
  endfunction

  let nrs = filter(range(1, bufnr('$')), function("BufferFilter"))
  let names = map(nrs, {_, n -> bufname(n)})
  return names
endfunction

function! s:Switch(qargs)
  let winids = win_findbuf(bufnr(a:qargs))
  call win_gotoid(winids[0])
  endif
endfunction

command! -nargs=1 -complete=customlist,<SID>SwitchCompl Switch call <SID>Switch(<q-args>)

function! s:IsBufferQf()
  let tabnr = tabpagenr()
  let bufnr = bufnr()
  let wins = filter(getwininfo(), {_, w -> w['tabnr'] == tabnr && w['quickfix'] == 1 && w['bufnr'] == bufnr})
  return !empty(wins)
endfunction

function! s:IsQfOpen()
  let tabnr = tabpagenr()
  let wins = filter(getwininfo(), {_, w -> w['tabnr'] == tabnr && w['quickfix'] == 1 && w['loclist'] == 0})
  return !empty(wins)
endfunction

function! s:ToggleQf()
  if <SID>IsQfOpen()
    cclose
  else
    copen
  endif
endfunction

nnoremap <silent> <leader>cc :call <SID>ToggleQf()<CR>
" }}}

""""""""""""""""""""""""""""Appearance"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
colorscheme catppuccin-frappe
highlight Structure guifg=#e78284
highlight debugBreakpoint guifg=#303446 guibg=#e78284
highlight debugBreakpointDisabled guifg=#303446 guibg=#949cbb

set termguicolors
hi! link qfFileName Comment
hi! link netrwDir Comment
set fillchars+=vert:\|

" Show indentation
set list
set list lcs=tab:\|\ 

function! GetFileStatusLine()
  " Kind of resticts maximum returned length
  const maxwidth = 80

  " Return basename for help files
  if &ft == "help"
    return expand("%:t")
  endif
  " Empty file -> Empty string
  let filename = bufname()
  if empty(filename)
    return ""
  endif
  " No file on disk -> Display buffer only
  if !filereadable(filename)
    return filename
  endif

  let filename = expand("%:p")
  let cwd = getcwd()
  let mixedStatus = (filename[0:len(cwd)-1] == cwd)

  " Dir is not substring of file -> Display file only
  if !mixedStatus
    return s:PathShorten(filename, maxwidth)
  endif

  " Display mixed status
  let filename = filename[len(cwd)+1:]
  const sep = "> "
  return s:PathShorten(cwd . sep . filename, maxwidth)
endfunction

function! s:PathShorten(file, maxwidth)
  if empty(a:file)
    return "[No name]"
  endif
  if len(a:file) < a:maxwidth
    return a:file
  endif
  " Truncate from the left. truncPart will be substituted in place of excess symbols.
  let items = reverse(split(a:file, "/"))
  let accum = items[0]
  for item in items[1:]
    let tmp = item . "/" . accum
    if len(tmp) > a:maxwidth
      return "(..)/" . accum
    endif
    let accum = tmp
  endfor
  if a:file[0] == '/'
    return '/' . accum
  else
    return accum
  endif
endfunction

function! GetLspStatusLine()
  let serverResponses = luaeval('vim.lsp.util.get_progress_messages()')
  if empty(serverResponses)
    return ""
  endif

  function! GetServerProgress(_, status)
    if !has_key(a:status, 'message')
      return [0, 0]
    endif
    let msg = a:status['message']
    let partFiles = split(msg, "/")
    if len(partFiles) != 2
      return [0, 0]
    endif
    return [str2nr(partFiles[0]), str2nr(partFiles[1])]
  endfunction

  let serverProgress = map(serverResponses, function("GetServerProgress"))

  let totalFiles = 0
  let totalDone = 0
  for progress in serverProgress
    let totalDone += progress[0]
    let totalFiles += progress[1]
  endfor

  if totalFiles == 0
    return ""
  endif

  let percentage = (100 * totalDone) / totalFiles
  return percentage . "%"
endfunction

function! BranchStatusLine()
  let res = FugitiveStatusline()
  if empty(res)
    return res
  endif
  let res = substitute(res, "\\[Git(", "", "")
  let res = substitute(res, ")\\]", "", "")
  return res . ">"
endfunction

set statusline=
set statusline+=%(%{BranchStatusLine()}\ %)
set statusline+=%(%{GetFileStatusLine()}\ %{GetLspStatusLine()}%m%h%r%)
set statusline+=%=
set statusline+=%(%l,%c\ %10.p%%%)

function! s:SynStack()
  if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

command! -nargs=0 CursorSym call <SID>SynStack()
" }}}

""""""""""""""""""""""""""""IDE maps"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

nnoremap <leader><leader>q :mksession! ~/.local/share/nvim/session.vim<CR>
nnoremap <leader>so :so ~/.local/share/nvim/session.vim<CR>
set sessionoptions-=blank

nnoremap <silent> <leader>cd :lcd %:p:h<CR>

nnoremap <silent> <leader>ta :tabnew<CR><C-O>
nnoremap <silent> <leader>tc :tabclose<CR>

nnoremap <silent> <leader>unix :set ff=unix<CR>
nnoremap <silent> <leader>dos :set ff=dos<CR>

" copy-pasting
nnoremap <leader>y "+y
nnoremap <leader>Y "+Y
xnoremap <leader>y "+y
xnoremap <leader>Y "+Y
nnoremap <silent> <leader>p :set
      \ paste <Bar> exe 'silent! normal! "+p' <Bar> set nopaste<CR>
nnoremap <silent> <leader>P :set
      \ paste <Bar> exe 'silent! normal! "+P' <Bar> set nopaste<CR>
xnoremap <silent> <leader>p :<C-W>set
      \ paste <Bar> exe 'silent! normal! gv"+p' <Bar> set nopaste<CR>
xnoremap <silent> <leader>P :<C-W>set
      \ paste <Bar> exe 'silent! normal! gv"+P' <Bar> set nopaste<CR>

command! -bar Retab set invexpandtab | retab!
command! -bar Fixtab Retab | Retab

function! s:ToggleDiff()
  let fugitive_winids = []
  let diff_winids = []

  let winids = gettabinfo(tabpagenr())[0]["windows"]
  for winid in winids
    let winnr = win_id2tabwin(winid)[1]
    let bufnr = winbufnr(winnr)
    let name = bufname(bufnr)
    if win_execute(winid, "echon &diff") == "1"
      if name =~ "^fugitive:///"
        let fugitive_winids += [winid]
      else
        let diff_winids += [winid]
      endif
    endif
  endfor

  if len(diff_winids) == 0
    " No window in diff mode, toggle should open diff
    if exists("b:commitish") && b:commitish != "0"
      exe "lefta Gdiffsplit " . b:commitish
    else
      lefta Gdiffsplit
    endif
  else
    if len(fugitive_winids) > 0
      for winid in fugitive_winids
        let winnr = win_id2tabwin(winid)[1]
        let bufnr = winbufnr(winnr)
        let name = bufname(bufnr)

        let commitish = split(FugitiveParse(name)[0], ":")[0]
        let realnr = bufnr(FugitiveReal(name))

        " Memorize the last diff commitish for the buffer
        call win_gotoid(winid)
        exe "b " . realnr
        let b:commitish = commitish
        " Close fugitive window
        quit
      endfor
    else
      for winid in diff_winids
        call win_execute(winid, "diffoff")
      endfor
    endif
  endif

endfunction

nnoremap <silent> <leader>dif :call <SID>ToggleDiff()<CR>

set updatetime=500
set completeopt=menuone
inoremap <silent> <C-Space> <C-X><C-O>


" http://vim.wikia.com/wiki/Automatically_append_closing_characters
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:GoToNextItem(dir)
  if &foldmethod == "diff"
    if a:dir == "prev"
      exe "normal! [c"
    elseif a:dir == "next"
      exe "normal! ]c"
    endif
    return
  endif

  let listProps = getqflist({"size": 1, "idx": 0})
  let cmd = "c" . a:dir
  let size = listProps["size"]
  let idx = listProps["idx"]
  if size == 0
    return
  endif

  if (a:dir == "next" && idx < size) ||
        \ (a:dir == "prev" && idx > 1) ||
        \ (a:dir == "first" || a:dir == "last")
    copen
    exe cmd
  endif
endfunction

nnoremap <silent> [c :call <SID>GoToNextItem("prev")<CR>
nnoremap <silent> ]c :call <SID>GoToNextItem("next")<CR>
nnoremap <silent> [C :call <SID>GoToNextItem("first")<CR>
nnoremap <silent> ]C :call <SID>GoToNextItem("last")<CR>

" Navigate blocks
nnoremap [b [{
nnoremap ]b ]}

" Navigate folds
nnoremap [z zo[z
nnoremap ]z zo]z

function! s:OpenSource()
  let extensions = ["cpp", "c", "cc"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      exe "edit " . file
      return
    endif

    let file = substitute(file, "include", "src", "")
    if filereadable(file)
      exe "edit " . file
      return
    endif
  endfor

  "Default to using FindInWorkspace
  let nobang = ""
  call <SID>FindInWorkspace(nobang, expand("%:t:r") . ".c")
endfunction

function! s:OpenHeader()
  let extensions = ["h", "hpp", "hh"]
  for ext in extensions
    let file = expand("%:r") . ext
    if filereadable(file)
      exe "edit " . file
      return
    endif

    let file = substitute(file, "src", "include", "")
    if filereadable(file)
      exe "edit " . file
      return
    endif
  endfor

  "Default to using FindInWorkspace
  let nobang = ""
  call <SID>FindInWorkspace(nobang, expand("%:t:r") . ".h")
endfunction

nmap <silent> <leader>cpp :call <SID>OpenSource()<CR>
nmap <silent> <leader>hpp :call <SID>OpenHeader()<CR>

function! s:EditFugitive()
  let actual = bufname()
  let real = FugitiveReal()
  if actual != real
    let pos = getpos(".")
    exe "edit " . FugitiveReal()
    call setpos(".", pos)
  endif
endfunction

nnoremap <silent> <leader>fug :call <SID>EditFugitive()<CR>

function! s:Find(bang, dir, arglist, Cb)
  if empty(a:dir)
    return
  endif

  " Add exclude paths flags
  let flags = []
  " Bang means to force more results and not take into accound exclude paths.
  if a:bang != "!"
    for excludePath in <SID>GetExcludePaths(a:dir)
      let flags = flags + ["-path", "**/" . excludePath, "-prune", "-false", "-o"]
    endfor
  endif

  " Exclude directorties from results
  let flags = flags + ["-type", "f"]
  " Add user flags
  let flags = flags + a:arglist
  " Add actions (ignore binary files)
  let flags = flags + [
        \ "-exec", "grep", "-Iq", ".", "{}", ";",
        \ "-print"
        \ ]

  let cmd = ["find",  fnamemodify(a:dir, ':p')] + flags
  let id = jobstart(cmd, {'on_stdout': a:Cb})
  call chanclose(id, 'stdin')
  return id
endfunction

function! s:FindInQuickfix(bang, dir, ...)
  " Get the callback function
  let loc = get(a:, 1, "")
  let locSplit = split(loc, ':')
  let lnum = "1"
  if len(locSplit) > 1
    let lnum = locSplit[1]
  endif
  let col = "1"
  if len(locSplit) > 2
    let col = locSplit[2]
  endif

  function! PopulateQuickfix(lnum, col, id, data, event)
    let files = filter(a:data, {i, d -> filereadable(d)})
    if empty(files)
      return
    endif
    let n = len(getqflist()) + len(files)
    if n > 4000
      echom "Too many results, stopping..."
      call jobstop(a:id)
      return
    endif
    let items = map(files, {_, f -> {'filename': f, 'lnum': a:lnum, 'col': a:col, 'text': fnamemodify(f, ':t')} })
    call setqflist([], 'a', {'items' : items})
  endfunction

  let Cb = function('PopulateQuickfix', [lnum, col]) 


  let flags = []
  " Apply 'smartcase' to the file name
  if len(locSplit) > 0
    let fname = locSplit[0]
    let regex = ".*" . fname . ".*"
    if regex =~# "[A-Z]"
      let flags = ["-regex", regex]
    else
      let flags = ["-iregex", regex]
    endif
  endif
  let flags += get(a:, 2, [])

  " Perform find operation
  call setqflist([], ' ', {'title' : 'Find', 'items' : []})
  let id = <SID>Find(a:bang, a:dir, flags, Cb)

  call jobwait([id]) " Need to know length of items
  let n = len(getqflist())
  if n == 0
    echo "No results"
  elseif n == 1
    cc
  else
    copen
  endif
endfunction

function! s:GetWorkspace()
  let workspaces = luaeval("ListWorkspaces()")
  let currfn = expand("%:p")
  for wsp in workspaces
    if stridx(currfn, wsp) >= 0
      return wsp
    endif
  endfor

  let worktree = FugitiveWorkTree()
  if !empty(worktree)
    return worktree
  endif

  echoerr "Not in workspace"
  return ""
endfunction

function! s:FindInWorkspace(bang, loc)
  let ws = s:GetWorkspace()
  if empty(ws)
    return
  endif
  call <SID>FindInQuickfix(a:bang, ws, a:loc)
endfunction

command! -nargs=? -bang List call <SID>FindInQuickfix("<bang>", getcwd(), <q-args>, ['-maxdepth', 1])
command! -nargs=? -bang Find call <SID>FindInQuickfix("<bang>", getcwd(), <q-args>)
command! -nargs=? -bang Workspace call <SID>FindInWorkspace("<bang>", <q-args>)

command! -nargs=0 Methods lua ListFilteredSymbols('Method\\|Construct')
command! -nargs=0 Functions lua ListFilteredSymbols('Function')
command! -nargs=0 Callable lua ListFilteredSymbols('Method\\|Construct\\|Function')
command! -nargs=0 Variables lua ListFilteredSymbols('Variable\\|Field')
command! -nargs=0 Types lua ListFilteredSymbols('Class\\|Struct\\|Enum')
"}}}

""""""""""""""""""""""""""""DEBUGGING"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=1 -complete=customlist,AttachCompl Attach call s:Debug({'pname': <q-args>})
command! -nargs=1 -complete=customlist,AttachSSHCompl AttachSSH call s:DebugSSH({'pname': <q-args>})

command! -nargs=? -complete=customlist,ExeCompl -bar Debug
      \ if empty(<q-args>) |
      \   call s:Debug({"exe": "a.out"}) |
      \ else |
      \   call s:Debug({"exe": <q-args>}) |
      \ endif
command! -nargs=? -complete=customlist,ExeComplSSH -bar DebugSSH
      \ if empty(<q-args>) |
      \   call s:Debug({}) |
      \ else |
      \   call s:Debug({"exe": <q-args>}) |
      \ endif

function! AttachCompl(A, L, P)
  let item = a:A
  if empty(item)
    let item = "."
  endif
  let compl = split(system("pgrep " . item . " | xargs ps -o cmd= -p"), nr2char(10))
  " Drop the command flags
  let compl = map(compl, {_, p -> split(p, " ")[0]})
  " Some processes have () and []. Remove them from completion.
  let compl = filter(compl, {_, p -> executable(p)})
  return compl
endfunction

function! AttachSSHCompl(A, L, P)
  let scriptStr = "ps -o args | cut -d \" \"  -f 1"

  let item = a:A
  let compl = split(system("ssh -o 'ConnectTimeout 1' root@192.168.3.2 '" . scriptStr . "'"), nr2char(10))
  if v:shell_error != 0
    return []
  endif

  " Filter with completion string
  if !empty(item)
    let compl = filter(compl, {_, p -> stridx(p, item) >= 0})
  endif
  " Some processes have () and []. Remove hits with illegal characters from completion.
  let compl = filter(compl, {_, p -> p =~ '^[/A-Za-z0-9_.\-~]\+$'})
  return compl
endfunction

function! ExeCompl(A, L, P)
  let oldwildignore=&wildignore
  set wildignore=
  let oldsuffixes=&suffixes
  set suffixes=

  let item = a:A
  let dirname = fnamemodify(item, ":h")
  let basename = fnamemodify(item, ":t")
  let globStr = basename . "*"

  " Get list of completion results
  let compl = globpath(dirname, globStr, 1, 1)

  set wildignore=oldwildignore
  set suffixes=oldsuffixes

  " Add back the dirname from the glob
  if dirname != "/"
    let compl = map(compl, {_, i -> dirname . "/" . fnamemodify(i, ":t")})
  else
    let compl = map(compl, {_, i -> "/" . fnamemodify(i, ":t")})
  endif

  " Append / to directories to avoid typing it manually. Mimcs default file completion behavior.
  let compl = map(compl, {_, c -> c . (isdirectory(expand(c)) ? "/" : "")})

  " Filter out non executable files. Only for Debug command
  let cmd = split(a:L, " ")[0]
  if cmd == "Debug"
    let compl = filter(compl, {_, c -> isdirectory(expand(c)) || executable(expand(c))})
  endif

  return compl
endfunction

function! ExeComplSSH(A, L, P)
  let cmd = split(a:L, " ")[0]
  if cmd == "DebugSSH"
    " Only executables
    let ftype = '-x'
  else
    " Any file
    let ftype = '-f'
  endif

  let item = a:A
  let globStr = item . "*"
  " Get list of completion results

  let scriptStr = "for file in " . globStr . "; do if [[ -d $file ]]; then echo $file/; elif [[ " . ftype . " $file ]]; then echo $file; fi; done"
  let echoScript = "echo " . "'" . scriptStr . "'"
  let compl = split(system(echoScript . "| ssh -o 'ConnectTimeout 1' root@192.168.3.2 /bin/bash"), nr2char(10))
  if v:shell_error != 0
    return []
  endif

  if len(compl) == 1 && compl[0] == globStr
    return []
  else
    return compl
  endif
endfunction

function! s:GetProcessID(pname, ssh_or_empty)
  let cmd = ""
  if !empty(a:ssh_or_empty)
    let cmd = "ssh " . a:ssh_or_empty . " "
  endif
  let cmd .= "pgrep " . a:pname
  let pid = split(system(cmd), nr2char(10))
  if len(pid) > 1
    echoerr "Multiple processes"
    return -1
  endif
  if len(pid) == 0
    echoerr "No process matching pattern"
    return -1
  endif
  return str2nr(pid[0]) 
endfunction

" Available modes:
" - exe. Pass executable + arguments
" - pname. Process name to attach. Will be resolved to a pid.
" - core. Pass a coredump to debug
" Other arguments:
" - symbols. Whether to load symbols or not. Used for faster loading of gdb.
" - ssh. Launch GDB over ssh with the given address.
function! s:Debug(args)
  if TermDebugIsOpen()
    echoerr 'Terminal debugger already running, cannot run two'
    return
  endif

  autocmd User TermdebugStopPre call s:DebugStopPre()
  exe "autocmd User TermdebugStartPost call s:DebugStartPost(" . string(a:args) . ")"

  if has_key(a:args, "ssh")
    call TermDebugStartSSH(a:args["ssh"])
  else
    call TermDebugStart()
  endif
endfunction

function! s:DebugStartPost(args)
  let quickLoad = has_key(a:args, "symbols") && !a:args["symbols"]

  nnoremap <silent> <leader>v :call TermDebugSendCommand("p " . expand('<cword>'))<CR>
  vnoremap <silent> <leader>v :call TermDebugSendCommand("p " . <SID>GetRangeExpr())<CR>
  nnoremap <silent> <leader>br :call TermDebugSendCommand("br " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>tbr :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<CR>
  nnoremap <silent> <leader>unt :call TermDebugSendCommand("tbr " . <SID>GetDebugLoc())<BAR>call TermDebugSendCommand("c")<CR>
  nnoremap <silent> <leader>pc :call TermDebugGoToPC()<CR>

  call TermDebugSendCommand("set debug-file-directory /dev/null")
  call TermDebugSendCommand("set print asm-demangle on")
  call TermDebugSendCommand("set print pretty on")
  call TermDebugSendCommand("set print frame-arguments none")
  call TermDebugSendCommand("set print raw-frame-arguments off")
  call TermDebugSendCommand("set print entry-values no")
  call TermDebugSendCommand("set print inferior-events off")
  call TermDebugSendCommand("set print thread-events off")
  call TermDebugSendCommand("set print object on")
  call TermDebugSendCommand("set breakpoint pending on")
  call TermDebugSendCommand("set debuginfod enabled off")
  if quickLoad
    call TermDebugSendCommand("set auto-solib-add off")
  endif
  
  if has_key(a:args, "pname")
    let pname = a:args["pname"]
    let pid = s:GetProcessID(pname, get(a:args, 'ssh', ''))
    if pid >= 0
      call TermDebugSendCommand("attach " . pid)
    endif
  elseif has_key(a:args, "exe")
    let cmdArgs = split(a:args["exe"], " ")
    call TermDebugSendCommand("file " . cmdArgs[0])
    if len(cmdArgs) > 1
      call TermDebugSendCommand("set args " . join(cmdArgs[1:], " "))
    endif
    call TermDebugSendCommand("start")
  elseif has_key(a:args, "core")
    let core = a:args["core"]
    let prog = s:ProgramCoreMapping(core)
    if !empty(prog)
      call TermDebugSendCommand("file" . prog)
      call TermDebugSendCommand("core " . core)
    endif
  endif

  if TermDebugGetPid() > 0
    call TermDebugSendCommand("set scheduler-locking step")
    call TermDebugSendCommand("set disassembly-flavor intel")
  endif
endfunction

function! s:DebugStopPre()
  autocmd! User TermdebugStopPre
  autocmd! User TermdebugStartPost
  execute "Source" | setlocal so=4

  nunmap <silent> <leader>v
  vunmap <silent> <leader>v
  nunmap <silent> <leader>br
  nunmap <silent> <leader>tbr
  nunmap <silent> <leader>unt
  nunmap <silent> <leader>pc
endfunction

function! s:GetDebugLoc()
  let absolute = v:false
  if absolute
    let file = expand("%:p")
  else
    let file = expand("%:t")
  endif
  let ln = line(".")
  return file.":".ln
endfunction

function! s:GetRangeExpr()
  let [lnum1, col1] = getpos("'<")[1:2]
  let [lnum2, col2] = getpos("'>")[1:2]
  let lines = getline(lnum1, lnum2)
  let lines[-1] = lines[-1][:col2 - 1]
  let lines[0] = lines[0][col1 - 1:]
  let expr = join(lines, "\n")
  return expr
endfunction

command! -nargs=0 -bar TermDebugMessages tabnew | exe "b " . bufnr("Gdb messages")
"}}}

""""""""""""""""""""""""""""LSP"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
command! LspStop lua vim.lsp.stop_client(vim.lsp.get_active_clients())
command! LspProg lua print(vim.inspect(vim.lsp.util.get_progress_messages()))

command! -range=% For lua vim.lsp.buf.format{ range = {start= {<line1>, 0}, ["end"] = {<line2>, 0}} }

" Document highlight
highlight LspReferenceText gui=underline
highlight! link LspReferenceRead LspReferenceText
highlight! link LspReferenceWrite LspReferenceText
lua vim.highlight.priorities.user = 9999

" Class highlight
highlight LspCxxHlGroupMemberVariable guifg=LightGray
highlight! link LspCxxHlGroupNamespace LspCxxHlSymClass

lua require('lsp')

autocmd User LspProgressUpdate redrawstatus
autocmd User LspRequest redrawstatus
"}}}
