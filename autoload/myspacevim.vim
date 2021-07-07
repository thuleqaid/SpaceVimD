let g:et#bin_plantuml = 'E:\home\.SpaceVim.d\plantuml.jar'
let g:et#openwith = {'png': 'E:\PortableSoft\iview\i_view64.exe'
                  \ ,'jpg': 'E:\PortableSoft\iview\i_view64.exe'
                  \ }
let s:extlist_autofenc = ['c', 'h']
let s:extlist_disablecomplete = ['rs']
let s:extlist_expandtab = ['python', 'html', 'rust', 'javascript', 'vue', 'markdown', 'vim', 'c', 'cpp']

silent! exe 'source ' . expand("<sfile>:p:h") . '/common.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/et.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/ip.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/mark.vim'

func! s:HookPreload() abort
    let l:SizeLimit100k = 1024 * 100
    let l:filename = expand("<afile>")
    let l:filesize=getfsize(l:filename)
    if l:filesize>l:SizeLimit100k || l:filesize==-2
        call deoplete#custom#buffer_option('auto_complete', v:false)
    endif
    let l:fileext = tolower(fnamemodify(l:filename, ":t:e"))
    if index(s:extlist_disablecomplete, l:fileext) >= 0
        call deoplete#custom#buffer_option('auto_complete', v:false)
    endif
endf
func! s:HookPost() abort
    let l:filename = expand("<afile>")
    if filereadable(l:filename)
        let l:fileext = tolower(fnamemodify(l:filename, ":t:e"))
        if index(s:extlist_autofenc, l:fileext) >= 0
            silent! exe 'FencAutoDetect'
        endif
        if index(s:extlist_expandtab, &filetype) >= 0
            call s:autoExpandTab()
        endif
    endif
endf
func! s:autoExpandTab()
    let l:leadingTab = search("^\t","n")
    let l:leadingSpace = search("^ \\{2,\\}","n")
    if (l:leadingTab > 0) && (l:leadingSpace <= 0)
        silent! exe "setlocal noexpandtab"
    else
        silent! exe "setlocal expandtab"
    endif
endf
func! s:autoChdir()
    let l:cfile = expand("%:p")
    if l:cfile == ""
    else
        let l:childflag = 0
        let l:cwd = getcwd()
        let l:lcwd = fnamemodify(l:cfile, ":h")
        if stridx(l:lcwd, l:cwd) == 0
            while strlen(l:lcwd) > strlen(l:cwd)
                let l:lcwd = fnamemodify(l:lcwd, ":h")
            endwhile
            if l:lcwd == l:cwd
                let l:childflag = 1
            endif
        endif
        if l:childflag == 0
            let l:root = RootPath()
            if l:root == ""
                call chdir(fnamemodify(l:cfile, ":h"))
            else
                call chdir(l:root)
            endif
        endif
        if exists('b:_lvimrc_list') && exists('b:_lvimrc_status')
            let l:i = 0
            while l:i < len(b:_lvimrc_list)
                if and(b:_lvimrc_status[l:i], 0x02) > 0
                    silent! exe 'source ' . b:_lvimrc_list[l:i]
                    call _lvimrc_func_(1)
                    silent! exe 'delfunction _lvimrc_func_'
                endif
                let l:i = l:i + 1
            endwhile
        else
            let l:rootlen = strlen(getcwd())
            let l:localrc = '.lvimrc.vim'
            " find local vimrc list
            let b:_lvimrc_list = []
            let b:_lvimrc_status = []
            let l:lcwd = fnamemodify(l:cfile, ":h")
            while strlen(l:lcwd) >= l:rootlen
                let l:target = findfile(l:localrc, l:lcwd)
                if l:target == ''
                else
                    let b:_lvimrc_list = insert(b:_lvimrc_list, l:target)
                endif
                let l:lcwd = fnamemodify(l:lcwd, ":h")
            endwhile
            " source local vimrc files
            let l:i = 0
            while l:i < len(b:_lvimrc_list)
                silent! exe 'source ' . b:_lvimrc_list[l:i]
                try
                    call funcref('_lvimrc_func_')
                    let b:_lvimrc_status = insert(b:_lvimrc_status, _lvimrc_func_(0))
                    silent! exe 'delfunction _lvimrc_func_'
                catch /E700:/
                    let b:_lvimrc_status = insert(b:_lvimrc_status, 0)
                endtry
                let l:i = l:i + 1
            endwhile
        endif
    endif
endf
func! s:autoChdir_end()
    if exists('b:_lvimrc_list') && exists('b:_lvimrc_status')
        let l:i = len(b:_lvimrc_list) - 1
        while l:i >= 0
            if and(b:_lvimrc_status[l:i], 0x01) > 0
                silent! exe 'source ' . b:_lvimrc_list[l:i]
                call _lvimrc_func_(-1)
                silent! exe 'delfunction _lvimrc_func_'
            endif
            let l:i = l:i - 1
        endwhile
    endif
endf

func! TmplLocalScript()
    let l:dir = input("Target Dir: ", getcwd(), "dir")
    if l:dir == ''
        echom "No dir specified, skipped!"
    else
        let l:localrc = '.lvimrc.vim'
        let l:target = findfile(l:localrc, l:dir)
        if l:target == ''
            let l:target = fnamemodify(l:dir, ":p") . l:localrc
            let l:text = [
\ 'func! _lvimrc_func_(step)',
\ '  let l:reload = 0',
\ '  let l:unload = 0',
\ '  if a:step >= 0',
\ '    "" load step',
\ '    if a:step == 0',
\ '      "" first load',
\ '      "" Set file encoding for rg',
\ '      " let b:search_tools = {}',
\ '      " let b:search_tools.rg = ["-E", "sjis"]',
\ '      "" Make file readonly',
\ '      " if index(["c", "h"], tolower(expand("%:t:e"))) >= 0',
\ '      "   set readonly',
\ '      " endif',
\ '    else',
\ '      "" reload',
\ '    endif',
\ '  else',
\ '    "" unload step',
\ '  endif',
\ '  return l:reload * 2 + l:unload',
\ 'endf'
\ ]
            call writefile(l:text, l:target, "b")
        else
            echom l:target . " existed, skipped!"
        endif
    endif
endf
func! TmplAsyncTask()
    let l:dir = input("Target Dir: ", getcwd(), "dir")
    if l:dir == ''
        echom "No dir specified, skipped!"
    else
        let l:localrc = '.tasks'
        let l:target = findfile(l:localrc, l:dir)
        if l:target == ''
            let l:target = fnamemodify(l:dir, ":p") . l:localrc
            let l:text = [
\ '[run]',
\ 'command=python "$(VIM_FILENAME)"',
\ 'cwd=$(VIM_FILEDIR)',
\ 'output=terminal'
\ ]
            call writefile(l:text, l:target, "b")
        else
            echom l:target . " existed, skipped!"
        endif
    endif
endf

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

func! s:enableModifyTag() abort
    silent! exe 'source ' . expand("<sfile>:p:h") . '/modifytag.vim'
    call ModifyTag#mapping()
endf

function! g:BMWorkDirFileLocation()
    let filename = '/.bookmarks'
    return RootPath() . filename
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
    " space marks
    set list
    set listchars=tab:>-,trail:-
    " ring bell after asycrun finished
    let g:asyncrun_bell = 1
    " reStructuredText realtime preview
    let g:previm_enable_realtime = 0
    augroup HookPreload
    autocmd BufReadPre * call s:HookPreload()
    augroup END
    augroup HookPost
    autocmd BufReadPost * call s:HookPost()
    augroup END
    augroup BufferSwitched
    autocmd BufEnter * call s:autoChdir()
    autocmd BufLeave * call s:autoChdir_end()
    augroup END
    augroup MarkdownEmoji
    autocmd FileType markdown setlocal completefunc=emoji#complete
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
    " project root pattern
    call add(g:spacevim_project_rooter_patterns, '.root')
    " LeaderF
    let g:_spacevim_mappings.F = ['call feedkeys(":Leaderf ", "n")', 'Leaderf shortcut']
    let g:Lf_GtagsAutoGenerate = 0
    let g:Lf_Gtagslabel = 'native-pygments'
    let g:Lf_RootMarkers = ['.git', '.hg', '.svn', '.root']
    let g:_spacevim_mappings.f.g = {'name' : '+gtags'}
    noremap <leader>fgr :<C-U><C-R>=printf("Leaderf! gtags -r %s --auto-jump", expand("<cword>"))<CR><CR>
    noremap <leader>fgd :<C-U><C-R>=printf("Leaderf! gtags -d %s --auto-jump", expand("<cword>"))<CR><CR>
    noremap <leader>fgg :<C-U><C-R>=printf("Leaderf! gtags -g %s --auto-jump", expand("<cword>"))<CR><CR>
    let g:_spacevim_mappings.f.g.b = ['Leaderf gtags', 'browser']
    let g:_spacevim_mappings.f.g.n = ['Leaderf gtags --next', 'next']
    let g:_spacevim_mappings.f.g.p = ['Leaderf gtags --previous', 'previous']
    let g:_spacevim_mappings.f.g.u = ['Leaderf gtags --update', 'update']
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
    nmap <F10> :call InputRelPath()<CR>
    map! <F10> <C-o>:call InputRelPath()<CR>

    command! -bang -nargs=0 AsyncAuto call s:AsyncTaskAuto()
    command! -n=0 -bar EnableModifyTag :call s:enableModifyTag()
    command! -n=0 -rang=% -bar LvlDraw :<line1>,<line2>call LvlDraw()
endf
