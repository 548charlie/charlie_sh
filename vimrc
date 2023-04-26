set autoindent
set autowrite
set backspace=2
set backspace=indent,eol,start
"set background=white
highlight Normal ctermfg=gray ctermbg=black
set cmdheight=1
set confirm
set cindent
set columns=80
set expandtab
set et
set foldmethod=indent
set foldlevel=3
set foldnestmax=4
set foldcolumn=3
set gdefault
set guifont=Courier_New:h8:cDEFAULT
"set guifont=courier
set helpfile=$VIMRUNTIME/doc/help.txt.gz
set hidden
set history=1000
set undolevels=1000
set wildignore=*.pyc,*.bak,*.class
set ignorecase
set incsearch
set laststatus=2
set lines=30
set list
set listchars=tab:>>
set matchpairs=(:),{:},[:],<:>
set mouse=ar
set nobackup
set noendofline
set nocompatible
set nojoinspaces
set noswapfile
set nu
set hlsearch
set ruler
set shiftwidth=4
set shortmess=o
set showbreak+=\
set showmatch
set showmode
set showcmd
set sidescroll=1
set smartcase
set smartindent
set softtabstop=4
set splitbelow
set viminfo='10
set wrap
set showcmd
set title
set tabstop=4
"set tags=/home/desas2/tags
"set dictionary=/usr/share/dict
set textwidth=0
set title
set ttyfast
set visualbell
set noerrorbells
set wmh=0
set wmw=0

"colors ron 

"matchit for html and other if and endif
"source ~/matchit.vim


" have syntax highlighting in terminals which can display colours:
if has('syntax') && (&t_Co > 2)
  syntax on
endif
syntax on
filetype on

"set the filetype detection on 
autocmd BufRead,BufNewFile *.py syntax on autocmd BufRead,BufNewFile *.py set ai 
" for C-like programming, have automatic indentation:
autocmd FileType c,cpp,slang,java set cindent

" for Perl programming, have things in braces indenting themselves:
autocmd FileType perl set smartindent

" for CSS, also have things in braces indented:
autocmd FileType css set smartindent

" for HTML, generally format text, but if a long line has been created leave it
" alone when editing:
autocmd FileType html set formatoptions+=tl

" for both CSS and HTML, use genuine tab characters for indentation, to make
" files a few bytes smaller:
autocmd FileType html,css set noexpandtab tabstop=4

" assume the /g flag on :s substitutions to replace all matches in a line:


"autocmd!
autocmd BufNewFile,BufRead *.html   set filetype=html
autocmd BufNewFile,BufRead *.pl     set filetype=pl
autocmd BufNewFile,BufRead *.java   set filetype=java
autocmd BufNewFile,BufRead *.jsp    set filetype=jsp
autocmd BufNewFile,BufRead *.cpp    set filetype=cpp
autocmd BufNewFile,BufRead *.c      set filetype=c
autocmd BufNewFile,BufRead *.tcl    set filetype=tcl
autocmd BufNewFile,BufRead *.txt set expandtab tabstop=4

if has("autocmd")
  filetype plugin on
endif "has ("autocmd")

iab dinkar Dinakar
iab mnopq mnopq@mayo.edu
"iab {} {<cr><cr>}<esc><up>i<tab>
"iab ( ( )<esc>hi

" correct my common typos without me even noticing them:
ab teh the
ab spolier spoiler
ab reslut result
ab atmoic atomic

nnoremap <F2> :browse confirm e c:\projects\tdt
nnoremap <F1> :help
"clear current search highlight
nnoremap <esc> :noh<return><esc>

"mapping the keys section
"use <Ctrl>+N/<Ctrl>+P to cycle through files:
nnoremap <C-N> :next<CR>
nnoremap <C-P> :prev<CR>
" [<Ctrl>+N by default is like j, and <Ctrl>+P like k.]

function! CurDir()
  let curdir=substitute(getcwd(), '/home/dinakar', "~/", "g")
  return curdir
endfunction
set statusline=%{strftime(\"%I:%M:%S\ \%p,\ %a\ %b\ %d,\ %Y\")}\ %F%m%r%h\ %w\ \ CWD:\ %r%{CurDir()}%h\ \ \ Line:\ %l/%L:%c


fun! ToggleFold()
  if foldlevel('.') == 0
    normal! l
  else
    if foldclosed('.') < 0
      . foldclose
    else
      . foldopen
    endif
  endif
  " Clear status line
  echo
endfun

" Map this function to Space key.
noremap <space> :call ToggleFold()<CR>


"following is HTML stuff.
"
"iab <html> <HTML><CR><HEAD><CR><TITLE><CR></TITLE><CR></HEAD><CR><BODY><CR></BODY><CR></HTML><up><up>
"iab <tbl> <table><CR><SPACE><tr><CR><SPACE><td><CR><CR></td><CR></tr><CR></table><up><up><up>
"iab <tr> <tr><CR><td><CR><CR></td><CR></tr><up><up>

iab <td> <td> </td><ESC>gE
iab <ul> <ul> <CR><CR> </ul><up>
iab <li> <li> </li><ESC>gE

function InsertTabWrapper()
  let col = col('.') - 1
  if !col || getline('.')[col - 1] !~ '\k'
    return "\<tab>"
  else
    return "\<c-p>"
  end if
endfunction

inoremap <tab> <c-r>=InsertTabWrapper()<cr>
 
"nmap section.. this section maps all keys
nmap <c-h> <c-w>h<c-w><bar>
nmap <c-l> <c-w>l<c-w><bar>
nnoremap <F3> :%s/\n/\<C-V><C-M>/g<Bar>%s/\rMSH/\rMSH/g<CR>
nnoremap <F4> :%s/\<C-V><C-M>/\r/g<CR>
inoremap ( () <Esc><Left>i
inoremap { {} <Esc><Left>i
inoremap [ [] <Esc><Left>i

