call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-sensible'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-endwise'

Plug 'arcticicestudio/nord-vim'
Plug 'webdevel/tabulous'
Plug 'vim-airline/vim-airline'

Plug 'PotatoesMaster/i3-vim-syntax'
Plug 'octol/vim-cpp-enhanced-highlight'

Plug 'Valloric/YouCompleteMe', { 'for': ['c', 'cpp'], 'do': './install.py --clang-completer --system-libclang' }
Plug 'sshklifov/auclo'
"Plug 'sakhnik/nvim-gdb'

call plug#end()

" vim-eunuch
function! LineNumFind(args)
  redir => msg
  silent execute "Cfind! ".a:args
  redir END
  echo join(
\   map(
\     filter(
\       split(msg, "\n"),
\         {_, val -> match(val,  '^\p*$\&\(^\s*$\)\@!') >= 0}),
\     {key, val -> (key+1).": ".val}),
\   "\n")
  return ''
endfunction

command! -bar -bang -complete=file -nargs=+ Find exe LineNumFind(<q-args>)

" vim-unimpaired
nnoremap [l :lprev<CR>
nnoremap ]l :lnext<CR>

" colorscheme
colorscheme nord
set background=dark
set termguicolors

" tabulous
let tabulousLabelLeftStr = ' ['
let tabulousLabelRightStr = '] '
let tabulousLabelNumberStr = ':'
let tabulousLabelNameDefault = 'Empty'
let tabulousCloseStr = ''

" vim-airline
let g:airline_powerline_fonts = 1
let g:airline_symbols = {'space': ' ', 'paste': 'PASTE', 'maxlinenr': ' |',
\ 'dirty': '⚡', 'crypt': '🔒', 'linenr': '<C-G>', 'readonly': '',
\ 'spell': 'SPELL', 'modified': '+', 'notexists': 'Ɇ', 'keymap': 'Keymap:',
\ 'ellipsis': '...', 'branch': '', 'whitespace': ''}

" YCM
let g:ycm_always_populate_location_list = 1
let g:ycm_min_num_of_chars_for_completion = 3
let g:ycm_max_num_candidates = 10
let g:ycm_max_num_identifier_candidates = 30
let g:ycm_filetype_whitelist = {'cpp': 1, 'c': 1}
let g:ycm_complete_in_comments = 1
" let g:ycm_extra_conf_vim_data = []
let g:ycm_max_diagnostics_to_display = 5
let g:ycm_global_ycm_extra_conf = '~/.config/nvim/ycm_conf.py'
let g:ycm_confirm_extra_conf = 0
let g:ycm_goto_buffer_command = 'split-or-existing-window'
let g:ycm_key_list_select_completion = ['<Down>']
let g:ycm_key_list_previous_completion = ['<Up>']
let g:ycm_key_list_stop_completion = ['<C-y>']
let g:ycm_key_invoke_completion = '<C-Space>'
let g:ycm_key_detailed_diagnostics = '<leader>e'
" set completeopt-=preview
" au! InsertLeave *.cpp,*.h :pclose

" auclo
let g:auclo_whitelist = ['cpp', 'c']

" IDE <leader> maps
" nnoremap <leader>i :YcmCompleter GoToInclude<CR>
" nnoremap <leader>b :YcmCompleter GoToDeclaration<CR>
" nnoremap <leader>p :YcmCompleter GoToDefinition<CR>
" nnoremap <leader>g :YcmCompleter GoTo<CR>
" nnoremap <leader><leader>g :YcmCompleter GoToImprecise<CR>
" nnoremap <leader>d :YcmCompleter GetDoc<CR>
" nnoremap <leader><leader>d :YcmCompleter GetDocImprecise<CR>
nnoremap <leader>fix :YcmCompleter FixIt<CR>

nnoremap <silent> <leader><leader>q :mksession! ~/nvim<CR>:qa<CR>
nnoremap <silent> <leader>so :so nvim<CR>
nnoremap <silent> <leader>mk :mksession! ~/nvim<CR>
nnoremap <silent> <leader>cd :cd %:p:h<CR>
nnoremap <silent> <leader>t :execute ":silent !i3-msg exec" . shellescape("kitty -d " . getcwd())<CR>
nnoremap <silent> <leader><leader>t :execute ":silent !i3-msg exec" . shellescape("kitty -d " . expand("%:p:h"))<CR>
nnoremap <silent> <leader>ev :tabnew $MYVIMRC<CR>
nnoremap <silent> <leader>sv :source $MYVIMRC<CR>

nnoremap <leader>y "+y
nnoremap <leader>Y "+Y
nnoremap <leader>p "+p
nnoremap <leader>P "+P
xnoremap <leader>y "+y
xnoremap <leader>Y "+Y
xnoremap <leader>p "+p
xnoremap <leader>P "+P

" Indentation settings
set expandtab
set shiftwidth=4
set softtabstop=4
set cinoptions=g0,l1,L0,:0,b1

" Display line numbers
set number
set relativenumber

" Smart searching with '/'
set ignorecase
set smartcase
set hlsearch
nnoremap <silent> <Space> :nohlsearch<CR>:pclose<CR>

" Typos
:command! Q q
:command! W w
:command! Qa qa

" Command completion
set wildchar=9
set wildignore="*.\\.o *.\\.out *.\\.obj"
set wildignorecase
set wildmode=full

" Annoying quirks
" TODO HELP netrw
let g:netrw_banner = 0
set shortmess+=I
au FileType * setlocal fo-=cro

" vim: set sw=2 ts=2 sts=2:
