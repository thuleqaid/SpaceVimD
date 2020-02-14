let g:et#bin_plantuml = 'E:\home\.emacs.d\private\plantuml.jar'
let g:et#openwith = {'png': 'E:\PortableSoft\iview\i_view64.exe'
                  \ ,'jpg': 'E:\PortableSoft\iview\i_view64.exe'
                  \ }
let s:extlist_autofenc = ['c', 'h']
let s:extlist_disablecomplete = ['rs']

silent! exe 'source ' . expand("<sfile>:p:h") . '/et.vim'

func! HookPreload() abort
    let l:SizeLimit100k = 1024 * 100
    let l:filename = expand("<afile>")
    let l:filesize=getfsize(l:filename)
    if l:filesize>l:SizeLimit100k || l:filesize==-2
        call neocomplete#commands#_lock()
    endif
    let l:fileext = tolower(fnamemodify(l:filename, ":t:e"))
    if index(s:extlist_disablecomplete, l:fileext) >= 0
        call neocomplete#commands#_lock()
    endif
endf

func! HookPost() abort
    let l:filename = expand("<afile>")
    if filereadable(l:filename)
        let l:fileext = tolower(fnamemodify(l:filename, ":t:e"))
        if index(s:extlist_autofenc, l:fileext) >= 0
            silent! exe 'FencAutoDetect'
        endif
    endif
endf

func! myspacevim#after() abort
    " Navigation in command line
    cnoremap <C-a> <Home>
    cnoremap <C-b> <Left>
    cnoremap <C-d> <Del>
    cnoremap <C-e> <End>
    cnoremap <C-f> <Right>
    cnoremap <C-n> <Down>
    cnoremap <C-p> <Up>
    " expandtab for specified filetypes
    if has("autocmd")
        autocmd FileType python,html,rust,javascript set expandtab
    endif
    " system clipboard
    map <F5> "+y
    nmap <F6> "+p
    map! <F6> <C-r>+
    " space marks
    set list
    set listchars=tab:>-,trail:-
    " reStructuredText realtime preview
    let g:previm_enable_realtime = 0
    augroup HookPreload
    autocmd BufReadPre * call HookPreload()
    augroup END
    augroup HookPost
    autocmd BufReadPost * call HookPost()
    augroup END
    " rust
    let g:racer_cmd = exepath('racer')
    " define 'SPC j p' to jump to next placeholder of neosnippet
    call SpaceVim#mapping#space#def('nnoremap', ['j', 'p'], 'call neosnippet#view#_search_outof_range(1)', 'Jump to next placeholder of neosnippet', 1)
    " append .py to $PATHEXT
    if has('win32')
        if getenv('PATHEXT') == v:null
            call setenv('PATHEXT', '.PY') 
        else
            call setenv('PATHEXT', getenv('PATHEXT') . ';.PY') 
        endif
    endif
endf
