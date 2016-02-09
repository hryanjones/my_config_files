" Pathogen
" --------

" Pathogen seems to be sucking on hrjones.aka and can't figure out why
" adding plugin lines here
"set runtimepath^=~/.vim/bundle/neocomplcache/autoload/neocomplcache.vim
runtime bundle/neocomplcache/autoload/neocomplcache.vim

let g:acp_enableAtStartup = 0
let g:neocomplcache_enable_at_startup = 1
let g:neocomplcache_enable_smart_case = 1
let g:neocomplcache_min_syntax_length = 3
" Use a mapping similar to fish with neocomplcache to accept first autocomplete
"
inoremap <C-f>     <Down><Enter>

" Enable omni completion.
autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
" Enable heavy omni completion.
if !exists('g:neocomplcache_omni_patterns')
  let g:neocomplcache_omni_patterns = {}
endif

nnoremap <F4> :GundoToggle<CR>
set rtp+=~/.vim/bundle/powerline/powerline/bindings/vim
set runtimepath^=~/.vim/bundle/ctrlp.vim
set runtimepath^=~/.vim/bundle/nerdcommenter/plugin/NERD_commenter.vim
set runtimepath^=~/.vim/bundle/nerdtree/plugin/NERD_tree.vim
set runtimepath^=~/.vim/bundle/vim-endwise/plugin/endwise.vim
set runtimepath^=~/.vim/bundle/vim-surround/plugin/surround.vim

let g:rails_statusline=0        " Disable rails statusline, which doesn't like powerline
let g:Powerline_symbols='fancy'


runtime bundle/vim-pathogen/autoload/pathogen.vim

filetype off                    " Avoid a Vim/Pathogen bug
"execute pathogen#infect()
"execute pathogen#infect('bundle/{}', '~/.vim/bundle/{}')
call pathogen#helptags()

"execute pathogen#incubate()
"call pathogen#incubate()
call pathogen#incubate()




set nocompatible                " Don't maintain compatibility with vi

filetype plugin indent on

" Configuration
" -------------
" Looks good inverted with my set background color and readable in vimdiff
if &diff " stolen from http://stackoverflow.com/questions/2019281/load-different-colorscheme-when-using-vimdiff
  colorscheme ron
endif

  set shiftwidth=2 "number of columns to indent blocks
  set ts=2 " set normal indenting to 2 spaces
set encoding=utf-8
set t_Co=256                    " use 256 colors
set visualbell                  " Suppress audio/visual error bell
set notimeout                   " No command timeout
set showcmd                     " Show typed command prefixes while waiting for operator
  "set ttimeout              " timeout on key-codes
  "set ttimeoutlen=200       " timeout on key-codes after this many ms
set number                      " Line numbers
set ignorecase                  " Ignore case
set smartcase                   " ... unless uppercase characters are involved

set list                                     " allows showing of whitespace chars
set listchars=tab:>-,trail:-                 " prefix tabs with a > and trails with -
  set showmatch                   " Show matching brackets

set splitright                  " Add new windows towards the right
set splitbelow                  " ... and bottom
  set wildmode=list:longest,full               " list all options, match to the longest
  set wildmenu              " This is used with wildmode(full) to cycle options
  set laststatus=2          " always have status bar

set incsearch             " incremental search
set history=1024  " keep 1024 lines of history
set autowriteall                " Save when focus is lost
autocmd FocusLost * silent! wall

" Indent/unindent visual mode selection
vmap <tab>      >gv
vmap <S-tab>    <gv



" Key remappings
set pastetoggle=<F2> " Allow paste mode to be entered via <F2> key
" switch focus to next tab
map <F7> <esc>:tabp<enter>
" switch focus to prev tab
map <F8> <esc>:tabn<enter>


" insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
  set mouse=a
endif

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

" Only do this part when compiled with support for autocommands.
if has("autocmd")

  " Enable file type detection.
  " Use the default filetype settings, so that mail gets 'tw' set to 72,
  " 'cindent' is on in C files, etc.
  " Also load indent files, to automatically do language-dependent indenting.

  " Perl mason modules often have different tab stop issues
  autocmd BufRead *mi setlocal shiftwidth=4 | setlocal tabstop=4 | setlocal expandtab

 " Put these in an autocmd group, so that we can delete them easily.
  augroup vimrcEx
  au!

  " When editing a file, always jump to the last known cursor position.
  " Don't do it when the position is invalid or when inside an event handler
  " (happens when dropping a file on gvim).
  " Also don't do it when the mark is in the first line, that is the default
  " position when opening a file.
  autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

  augroup END
  augroup GPGASCII
    au!
    au BufReadPost *.gpg :%!gpg -q -d
    au BufReadPost *.gpg |redraw
    au BufWritePre *.gpg :%!gpg -q -e -a
    au BufWritePost *.gpg u
    au VimLeave *.gpg :!clear
  augroup END

endif " has("autocmd")

" Syntax Highlighting changes
au BufNewFile,BufRead *.mi set filetype=xml " Perl Mason"

"let hostname = substitute($HOSTNAME, '\..*','','')
"if hostname == "hrjones-2" || hostname == "hrjones"
"  " only stuff to be applied at work"
"endif
"if hostname == "hrjones-2"
"  " only on RHEL5"
"source /apollo/env/EnvImprovement/var/vimruntimehook
"endif
"
" --FOLLOWING STOLEN FROM VIMRC ENVIMPROVEMENT -----
"  are my equivalents that have been disabled by comment
  set autoindent            " always set autoindenting on
  set backspace=2           " allow backspacing over everything in insert mode
  "set cindent               " c code indenting, autoindent suggested over cindent http://goo.gl/qMsEu
  set autoindent    " always set autoindenting on mine
  set diffopt=filler,iwhite " keep files synced and ignore whitespace
  set expandtab             " get rid of tabs altogether and replace with spaces
  "set foldcolumn=2          " set a column incase we need it
  "set foldlevel=10           " fold MINE
  "set foldmethod=indent     " use indent unless overridden
  set nofen                 " disable folds
  set linebreak             " This displays long lines as wrapped at word boundries
  set nobackup              " Don't keep a backup file
  "set ruler                 " the ruler on the bottom is useful
  set scrolloff=5           " dont let the curser get too close to the edge MINE
  set textwidth=0           " Don't wrap words by default
  set colorcolumn=120       " set a colored column to warn about width
  set whichwrap+=<,>,[,],h,l,~                 " arrow keys can wrap in normal and insert modes
  set helpfile=$VIMRUNTIME/doc/help.txt
  set suffixes=.bak,~,.swp,.o,.info,.aux,.log,.dvi,.bbl,.blg,.brf,.cb,.ind,.idx,.ilg,.inx,.out,.toc,.class
  "set wrapmargin=80           " When pasteing, use this, because textwidth becomes 0
                               " wrapmargin inserts breaks if you exceed its value
  " LargeFile.vim settings
  " don't run syntax and other expensive things on files larger than NUM megs
  let g:LargeFile = 100
  set noswapfile              " this guy is really annoyoing sometimes
" Whitespace & highlighting & language-specific config
" ----------------------------------------------------

" Strip trailing whitespace for code files on save
" C family
autocmd BufWritePre *.m,*.h,*.c,*.mm,*.cpp,*.hpp :%s/\s\+$//e

" Ruby, Rails
autocmd BufWritePre *.rb,*.yml,*.js,*.json,*.css,*.less,*.sass,*.html,*.xml,*.erb,*.haml,*.feature :%s/\s\+$//e
au BufRead,BufNewFile *.thor set filetype=ruby
au BufRead,BufNewFile *.god set filetype=ruby
au BufRead,BufNewFile Gemfile* set filetype=ruby
au BufRead,BufNewFile Vagrantfile set filetype=ruby
au BufRead,BufNewFile soloistrc set filetype=ruby

" Java, PHP
autocmd BufWritePre *.java,*.php :%s/\s\+$//e

" Highlight JSON files as javascript
autocmd BufRead,BufNewFile *.json set filetype=javascript

" Highlight Jasmine fixture files as HTML
autocmd BufRead,BufNewFile *.jasmine_fixture set filetype=html

" Consider question/exclamation marks to be part of a Vim word.
autocmd FileType ruby set iskeyword=@,48-57,_,?,!,192-255
autocmd FileType scss set iskeyword=@,48-57,_,-,?,!,192-255

" Insert ' => '
autocmd FileType ruby imap <Space>=><Space>

" Disable 'ex' mode
map Q <Nop>

" --------------------- Maybe unnecessary

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
      \ | wincmd p | diffthis
endif
