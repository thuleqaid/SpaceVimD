let g:et#bin_plantuml = 'E:\home\.emacs.d\private\plantuml.jar'
let g:et#openwith = {'png': 'E:\PortableSoft\iview\i_view64.exe'
                  \ ,'jpg': 'E:\PortableSoft\iview\i_view64.exe'
                  \ }
let s:extlist_autofenc = ['c', 'h']
let s:extlist_disablecomplete = ['rs']

silent! exe 'source ' . expand("<sfile>:p:h") . '/et.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/ip.vim'

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

function! ListAndSelect(title, itemlist, markindex)
	let l:choices = copy(a:itemlist)
	" generate choice-list
	call map(l:choices, '"  " . (v:key + 1) . ". " . v:val')
	" insert '*' at the start of selected item
	if (a:markindex >= 0) && (a:markindex < len(a:itemlist))
		let l:choices[a:markindex] = '*' . l:choices[a:markindex][1:]
	endif
	" set list title
	call insert(l:choices, a:title)
	" ask for user choice
	let l:choice = inputlist(l:choices)
	if (l:choice < 1) || (l:choice > len(a:itemlist))
		let l:choice = 0
	endif
	echo "\n"
	return l:choice - 1
endfunction

func! s:AsyncTaskAuto() abort
    let l:tasks = asynctasks#list('')
    let l:taskcnt = len(l:tasks)
    if l:taskcnt > 0
        let l:target = ""
        if l:taskcnt == 1
            let l:target = l:tasks[0]['name']
        elseif l:taskcnt > 1
            " format choices
            let l:rows = []
            let l:i = 0
            while l:i < l:taskcnt
                call add(l:rows, [l:tasks[l:i]['name'], l:tasks[l:i]['scope'], l:tasks[l:i]['command'], l:tasks[l:i]['source']])
                let l:i = l:i + 1
            endwhile
            let l:rows = asynctasks#tabulify(l:rows)
            let l:i = 0
            let l:contents = []
            while l:i < l:taskcnt
                call add(l:contents, join(l:rows[l:i], " # "))
                let l:i = l:i + 1
            endwhile
            let l:choice = ListAndSelect("Select Task:", l:contents, 0)
            if l:choice >= 0
                let l:target = l:tasks[l:choice]['name']
            else
                echo "Abort"
            endif
        endif
        if len(l:target) > 0
            echo 'Task[' . l:target .'] is chosen'
            augroup AsyncTaskAuto
                autocmd! * <buffer>
                execute "autocmd BufWritePost <buffer> execute 'AsyncTask " . l:target . "'"
            augroup END
        endif
    else
        echo "No task found!"
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
    " ring bell after asycrun finished
    let g:asyncrun_bell = 1
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
    command! -bang -nargs=0 AsyncAuto call s:AsyncTaskAuto()
endf
