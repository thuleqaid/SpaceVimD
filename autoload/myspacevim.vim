let g:et#bin_plantuml = 'E:\home\.SpaceVim.d\plantuml.jar'
let g:et#openwith = {'png': 'E:\PortableSoft\iview\i_view64.exe'
                  \ ,'jpg': 'E:\PortableSoft\iview\i_view64.exe'
                  \ }
let s:extlist_autofenc = ['c', 'h']
let s:extlist_disablecomplete = ['rs']

silent! exe 'source ' . expand("<sfile>:p:h") . '/et.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/ip.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/mark.vim'

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

func! SelectList(itemlist, markindex) abort
    call s:print_list(a:itemlist, a:markindex)
    let l:choice = s:get_choice()
    if l:choice >= len(a:itemlist)
        return 0
    else
        return l:choice
    endif
endf
func! SelectTable(table, highmap, markindex) abort
    call s:print_table(a:table, a:highmap, a:markindex)
    let l:choice = s:get_choice()
    if l:choice >= len(a:table)
        return 0
    else
        return l:choice
    endif
endf
func! s:get_choice() abort
	let l:choice = inputlist([])
	if l:choice < 1
		let l:choice = 0
	endif
	echo "\n"
	return l:choice
endf
func! s:print_list(itemlist, markindex) abort
    let l:rows = []
    let l:highmap = []
    for l:item in a:itemlist
        let l:rows += [[l:item]]
        let l:highmap += [['']]
    endfor
    call s:print_table(l:rows, l:highmap, a:markindex)
endf
func! s:print_table(rows, highmap, markindex) abort
    let l:rows = deepcopy(a:rows)
    let l:highmap = deepcopy(a:rows)
    " prepend number
    let l:i = len(l:rows) - 1
    while l:i > 0
        call insert(l:rows[l:i], '' . l:i)
        let l:i = l:i - 1
    endwhile
    call insert(l:rows[0], 'No.')
    let l:i = len(l:highmap) - 1
    while l:i > 0
        call insert(l:highmap[l:i], 'Number')
        let l:i = l:i - 1
    endwhile
    call insert(l:highmap[0], 'Title')
    let l:nrows = len(l:rows)
    let l:ncols = 0
    for l:row in l:rows
        if len(l:row) > l:ncols
            let l:ncols = len(l:row)
        endif
    endfor
    if l:nrows > 0 && l:ncols > 0
        " tabulify
        let l:content = []
        let l:xrows = []
        let l:sizes = repeat([0], l:ncols)
        let l:index = range(l:ncols)
        for l:row in l:rows
            let l:newrow = deepcopy(l:row)
            if len(l:newrow) < l:ncols
                let l:newrow += repeat([''], l:ncols - len(l:newrow))
            endif
            for l:i in l:index
                let l:size = strwidth(l:newrow[i])
                let l:sizes[l:i] = (l:sizes[l:i] < l:size)? l:size : l:sizes[i]
            endfor
            let l:xrows += [l:newrow]
        endfor
        for l:row in l:xrows
            let l:ni = []
            for l:i in l:index
                let l:x = l:row[l:i]
                let l:size = strwidth(l:x)
                if l:size < l:sizes[l:i]
                    let l:x = l:x . repeat(' ', l:sizes[i] - l:size)
                endif
                let l:ni += [l:x]
            endfor
            let l:content += [l:ni]
        endfor
        " print
        let l:index = 0
        for l:line in l:content
            let l:col = 0
            if l:index == 0
                echon " "
            else
                if l:index == a:markindex
                    echon "\n*"
                else
                    echon "\n "
                endif
            endif
            for l:cell in l:line
                exec 'echohl ' . ((l:highmap[l:index][l:col]=='')? "None" : l:highmap[l:index][l:col])
                echon cell . '  '
                let col += 1
            endfor
            let index += 1
        endfor
        echohl None
    endif
endfunc

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
            call insert(l:contents, "Select task:")
            let l:choice = SelectList(l:contents, -1)
            if l:choice > 0
                let l:target = l:tasks[l:choice - 1]['name']
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

function! g:BMWorkDirFileLocation()
    let filename = '/.bookmarks'
    return SpaceVim#plugins#projectmanager#current_root() . filename
endfunction

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
        autocmd FileType python,html,rust,javascript,markdown set expandtab
    endif
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
    call SpaceVim#mapping#space#def('nnoremap', ['j', 'p'], 'call neosnippet#view#_jump(1, 1)', 'Jump to next placeholder of neosnippet', 1)
    " append .py to $PATHEXT
    if has('win32')
        if getenv('PATHEXT') == v:null
            call setenv('PATHEXT', '.PY') 
        else
            call setenv('PATHEXT', getenv('PATHEXT') . ';.PY') 
        endif
    endif
    command! -bang -nargs=0 AsyncAuto call s:AsyncTaskAuto()
    " project root pattern
    call add(g:spacevim_project_rooter_patterns, '.root')
    " vim-bookmarks
    let g:bookmark_save_per_working_dir = 1
    let g:bookmark_auto_save = 1
    " disable default key mapping of vim-bookmarks
    let g:bookmark_no_default_key_mappings = 1
    " delete key mapping for vim-bookmarks in autoload/SpaceVim/layers/tools.vim
    silent! nunmap mm
    silent! nunmap mi
    silent! nunmap ma
    silent! nunmap mn
    silent! nunmap mp
    " set key mapping
    let g:_spacevim_mappings.m = {'name' : '+Bookmarks'}
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mm', ':BookmarkToggle<CR>', 'toggle anonymous bookmark', '', 'toggle anonymous bookmark')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mi', ':BookmarkAnnotate<CR>', 'toggle annotated bookmark', '', 'toggle annotated bookmark')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>ma', ':BookmarkShowAll<CR>', 'show bookmark', '', 'show bookmark')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mn', ':BookmarkNext<CR>', 'jump to next bookmark', '', 'jump to next bookmark')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mp', ':BookmarkPrev<CR>', 'jump to previous bookmark', '', 'jump to previous bookmark')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mc', ':BookmarkClear<CR>', 'clear current bookmarks of current file', '', 'clear current bookmarks of current file')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mx', ':BookmarkClearAll<CR>', 'clear bookmarks of all files', '', 'clear bookmarks of all files')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mv', ':echo g:BMWorkDirFileLocation()<CR>', 'show bookmark file location', '', 'show bookmark file location')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mj', ':<C-U>BookmarkMoveDown v:count<CR>', 'move current bookmark down', '', 'move current bookmark down')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mk', ':<C-U>BookmarkMoveUp v:count<CR>', 'move current bookmark up', '', 'move current bookmark up')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mg', ':<C-U>BookmarkMoveToLine v:count<CR>', 'move current bookmark to specified line', '', 'move current bookmark to specified line')
    " fix problem with command with count
    let g:_spacevim_mappings.m.j[0] = ':<C-U>BookmarkMoveDown v:count<CR>'
    let g:_spacevim_mappings.m.k[0] = ':<C-U>BookmarkMoveUp v:count<CR>'
    let g:_spacevim_mappings.m.g[0] = ':<C-U>BookmarkMoveToLine v:count<CR>'

    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mh', ':call mark#MarkCurruntWord()<CR>', 'highlight current word', '', 'highlight current word')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>me', ':call mark#MarkExpression()<CR>', 'highlight expression', '', 'highlight expression')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>md', ':call mark#DeleteHighlight()<CR>', 'delete highlight', '', 'delete highlight')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mt', ':call mark#SearchHighlight()<CR>', 'search highlight expression', '', 'search highlight expression')
    call SpaceVim#mapping#def('nnoremap <silent>', '<Leader>mu', ':call mark#ClearHighlights()<CR>', 'clear highlights', '', 'clear highlights')

    " system clipboard
    map <F5> "+y
    nmap <F6> "+p
    map! <F6> <C-r>+
    nnoremap <silent> <F4> :MundoToggle<CR>
    nmap <F7> :call et#Execute(0, 0)<CR>
    nmap <S-F7> :call et#Execute(0, 1)<CR>
    nmap <C-F7> :call et#Execute(1, 1)<CR>
    nmap <F8> :call et#OpenWith()<CR>
    nmap <F9> :call ip#moveToOtherProcess()<CR>
endf
