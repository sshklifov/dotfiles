" vim: set sw=2 ts=2 sts=2 foldmethod=marker:
call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-endwise'

Plug 'glepnir/oceanic-material'
Plug 'joshdick/onedark.vim'

Plug 'webdevel/tabulous'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'tpope/vim-fugitive'
Plug 'neovim/nvim-lspconfig'
Plug 'jackguo380/vim-lsp-cxx-highlight'
Plug 'sshklifov/debug'
Plug 'sshklifov/vim-lang'

call plug#end()

packadd cfilter

""""""""""""""""""""""""""""Plugin settings"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" debug
let g:termdebug_capture_msgs = 1

" vim-eunuch (substitution)
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

" vim-lang
let g:XkbSwitchEnable = 0
let g:XkbSwitchLib = "/home/shs1sf/xkb-switch/build/libxkbswitch.so.1.8.5"

" vim-eunich
set diffopt-=horizontal
set diffopt+=vertical

" vim-commentary
autocmd BufEnter,BufNew *.fish setlocal commentstring=#\ %s
autocmd FileType vim setlocal commentstring=\"\ %s

" vim-fugitive

function DescribeCommitish()
  let tags = FugitiveExecute("describe", "--all")
  if tags['exit_status'] == 0
    return tags['stdout'][0]
  endif
  return FugitiveExecute("rev-parse", "--short" "HEAD")
endfunction

command! -nargs=0 Head echo DescribeCommitish()

"}}}

""""""""""""""""""""""""""""Everything else"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
cabbr Gd lefta Gdiffsplit
cabbr Gl Gclog!
cabbr Gb Git blame
cabbr Gdt Git! difftool
cabbr Gmt Git mergetool

cab Pf Pfind
cab Wf Wfind
cab Bf Bfind
cab CM FindCMake

cab Hi Highlight

cab Cd Cdelete
cab Co Conly
cab Cf Cfilter

autocmd FileType gitcommit set spell

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
autocmd FileType text,tex set tw=100

" Smart searching with '/'
set ignorecase
set smartcase
set hlsearch
nnoremap <silent> <Space> :nohlsearch <bar> LspCxxHighlight<CR>

" Typos
command! Q q
command! W w
command! Qa qa

" Annoying quirks
set sessionoptions-=blank
set shortmess+=I
au FileType * setlocal fo-=cro
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1
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

autocmd FileType qf setlocal cursorline

" }}}

""""""""""""""""""""""""""""Quickfix"""""""""""""""""""""""""""" {{{
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:Grep(regex, ...)
  call setqflist([], ' ', {'title' : 'Grep', 'items' : []})

  function! OnEvent(id, data, event)
    let matches = filter(a:data, {i, d -> !empty(d)})
    function! GetItem(index, match)
      let sp = split(a:match, ":")
      if len(sp) < 3
        return {}
      endif
      if !filereadable(sp[0])
        return {}
      endif
      " Apply filter
      if exists('s:grep_exclude_paths')
        for exclude_path in s:grep_exclude_paths
          if stridx(sp[0], exclude_path) >= 0
            return {}
          endif
        endfor
      endif
      if !(sp[1] =~ '^[0-9]\+$')
        return {}
      endif
      return {"filename": sp[0], "lnum": sp[1], 'text': join(sp[2:-1])}
    endfunction
    let items = filter(map(matches, function("GetItem")), {_, o -> !empty(o)})
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
command! -nargs=1 Grep call <SID>Grep(<q-args>, [expand("%:p")])
" All files in quickfix
command! -nargs=1 Qgrep call <SID>GrepQuickfixFiles(<q-args>)
" Current path
command! -nargs=1 Rgrep call <SID>Grep(<q-args>, getcwd())
" All indexed files in project
command! -nargs=1 Igrep call <SID>Grep(<q-args>, s:GetIndexedFiles())
" All project files
command! -nargs=1 Wgrep call <SID>Grep(<q-args>, GetWorkspace())

" All document files
command! -nargs=1 VimHelp call <SID>Grep(<q-args>, "/usr/share/nvim/runtime/doc")
" All plugins
command! -nargs=1 VimPlug call <SID>Grep(<q-args>, "~/.vim/plugged")
" Config files
command! -nargs=1 VimConfig call <SID>Grep(<q-args>, "~/.config/nvim")

function! s:DeleteQfEntries(a, b)
  let qflist = filter(getqflist(), {i, _ -> i+1 < a:a || i+1 > a:b})
  call setqflist([], ' ', {'title': 'Cdelete', 'items': qflist})
endfunction

function! s:OnlyQfEntries(a, b)
  let qflist = filter(getqflist(), {i, _ -> i+1 >= a:a && i+1 <= a:b})
  call setqflist([], ' ', {'title': 'Cdelete', 'items': qflist})
endfunction

autocmd FileType qf command! -buffer -range Cdelete call <SID>DeleteQfEntries(<line1>, <line2>)
autocmd FileType qf command! -buffer -range Conly call <SID>OnlyQfEntries(<line1>, <line2>)

function! s:OpenJumpList()
  let jl = getjumplist()
  let entries = jl[0]
  let idx = jl[1]

  function! FixBuf(_, e)
    if !bufexists(a:e['bufnr'])
      let a:e['bufnr'] = bufnr("%")
    endif
    return a:e
  endfunction
  let entries = map(entries, function("FixBuf"))

  call setqflist([], 'r', {'title': 'Jump', 'items': entries})
  if idx < len(entries)
    exe "keepjumps crewind " . (idx + 1)
  endif

  " Keep the same window focused
  let winnr = bufwinnr(bufname("%"))
  keepjumps copen
  exec "keepjumps " . winnr . "wincmd w"
endfunction

function! s:Jump(scope)
  if <SID>IsBufferQf()
    return
  endif

  " Pass 1 to normal so vim doesn't interpret ^i as a TAB (they use the same keycode of 9)
  if a:scope == "in"
    exe "normal! 1" . "\<c-i>"
  elseif a:scope == "out"
    exe "normal! 1" . "\<c-o>"
  endif

  " Refresh jump list
  if <SID>IsQfOpen()
    let title = getqflist({'title': 1})['title']
    if title == "Jump"
      call <SID>OpenJumpList()
    endif
  endif
endfunction

nnoremap <silent> <leader>ju :call <SID>OpenJumpList()<CR>
nnoremap <silent> <c-o> :call <SID>Jump("out")<CR>
nnoremap <silent> <c-i> :call <SID>Jump("in")<CR>

function! s:ShowBuffers()
  let nrs = filter(range(1, bufnr('$')), {_, n -> buflisted(n) && filereadable(bufname(n))})

  function! GetItem(_, n)
    let bufinfo = getbufinfo(a:n)[0]
    let text = "" . a:n
    if bufinfo["changed"]
      let text = text . " (modified)"
    endif
    return {"bufnr": a:n, "text": text, "lnum": bufinfo["lnum"]}
  endfunction

  let items = map(nrs, function("GetItem"))
  call setqflist([], 'r', {'title' : 'Buffers', 'items' : items})
  copen
endfunction

nnoremap <silent> <leader>buf :call <SID>ShowBuffers()<CR>

command! -nargs=1 -bar Buffer call <SID>ShowBuffers() | Cfilter <q-args>

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
set background=dark
colorscheme oceanic_material
set termguicolors
highlight TabLine guibg=#1b2b34 guifg=#c0c5ce gui=underline
highlight TabLineSel guifg=#1b2b34 guibg=#c0c5ce gui=underline

hi default link qfFileName Comment

" Show indentation
set list
set list lcs=tab:\|\ 

" Tabulous
let tabulousLabelLeftStr = ' ['
let tabulousLabelRightStr = '] '
let tabulousLabelNumberStr = ':'
let tabulousLabelNameDefault = 'Empty'
let tabulousCloseStr = ''

" vim-airline
let g:airline#extensions#xkblayout#enabled = 0

let g:airline_detect_crypt = 0
let g:airline_detect_spelllang = 0
let g:airline_powerline_fonts = 1
let g:airline_theme = "base16_ocean"
let g:airline_symbols = {'space': ' ', 'paste': 'PASTE', 'maxlinenr': '',
      \ 'dirty': '', 'crypt': '', 'linenr': '', 'readonly': '[RO]',
      \ 'spell': 'SPELL', 'modified': '+', 'notexists': '', 'keymap': 'Keymap:',
      \ 'ellipsis': '...', 'branch': '', 'whitespace': ''}

function! GetStatusLineFile()
  let maxwidth = 100
  let filename = bufname()
  let cwd = getcwd()
  " Empty file -> Display path only
  if empty(filename)
    return BidirPathShorten(cwd, maxwidth) . " " . g:airline_left_alt_sep
  endif
  " VIM Buffer with no respective file on disk -> Display buffer only
  if !filereadable(bufname())
    return bufname()
  endif
  let filename = expand("%:p")

  " Dir is not substring of file -> Display file only
  let mixedStatus = (filename[0:len(cwd)-1] == cwd)
  if !mixedStatus
    return PathShorten(filename, maxwidth)
  endif

  " Use name relative to cwd
  let filename = filename[len(cwd)+1:]
  " Mix cwd with filename
  let sep = " " . g:airline_left_alt_sep . " "
  let status = cwd . sep . filename
  if len(status) < maxwidth
    return status
  endif
  let shortFilename = filename
  let shortCwd = BidirPathShorten(getcwd(), maxwidth - len(shortFilename))
  let status = shortCwd . sep . shortFilename
  return status
endfunction

function! BidirPathShorten(inPath, maxwidth)
  let path = a:inPath
  if len(path) <= a:maxwidth
    return path
  endif

  let partList = split(path, "/")
  let partIndices = range(len(partList))

  let leftPart = ""
  let rightPart = ""
  while !empty(partIndices)
    " Add path part to the right
    let tmpRight = "/" . partList[partIndices[-1]] . rightPart
    let res = leftPart . tmpRight
    if len(res) > a:maxwidth
      break
    endif
    let rightPart = tmpRight
    let partIndices = partIndices[:-2]

    if !empty(partIndices)
      " Add parth part to the left
      let tmpLeft = leftPart . "/" . partList[partIndices[0]] 
      let res = tmpLeft . rightPart
      if len(res) > a:maxwidth
        break
      endif
      let leftPart = tmpLeft
      let partIndices = partIndices[1:]
    endif
  endwhile
  " Degenerate case, just show the top level directory
  if empty(rightPart) || empty(leftPart)
    return "(..)/" . partList[-1]
  endif

  if empty(partIndices)
    echoerr "Assert failed! Path was not truncated, even though the first if checks against this!"
  endif
  return leftPart . "/(..)" . rightPart
endfunction

function! PathShorten(file, maxwidth)
  if empty(a:file)
    return "[No name]"
  endif
  if len(a:file) < a:maxwidth
    return a:file
  endif

  let relative = (a:file[0] != "/")
  " Truncate from the left. truncPart will be substituted in place of excess symbols.
  if relative
    let truncPart = ""
  else
    let truncPart = "/"
	endif
  let filePart = ""
  for item in reverse(split(a:file, "/"))
    let tmp = "/" . item . filePart
    if len(tmp) > a:maxwidth
      let truncPart = "(..)/"
      break
    endif
    let filePart = tmp
  endfor
  return truncPart . filePart[1:]
endfunction

command! -nargs=0 Bname echo expand("%:p")
command! -nargs=0 Pwd pwd

function! AirlineInit()
if g:XkbSwitchEnable
  call airline#parts#define_function('xkblayout', 'XkbSwitchGetLayout')
endif
  call airline#parts#define_function('lsp_status', 'GetLspStatus')
  call airline#parts#define_function('file', 'GetStatusLineFile')

  let g:airline_section_c = airline#section#create(['lsp_status'] + ['file'] + [ ' ', '%m', 'readonly'])
  let g:airline_section_z = airline#section#create(['%p%%', ' ', '(%l/%L)'])
endfunction

au User AirlineAfterInit call AirlineInit()

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

function! s:ChangeIntoWorkspace()
  let ws = GetWorkspace()
  if !empty(ws)
    exe "lcd " . ws
  endif
endfunction

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

function! s:ToggleDiff()
  let do_open_diff = v:true

  let winids = gettabinfo(tabpagenr())[0]["windows"]
  for winid in winids
    let winnr = win_id2tabwin(winid)[1]
    let bufnr = winbufnr(winnr)
    let name = bufname(bufnr)
    if name =~ "^fugitive:///"
      let commitish = split(FugitiveParse(name)[0], ":")[0]
      let realnr = bufnr(FugitiveReal(name))

      call win_gotoid(winid)
      " Memorize the last diff commitish for the buffer
      exe "b " . realnr
      let b:commitish = commitish
      " Close fugitive window
      quit

      " Found a window in diff mode, which means that toggle should close all such windows
      let do_open_diff = v:false
    endif
  endfor

  if do_open_diff
    " No window in diff mode, toggle should open diff
    if exists("b:commitish") && b:commitish != "0"
      exe "lefta Gdiffsplit " . b:commitish
    else
      lefta Gdiffsplit
    endif
  endif
endfunction

nnoremap <silent> <leader>dif :call <SID>ToggleDiff()<CR>

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

set updatetime=500
set completeopt=menuone
inoremap <silent> <C-Space> <C-X><C-O>

" http://vim.wikia.com/wiki/Automatically_append_closing_characters
" Parentheses
inoremap ( ()<Left>
inoremap (<BS> <NOP>
inoremap <expr> )  strpart(getline('.'), col('.')-1, 1) == ")" ? "\<Right>" : ")"
" Brackets
inoremap [ []<Left>
inoremap [<BS> <NOP>
inoremap <expr> ]  strpart(getline('.'), col('.')-1, 1) == "]" ? "\<Right>" : "]"
" Braces
inoremap { {}<Left>
inoremap {} {}<Left>
inoremap {<BS> <NOP>
inoremap <expr> }  strpart(getline('.'), col('.')-1, 1) == "}" ? "\<Right>" : "}"
inoremap {<CR> {<CR>}<C-o>O

nmap <leader>sp :setlocal invspell<CR>

let g:findExcludePaths = {
      \ "/home/shs1sf/ccls": ["ccls-cache", "Release", ".git", "index_tests"],
      \ "/home/shs1sf/ivs_": ["build", "install", ".git", "ambarella", "ccls-cache", ".ccls-cache", "extra_includes"]
      \ }

function! s:GetExcludePaths(dir)
  for [key, value] in items(g:findExcludePaths)
    if stridx(a:dir, key) >= 0
      return value
    endif
  endfor
  return []
endfunction

function! s:Find(dir, arglist, Cb)
  if empty(a:dir)
    return
  endif

  " Add exclude paths flags
  let flags = []
  for excludePath in <SID>GetExcludePaths(a:dir)
    let flags = flags + ["-path", "**/" . excludePath, "-prune", "-false", "-o"]
  endfor

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

function! s:FindInQuickfix(dir, ...)
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

  " Perform find operation
  call setqflist([], ' ', {'title' : 'Find', 'items' : []})
  let id = <SID>Find(a:dir, flags, Cb)

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

function! GetWorkspace()
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

function! s:GetIndexedFiles()
  let workspace = GetWorkspace()
  let cacheGlob = workspace . "/ccls-cache/[@][^@]*"
  let cdCmd = "cd " . cacheGlob

  let findCmd = "find ."
  " Add exclude paths flags
  for excludePath in <SID>GetExcludePaths(workspace)
    let findCmd = findCmd . ' -not -regex ".*' . excludePath . '.*"'
  endfor

  let findCmd = findCmd . ' -type f -not -regex ".*blob"'
  let sedCmd = 'sed "s|@|/|g"'
  let files = split(system(cdCmd . " && " . findCmd . " | " . sedCmd), nr2char(10))
  let files = map(files, {_, f -> workspace . "/" . f})
  let files = filter(files, {_, f -> filereadable(f)})
  return files
endfunction

function! s:OpenIndexedFiles()
  let files = s:GetIndexedFiles()
  if empty(files)
    echom "Not indexed"
    return
  endif

  let items = map(files, {_, f -> {'filename': f, 'lnum': 1, 'text': fnamemodify(f, ':t')}})
  call setqflist([], 'r', {'title' : 'CCLS cache', 'items' : items})
  copen
endfunction
command! -nargs=0 Index call <SID>OpenIndexedFiles()

function! s:FindInWorkspace(loc)
  let ws = GetWorkspace()
  if empty(ws)
    return
  endif
  call <SID>FindInQuickfix(ws, a:loc)
endfunction

" TODO Only used in ListCMake
function! s:GetFiles(dir, flags)
  let s:files = []
  function! AppendFiles(id, data, event)
    let s:files = s:files + filter(a:data, {i, d -> filereadable(d)})
    if len(s:files) > 4000
      echom s:files
      echom "Too many files, stopping..."
      call jobstop(a:id)
      return
    endif
  endfunction

  let id = <SID>Find(a:dir, a:flags, function("AppendFiles"))
  call jobwait([id])

  let files = s:files
  unlet s:files
  return files
endfunction

function! s:ListCMake()
  let hierarchy = v:true

  let ws = GetWorkspace()
  if empty(ws)
    return
  endif
  " Find all CMake files in workspace
  let files = s:GetFiles(ws, ['-iregex', '.*cmake.*'])
  " Filter those that are relevant to the opened file
  if a:hierarchy
    let files = filter(files, {_, f -> stridx(expand("%:p:h"), fnamemodify(f, ':h')) >= 0 })
    " Order by those that are most relevant
    let files = reverse(sort(files))
  endif

  " Add to quickfix
  let entries = map(files, {_, f -> {'filename': f, 'text': fnamemodify(f, ':t')}})
  call setqflist([], ' ', {'title': 'CMake', 'items': entries})
  copen
endfunction

" TODO Not used very much...
command! -nargs=0 ListCMake call <SID>ListCMake()

command! -nargs=+ -complete=file Find call <SID>FindInQuickfix(<f-args>)
command! -nargs=? Pfind call <SID>FindInQuickfix(getcwd(), <q-args>)
command! -nargs=? Wfind call <SID>FindInWorkspace(<q-args>)
command! -nargs=? Bfind call <SID>FindInQuickfix(expand("%:p:h"), <q-args>)

command! -nargs=0 Methods lua ListFilteredSymbols('Method\\|Construct')
command! -nargs=0 Functions lua ListFilteredSymbols('Function')
command! -nargs=0 Callable lua ListFilteredSymbols('Method\\|Construct\\|Function')
command! -nargs=0 Variables lua ListFilteredSymbols('Variable\\|Field')
command! -nargs=0 Types lua ListFilteredSymbols('Class\\|Struct\\|Enum')
" }}}

""""""""""""""""""""""""""""Code navigation"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Navigate blocks
nnoremap [b [{
nnoremap ]b ]}

function! s:ShowBlocks()
  let initialPos = getpos('.')
  let posList = [initialPos[1:2]]
  while v:true
    normal [b
    let new_pos = getpos('.')[1:2]
    if new_pos == posList[-1]
      break
    endif
    let posList = posList + [new_pos]
  endwhile

  let entries = map(posList, {_, p -> {"filename": bufname(), "lnum": p[0], "col": p[1], 'text': getline(p[0])}})
  let entries = reverse(entries)
  call setqflist([], ' ', {'title' : 'Blocks', 'items' : entries})
  copen
  clast
endfunction

nnoremap <silent> <leader>bl :call <SID>ShowBlocks()<CR>

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
  call <SID>FindInWorkspace(expand("%:t:r") . ".c")
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
  call <SID>FindInWorkspace(expand("%:t:r") . ".h")
endfunction

nmap <silent> <leader>cpp :call <SID>OpenSource()<CR>
nmap <silent> <leader>hpp :call <SID>OpenHeader()<CR>

function! MatchGetCapture(str, pat)
  let res = matchlist(a:str, a:pat)
  if empty(res)
    return ""
  endif
  return res[1]
endfunction

function! s:ResolveConanRepo(filename)
  if stridx(a:filename, 'ivs-camera-services') >= 0
    return "/home/shs1sf/ivs_camera_services/"
  elseif stridx(a:filename, 'ivs-base') >= 0
    return "/home/shs1sf/ivs_base/"
  elseif stridx(a:filename, 'ivs-car-bluetooth') >= 0
    return "/home/shs1sf/ivs_car_bluetoothservice/"
  endif
  echoerr "Cannot resolve conan repo"
  return ""
endfunction

function! s:EditConan(...)
  let bufname = get(a:, 1, expand("%:p"))
  if bufname !~ "/.conan/"
    return ""
  endif

  let repo = <SID>ResolveConanRepo(bufname)
  if empty(repo)
    return ""
  endif

  let path = MatchGetCapture(bufname, '.*/[0-9a-f]\{40\}/\(.*\)$')
  let pos = getpos(".")
  let loc = path . ":" . pos[1] . ":" . pos[2]
  call <SID>FindInQuickfix(repo, loc)
endfunction

nnoremap <silent> <leader>con :call <SID>EditConan()<CR>

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
"}}}

""""""""""""""""""""""""""""DEBUGGING"""""""""""""""""""""""""""" {{{
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

command! -nargs=1 -complete=customlist,AttachCompl Attach call s:Debug({'pname': <q-args>})
command! -nargs=1 -complete=customlist,AttachSSHCompl AttachSSH call s:DebugSSH({'pname': <q-args>})

command! -nargs=? -complete=customlist,ExeCompl -bar Debug
      \ if empty(<q-args>) |
      \   call s:Debug({}) |
      \ else |
      \   call s:Debug({"exe": <q-args>}) |
      \ endif
command! -nargs=? -complete=customlist,ExeComplSSH -bar DebugSSH
      \ if empty(<q-args>) |
      \   call s:DebugSSH({}) |
      \ else |
      \   call s:DebugSSH({"exe": <q-args>}) |
      \ endif

command! -nargs=1 -complete=customlist,ExeCompl -bang Coredump call s:Debug({"core": <q-args>})
command! -nargs=1 -complete=customlist,ExeComplSSH -bang CoredumpSSH call s:DebugSSH({"core": <q-args>})

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
  let scriptStr = "for file in $(ps -o args | cut -d \" \"  -f 1); do if [[ -x $file ]]; then echo $file; fi; done"

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

" Convenience method
function! s:DebugSSH(in_args)
  let args = a:in_args
  let args['ssh'] = 'root@192.168.3.2'
  call s:Debug(args)
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

" TODO No easy way to determine who generated the core.
" -readelf doesn't work
" -not in a fixed place in the elf core header
" -starting GDB just to print 'Core file was generated by' might be slow
function! s:ProgramCoreMapping(core)
  if stridx(a:core, "bluetoothservic") >= 0
    return "/opt/bosch/bin/bluetoothservice"
  endif
  echoerr "Unknown core, cannot determine who generated it."
  return ""
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
  autocmd User TermdebugCommOutput call s:DebugCommOutput()
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

  command! -nargs=0 -bar -bang Qbr if <bang>1 | call TermDebugQfToBr() | else | call TermDebugBrToQf() | endif

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
  if quickLoad
    call TermDebugSendCommand("set auto-solib-add off")
  endif
  
  call TermDebugSendCommand("set substitute-path /workspaces/ivs_feature_chain /home/shs1sf/ivs_feature_chain")
  call TermDebugSendCommand("set substitute-path /build/ivs_car_hailysharey /home/shs1sf/ivs_car_hailysharey")
  call TermDebugSendCommand("set substitute-path /home/build/repo /home/shs1sf/ivs_car_bluetoothservice")

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

function! s:DebugCommOutput()
  let msgs = g:termdebug_comm_output
  for msg in msgs
    if stridx(msg, "No such file or directory") >= 0
      let fname = MatchGetCapture(msg, '&"[0-9]*\\t\([^:]*\):')
    endif
  endfor

  if exists("l:fname") && !empty(fname)
    let conan_dir = MatchGetCapture(fname, '\(.*[0-9a-f]\{40\}\)')
    let git_dir = s:ResolveConanRepo(conan_dir)
    if !empty(conan_dir) && isdirectory(git_dir)
      call TermDebugSendMICommand("-gdb-set substitute-path " . conan_dir . " " . git_dir)
      echom "Substituting conan package with git repo"
    endif
  endif
endfunction

function! s:DebugStopPre()
  autocmd! User TermdebugStopPre
  autocmd! User TermdebugStartPost
  execute "Source" | setlocal so=4

  delcommand Qbr

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

command! For lua vim.lsp.buf.format()

" Document highlight
highlight LspReferenceText gui=underline
highlight default link LspReferenceRead LspReferenceText
highlight default link LspReferenceWrite LspReferenceText
lua vim.highlight.priorities.user = 9999

lua require('lsp')

autocmd User LspProgressUpdate redrawstatus
autocmd User LspRequest redrawstatus

let s:highlightFrozen = 0

function! s:ToggleHighlight()
  let s:highlightFrozen = xor(s:highlightFrozen, 1)

  if s:highlightFrozen
    lua FreezeHighlight(true)
    echo "Highlight frozen"
  else
    lua FreezeHighlight(false)
    echo "Highlight restored"
  endif
endfunction

command! -nargs=0 -bang Highlight call <SID>ToggleHighlight()

function! GetLspStatus()
  let serverResponses = luaeval('vim.lsp.util.get_progress_messages()')
  if empty(serverResponses)
    return ""
  endif

  function! Sum(list)
    let sum = 0
    for i in a:list
      let sum = sum + i
    endfor
    return sum
  endfunction

  function! GetProgress(_, status)
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

  let serverProgress = map(serverResponses, function("GetProgress"))

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
  let sep = " " . g:airline_left_alt_sep . " "
  return "Indexing " . percentage . "%" . sep
endfunction

function! GetRootDir(filename, bufnr)
  let dir = fnamemodify(a:filename, ":h")
  while dir != "/"
    let json = dir . "/" . "compile_commands.json"
    let git = dir . "/" . ".git"
    if filereadable(json) && isdirectory(git)
      return dir
    endif
    let dir = fnamemodify(dir, ":h")
  endwhile
  return ""
endfunction
"}}}
