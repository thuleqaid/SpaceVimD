" call `ModifyTag#mapping()` after loading this script
"" Usage :
" 1. use `ModifyTagAddSource`/`ModifyTagChgSource`/`ModifyTagDelSource` when coding
" 2. use `ModifyTagTerminalCmd` to grep files in the current buffer's directory
" 3. use `ModifyTagUpdateLinesBatch` to batch update line count based on grep's result if needed
" 4. use `ModifyTagSumLines` to summarize the result
" Manual Command :
" 1. use `ModifyTagUpdateLines` to update lines of modified code in the current file
" 2. use `ModifyTagManualCount` to count selected lines
" CodeReview Command :
" 1a. use `ModifyTagOKChanges` to approve selected lines
" 1b. use `ModifyTagOKWithoutTag` to approve selected lines(the whole modify section must be selected)
" 2. use `ModifyTagNGChanges` to deny selected lines
" Static Check command
" 1. use `ModifyTagTerminalCmd` to list all changes in the current directory
" 2.a use `ModifyTagStaticCheck 0 1/0` to list loop/divide statements in the modified files
" 2.b use `ModifyTagStaticCheck 1 1/0` to list loop/divide in all the files
" 3. use `ModifyTagFilterStaticCheck` to separate loop/divide in the base or in the modifications
" Diff Modified Files
" 1. use `ModifyTagTerminalCmd` to list all changes in the current directory
" 2. use `ModifyTagSumFiles` to summarize modified files
" 3. set base soft dir in the empty line between g:mt_tag_diff_tag1 and g:mt_tag_diff_tag2
"    set output html dir in the empty line between g:mt_tag_diff_tag3 and g:mt_tag_diff_tag4
"      Default Value for g:mt_tag_diff_tag1 ~ g:mt_tag_diff_tag4
"        g:mt_tag_diff_tag1 = "#1 Base Source Dir:"
"        g:mt_tag_diff_tag2 = "#2 New Source Dir:"
"        g:mt_tag_diff_tag3 = "#3 Output Html Dir:"
"        g:mt_tag_diff_tag4 = "#4 FileList:"
" 4. use `ModifyTagDiffFiles` to generate vim script for diff files
" 5. use :so % to run the generated vim script
"" key-binding
"nmap <Leader>ta :ModifyTagAddSource<CR>
"vmap <Leader>ta :ModifyTagAddSource<CR>
"vmap <Leader>tc :ModifyTagChgSource<CR>
"vmap <Leader>td :ModifyTagDelSource<CR>
"nmap <Leader>tu :ModifyTagUpdateLines<CR>
"vmap <Leader>tm :ModifyTagManualCount<CR>
"nmap <Leader>ts :ModifyTagSumLines<CR>
"nmap <Leader>tt :ModifyTagTerminalCmd<CR>
"nmap <Leader>to :ModifyTagOKChanges<CR>
"vmap <Leader>to :ModifyTagOKChanges<CR>
"vmap <Leader>tO :ModifyTagOKWithoutTag<CR>
"nmap <Leader>tn :ModifyTagNGChanges<CR>
"vmap <Leader>tn :ModifyTagNGChanges<CR>
"nmap <Leader>tb :ModifyTagUpdateLinesBatch<CR>
"nmap <Leader>tl :ModifyTagStaticCheck 0 1<CR>
"nmap <Leader>tz :ModifyTagStaticCheck 0 0<CR>
"nmap <Leader>tL :ModifyTagStaticCheck 1 1<CR>
"nmap <Leader>tZ :ModifyTagStaticCheck 1 0<CR>
"nmap <Leader>tf :ModifyTagFilterStaticCheck<CR>
"nmap <Leader>tS :ModifyTagSumFiles<CR>
"nmap <Leader>tD :ModifyTagDiffFiles<CR>
"" Known bugs:
" 1. call `ModifyTagAddSource` when selecting one line would be mis-recognized as selecting none

" [Start]load external config file
let b:config = {}
let s:config_file = '/.modifytag'
let s:config_cache = '/.modifytag_cache'
let s:TOML = SpaceVim#api#import('data#toml')
let s:JSON = SpaceVim#api#import('data#json')
let s:template = [
            \ "[options]",
            \ "user = 'Anonymous'",
            \ "codes = ['sample key 1']",
            \ "show_reason = 1 # 0: without reason line, 1: with reason line",
            \ "reasons = ['No.1', 'No.2']",
            \ "remove_mode = 2",
            \ "# <Original Source>    | Nothing              | NoTag(remove_mode:0) | NoTag(remove_mode:1) | NoTag(remove_mode:2) | NoTag(remove_mode:3) |",
            \ "# /* tag_start */      |                      |                      |                      |                      |                      |",
            \ "# /* keyword line */   |                      |                      |                      |                      |                      |",
            \ "# /* reason line */    |                      |                      | /* reason line */    | /* reason line sta */| /* reason line sta */|",
            \ "# #if 0                |                      | #if 0                | #if 0                | #if 0                |                      |",
            \ "#   old source         |                      |   old source         |   old source         |   old source         |                      |",
            \ "# #else                |                      | #else                | #else                | #else                |                      |",
            \ "#   new source         |   new source         |   new source         |   new source         |   new source         |   new source         |",
            \ "# #endif               |                      | #endif               | #endif               | #endif               |                      |",
            \ "# /* tag_end */        |                      |                      |                      | /* reason line end */| /* reason line end */|",
            \ "",
            \ "[tag]",
            \ "tag_timef = '%Y/%m/%d'",
            \ "tag_mode = 1 # 0: [#if] for chg and del, 1:[#if] for add, chg and del",
            \ "tag_co = '' # compile option, valid only if tag_mode == 1",
            \ "tag_const_true = '1' # valid only if tag_co == ''",
            \ "tag_const_false = '0'# valid only if tag_co == ''",
            \ "tag_start = '/*$$$$$$$$$$$$$$$$$CorrectStart$$$$$$$$$$$$$$$$$$*/'",
            \ "tag_end = '/*$$$$$$$$$$$$$$$$$$CorrectEnd$$$$$$$$$$$$$$$$$$$*/'",
            \ "tag_sep = ','",
            \ "cmt_start = '/*$ '",
            \ "cmt_end = ' $*/'",
            \ "rm_prefix = '' # prefix that will be added at the beginning of every deleted line",
            \ "",
            \ "[diff]",
            \ "grep_engine = 0 # 0:internal vimgrep 1:external grep program",
            \ "filepattern_0 = '*.{c,cxx,cpp,h,hxx,hpp}' # filepattern for grep_engine == 0",
            \ "filepattern_1 = '*.c;*.cxx;*.cpp;*.h;*.hxx;*.hpp' # filepattern for grep_engine == 1",
            \ "diffall = 1",
            \ "tag1 = '#1 Base Source Dir:'",
            \ "tag2 = '#2 New Source Dir:'",
            \ "tag3 = '#3 Output Html Dir:'",
            \ "tag4 = '#4 FileList:'",
            \ "tag5 = '#5 Finished'" ]
func! s:loadConfig() abort
    let l:local_conf = SpaceVim#plugins#projectmanager#current_root() . s:config_file
    if filereadable(l:local_conf)
        " config file exists
        let l:local_cache = SpaceVim#plugins#projectmanager#current_root() . s:config_cache
        if filereadable(l:local_cache)
            " cache file exists
            if getftime(l:local_conf) < getftime(l:local_cache)
                let l:loaded = getbufvar('%', 'config_loaded', 0)
                if l:loaded <= 0
                    " first time load config
                    let b:config = s:JSON.json_decode(join(readfile(l:local_cache, ''), ''))
                    call setbufvar('%', 'config_loaded', 1)
                endif
            else
                " config file modified
                let b:config = s:TOML.parse_file(l:local_conf)
                call writefile([s:JSON.json_encode(b:config)], l:local_cache)
                call setbufvar('%', 'config_loaded', 1)
            endif
        else
            " first time loading config
            let b:config = s:TOML.parse_file(l:local_conf)
            call writefile([s:JSON.json_encode(b:config)], l:local_cache)
            call setbufvar('%', 'config_loaded', 1)
        endif
    else
        " create an example config file
        call writefile(s:template, l:local_conf)
        call setbufvar('%', 'config_loaded', 0)
        throw "Please update config file[" . l:local_conf . "] found."
    endif
endf
" [End]load external config file

let s:rg = exepath('rg')
func! ModifyTag#mapping() abort
    command! -n=0 -rang -bar ModifyTagAddSource :call s:ModifyTag('add',<line1>,<line2>)
    command! -n=0 -rang -bar ModifyTagChgSource :call s:ModifyTag('chg',<line1>,<line2>)
    command! -n=0 -rang -bar ModifyTagDelSource :call s:ModifyTag('del',<line1>,<line2>)
    command! -n=0 -bar ModifyTagUpdateLines :call s:CalculateModifiedLines()
    command! -n=0 -rang=% -bar ModifyTagManualCount :<line1>,<line2>call s:CountLines()
    command! -n=0 -bar ModifyTagTerminalCmd :call s:SearchCurrentDirectory()
    command! -n=0 -bar ModifyTagUpdateLinesBatch :call s:CalculateModifiedLinesBatch()
    command! -n=0 -bar ModifyTagUpdateLinesAndClose :call s:CalculateModifiedLinesAndClose()
    command! -n=0 -bar ModifyTagSumLines :call s:SumModifiedLines()
    command! -n=0 -rang -bar ModifyTagOKChanges :<line1>,<line2>call s:ApproveChanges()
    command! -n=0 -rang -bar ModifyTagOKWithoutTag :<line1>,<line2>call s:RemoveTag()
    command! -n=0 -rang -bar ModifyTagNGChanges :<line1>,<line2>call s:DenyChanges()
    command! -n=+ -bar ModifyTagStaticCheck :call s:StaticCheck(<f-args>)
    command! -n=+ -bar ModifyTagListStaticCheck :call s:ListStaticCheck(<f-args>)
    command! -n=0 -bar ModifyTagFilterStaticCheck :call s:FilterStaticCheck()
    command! -n=+ -bar ModifyTagDiff2Html :call s:Diff2Html(<f-args>)
    command! -n=0 -bar ModifyTagSumFiles :call s:SumModifiedFiles()
    command! -n=0 -bar ModifyTagDiffFiles :call s:MakeVimScript()
    call s:mapping_key()
endf
func! s:mapping_key() abort
    let g:_spacevim_mappings.T = {'name' : '+ModifyTag'}
    call SpaceVim#mapping#def('nmap', '<Leader>Ta', ':ModifyTagAddSource<CR>', 'add code', '', 'add code')
    call SpaceVim#mapping#def('vmap', '<Leader>Ta', ':ModifyTagAddSource<CR>', 'add code', '', 'add code')
    call SpaceVim#mapping#def('vmap', '<Leader>Tc', ':ModifyTagChgSource<CR>', 'change code', '', 'change code')
    call SpaceVim#mapping#def('vmap', '<Leader>Td', ':ModifyTagDelSource<CR>', 'delete code', '', 'delete code')
    call SpaceVim#mapping#def('nmap', '<Leader>Tu', ':ModifyTagUpdateLines<CR>', 'update lines info', '', 'update lines info')
    call SpaceVim#mapping#def('vmap', '<Leader>Tm', ':ModifyTagManualCount<CR>', 'count lines info', '', 'count lines info')
    call SpaceVim#mapping#def('nmap', '<Leader>Ts', ':ModifyTagSumLines<CR>', 'summary lines info', '', 'summary lines info')
    call SpaceVim#mapping#def('nmap', '<Leader>Tt', ':ModifyTagTerminalCmd<CR>', 'search modification list', '', 'search modification list')
    call SpaceVim#mapping#def('nmap', '<Leader>To', ':ModifyTagOKChanges<CR>', 'approve changes', '', 'approve changes')
    call SpaceVim#mapping#def('vmap', '<Leader>To', ':ModifyTagOKChanges<CR>', 'approve changes', '', 'approve changes')
    call SpaceVim#mapping#def('vmap', '<Leader>TO', ':ModifyTagOKWithoutTag<CR>', 'approve changes with tag reformatting', '', 'approve changes with tag reformatting')
    call SpaceVim#mapping#def('nmap', '<Leader>Tn', ':ModifyTagNGChanges<CR>', 'deny changes', '', 'deny changes')
    call SpaceVim#mapping#def('vmap', '<Leader>Tn', ':ModifyTagNGChanges<CR>', 'deny changes', '', 'deny changes')
    call SpaceVim#mapping#def('nmap', '<Leader>Tb', ':ModifyTagUpdateLinesBatch<CR>', 'batch update lines info', '', 'batch update lines info')
    call SpaceVim#mapping#def('nmap', '<Leader>Tl', ':ModifyTagStaticCheck 0 1<CR>', 'loop check', '', 'loop check')
    call SpaceVim#mapping#def('nmap', '<Leader>Tz', ':ModifyTagStaticCheck 0 0<CR>', 'divide check', '', 'divide check')
    call SpaceVim#mapping#def('nmap', '<Leader>TL', ':ModifyTagStaticCheck 1 1<CR>', 'batch loop check', '', 'batch loop check')
    call SpaceVim#mapping#def('nmap', '<Leader>TZ', ':ModifyTagStaticCheck 1 0<CR>', 'batch divide check', '', 'batch divide check')
    call SpaceVim#mapping#def('nmap', '<Leader>Tf', ':ModifyTagFilterStaticCheck<CR>', 'filter static checks', '', 'filter static checks')
    call SpaceVim#mapping#def('nmap', '<Leader>TS', ':ModifyTagSumFiles<CR>', 'summary files info', '', 'summary files info')
    call SpaceVim#mapping#def('nmap', '<Leader>TD', ':ModifyTagDiffFiles<CR>', 'diff files', '', 'diff files')
endf

let s:ptn_escape = '/*[]()'
" Part 1: Add modify tag
func! s:ModifyTag(type, startlineno, endlineno)
    call s:loadConfig()
    " start part
    let l:curlineno = a:startlineno - 1
    call append(l:curlineno, s:constructStartLine())
    let l:curlineno += 1
    call append(l:curlineno, s:constructKeywordLine(a:type))
    let l:curlineno += 1
    if b:config['options']['show_reason'] > 0
        call append(l:curlineno, s:constructReasonLine())
        let l:curlineno += 1
    endif
    let l:ifelend = s:constructIfLine(a:type)
    if l:ifelend != ''
        call append(l:curlineno, l:ifelend)
        let l:curlineno += 1
    endif
    " middle part
    if a:type == 'add'
        if a:endlineno - a:startlineno > 0
            " multilines are selected
            let l:curlineno = l:curlineno + a:endlineno - a:startlineno + 1
        else
            " add an empty line
            call append(l:curlineno, '')
            let l:curlineno += 1
        endif
        let l:poslineno = l:curlineno
    elseif a:type == 'chg'
        " skip select lines
        call s:encodeDeleteBlock(l:curlineno + 1, l:curlineno + a:endlineno - a:startlineno + 1)
        let l:curlineno = l:curlineno + a:endlineno - a:startlineno + 1
        " add #else
        let l:ifelend = s:constructElseLine(a:type)
        if l:ifelend != ''
            call append(l:curlineno, l:ifelend)
            let l:curlineno += 1
        endif
        " add an empty line
        call append(l:curlineno, '')
        let l:curlineno += 1
        let l:poslineno = l:curlineno
    elseif a:type == 'del'
        " skip select lines
        call s:encodeDeleteBlock(l:curlineno + 1, l:curlineno + a:endlineno - a:startlineno + 1)
        let l:curlineno = l:curlineno + a:endlineno - a:startlineno + 1
        let l:poslineno = l:curlineno
    endif
    " end part
    let l:ifelend = s:constructEndifLine(a:type)
    if l:ifelend != ''
        call append(l:curlineno, l:ifelend)
        let l:curlineno += 1
    endif
    call append(l:curlineno, s:constructEndLine())
    call cursor(l:poslineno, 0)
endf
" Part 2: Count lines
func! s:CalculateModifiedLines()
    call s:loadConfig()
    let l:cntlist = s:countList()
    " modify source lines
    let l:i = 0
    while l:i < len(l:cntlist)
        let l:type  = l:cntlist[l:i]
        let l:line0 = l:cntlist[l:i+1]
        let l:line1 = l:cntlist[l:i+2]
        let l:line2 = l:cntlist[l:i+3]
        let l:i     = l:i + 4
        if l:type == 'add'
            let l:rep = 'ADD[' . l:line1 . ']_[' . l:line2 . ']'
            let l:res = substitute(getline(l:line0), '\CADD\[\d*\]_\[\d*\]', l:rep, "")
            call setline(l:line0, l:res)
        elseif l:type == 'chg'
            let l:line3 = l:cntlist[l:i]
            let l:line4 = l:cntlist[l:i+1]
            let l:i     = l:i + 2
            let l:rep   = 'CHG[' . l:line1 . ']_[' . l:line2 . '] -> [' . l:line3 . ']_[' . l:line4 . ']'
            let l:res = substitute(getline(l:line0), '\CCHG\[\d*\]_\[\d*\] -> \[\d*\]_\[\d*\]', l:rep, "")
            call setline(l:line0, l:res)
        elseif l:type == 'del'
            let l:rep = 'DEL[' . l:line1 . ']_[' . l:line2 . ']'
            let l:res = substitute(getline(l:line0), '\CDEL\[\d*\]_\[\d*\]', l:rep, "")
            call setline(l:line0, l:res)
        endif
    endwhile
endf
func! s:CountLines() range
    call s:loadConfig()
    let l:cnt = s:countSourceLines(a:firstline, a:lastline)
    call cursor(a:lastline, 1)
    echo l:cnt
endf
" Part 3: Summary modifications
func! s:SearchCurrentDirectory()
    call s:loadConfig()
    let l:keyword  = escape(s:constructKeyword(), s:ptn_escape)
    if b:config['diff']['grep_engine'] == 0
        let l:command  = "vimgrep /" . l:keyword . "/j " . expand("%:p:h:gs?\\?/?") . '/**/' . b:config['diff']['filepattern_0']
        silent! exe l:command
        silent! exe "cwindow"
    else
        let l:qflist = []
        let l:command  = s:rg . ' --vimgrep -e "' . l:keyword . '" -g ' . join(split(b:config['diff']['filepattern_1'],';'), ' -g ') . ' ' . s:rootpath()
        let l:result = system(l:command)
        for l:text in split(l:result, nr2char(10))
            let l:pos1  = match(l:text, ':\d\+:\d\+:')
            let l:pos2  = stridx(l:text, ':', l:pos1 + 1)
            let l:pos3  = stridx(l:text, ':', l:pos2 + 1)
            call add(l:qflist, {'filename':strpart(l:text, 0, l:pos1), 'lnum':str2nr(strpart(l:text, l:pos1 + 1, l:pos2 - l:pos1 - 1)), 'col':str2nr(strpart(l:text, l:pos2 + 1, l:pos3 - l:pos2 - 1)), 'text':strpart(l:text, l:pos3 + 1)})
        endfor
        "" code for using find and grep
        "" filepattern: .*\\.\\(c\\|cxx\\|cpp\\|h\\|hxx\\|hpp\\)
        " let l:command  = "find " . expand("%:p:h:gs?\\?/?") . " -iregex '" . b:config['diff']['filepattern_1'] . "' | xargs grep -Hn '" . l:keyword . "'"
        " let l:result = system(l:command)
        " for l:text in split(l:result,'\n')
        "     let l:pos1  = stridx(l:text, ':')
        "     let l:pos2  = stridx(l:text, ':', l:pos1 + 1)
        "     call add(l:qflist, {'filename':strpart(l:text, 0, l:pos1), 'lnum':str2nr(strpart(l:text, l:pos1 + 1, l:pos2 - l:pos1 - 1)), 'col':1, 'text':strpart(l:text, l:pos2 + 1)})
        " endfor
        call setqflist(l:qflist)
        silent! exe "cwindow"
    endif
endf
func! s:CalculateModifiedLinesBatch()
    call s:loadConfig()
    silent! exe "cclose"
    let l:filelist = s:fileList(1)
    for l:curfile in l:filelist
        silent! exe "edit +ModifyTagUpdateLinesAndClose ". l:curfile
    endfor
    call s:SearchCurrentDirectory()
endf
func! s:CalculateModifiedLinesAndClose()
    call s:loadConfig()
    silent! exe "FencAutoDetect"
    call s:CalculateModifiedLines()
    silent! exe "write"
    call s:closebuffer()
endf
func! s:SumModifiedLines()
    call s:loadConfig()
    let l:total1   = 0
    let l:total2   = 0
    let l:total3   = 0
    let l:total4   = 0
    let l:total5   = 0
    let l:total6   = 0
    let l:total7   = 0
    let l:total8   = 0
    call append(line('$'), expand("%:p:h:gs?\\?/?"))
    call append(line('$'), "File\tLineNo\tADD_Total\tADD_Code\tCHG_Total_Old\tCHG_Code_Old\tCHG_Total_New\tCHG_Code_New\tDEL_Total\tDEL_Code\tDate\tAuthor")
    for l:item in getqflist()
        let l:curlines = s:splitKeywordLine(l:item.text)
        if len(l:curlines) > 0
            let l:text = bufname(l:item.bufnr) . "\t" . l:item.lnum . "\t" . join(l:curlines, "\t")
            let l:total1 = l:total1 + str2nr(l:curlines[0])
            let l:total2 = l:total2 + str2nr(l:curlines[1])
            let l:total3 = l:total3 + str2nr(l:curlines[2])
            let l:total4 = l:total4 + str2nr(l:curlines[3])
            let l:total5 = l:total5 + str2nr(l:curlines[4])
            let l:total6 = l:total6 + str2nr(l:curlines[5])
            let l:total7 = l:total7 + str2nr(l:curlines[6])
            let l:total8 = l:total8 + str2nr(l:curlines[7])
            call append(line('$'), l:text)
        endif
    endfor
    call append(line('$'), "Total\t\t" . l:total1 . "\t" . l:total2 . "\t" . l:total3 . "\t" . l:total4 . "\t" . l:total5 . "\t" . l:total6 . "\t" . l:total7 . "\t" . l:total8)
endf
" Part 4: Code review
func! s:RemoveTag() range
    call s:loadConfig()
    let l:pos = s:tellPos(a:firstline, a:lastline)
    let l:i   = len(l:pos) - 5
    if b:config['options']['show_reason'] > 0
        let l:headlines = 3
        let l:rmode     = b:config['options']['remove_mode']
    else
        let l:headlines = 2
        let l:rmode     = 0
    endif
    while l:i >= 0
        let l:type  = l:pos[l:i]
        let l:line1 = l:pos[l:i+1]
        let l:line2 = l:pos[l:i+2]
        let l:line3 = l:pos[l:i+3]
        let l:line4 = l:pos[l:i+4]
        let l:i     = l:i - 5
        if (l:line1 + 2 + b:config['options']['show_reason'] >= l:line3) && (l:line4 + 1 >= l:line2)
            " full modify section must be selected
            if l:rmode == 0
                " remove reason line
                silent exe 'normal ' . l:line2 . 'Gdd' . l:line1 . 'G' . l:headlines . 'dd'
            elseif l:rmode == 1
                " hold reason line
                silent exe 'normal ' . l:line2 . 'Gdd' . l:line1 . 'G2dd'
            elseif l:rmode == 2
                " hold reason line and append reason line at the end of section
                let l:reason0 = getline(l:line1 + 2)
                let l:reason1 = strpart(l:reason0, 0, len(l:reason0) - len(b:config['tag']['cmt_end']))
                if l:type == 'add'
                    let l:reason2 = l:reason1 . '-ADD-END' . b:config['tag']['cmt_end']
                    let l:reason1 = l:reason1 . '-ADD-BEGIN' . b:config['tag']['cmt_end']
                elseif l:type == 'chg'
                    let l:reason2 = l:reason1 . '-MODIFY-END' . b:config['tag']['cmt_end']
                    let l:reason1 = l:reason1 . '-MODIFY-BEGIN' . b:config['tag']['cmt_end']
                elseif l:type == 'del'
                    let l:reason2 = l:reason1 . '-DELETE-END' . b:config['tag']['cmt_end']
                    let l:reason1 = l:reason1 . '-DELETE-BEGIN' . b:config['tag']['cmt_end']
                endif
                call setline(l:line1 + 2, l:reason1)
                call setline(l:line2, l:reason2)
                silent exe 'normal ' . l:line1 . 'G2dd'
            elseif l:rmode == 3
                " hold reason line ,append reason line at the end of section, remove invalid code
                let l:reason0 = getline(l:line1 + 2)
                let l:reason1 = strpart(l:reason0, 0, len(l:reason0) - len(b:config['tag']['cmt_end']))
                if l:type == 'add'
                    let l:reason2 = l:reason1 . '-ADD-END' . b:config['tag']['cmt_end']
                    let l:reason1 = l:reason1 . '-ADD-BEGIN' . b:config['tag']['cmt_end']
                    call setline(l:line1 + 2, l:reason1)
                    call setline(l:line2, l:reason2)
                    silent exe 'normal ' . l:line1 . 'G2dd'
                elseif l:type == 'chg'
                    let l:reason2 = l:reason1 . '-MODIFY-END' . b:config['tag']['cmt_end']
                    let l:reason1 = l:reason1 . '-MODIFY-BEGIN' . b:config['tag']['cmt_end']
                    call cursor(l:line1+3, 1)
                    let l:midline = searchpair('#if','#else','#endif')
                    if (l:midline > l:line1 + 3) && (l:midline < l:line2 - 1)
                        call setline(l:midline, l:reason1)
                        call setline(l:line2 - 1, l:reason2)
                        silent exe 'normal ' . l:line2 . 'Gdd' . l:line1 . 'G' . (l:midline - l:line1) . 'dd'
                    endif
                elseif l:type == 'del'
                    silent exe 'normal ' . l:line1 . 'G' . (l:line2 - l:line1 + 1) . 'dd'
                endif
            endif
        endif
    endwhile
endf
func! s:ApproveChanges() range
    call s:loadConfig()
    let l:pos = s:tellPos(a:firstline, a:lastline)
    let l:i   = len(l:pos) - 5
    while l:i >= 0
        let l:type  = l:pos[l:i]
        let l:line1 = l:pos[l:i+1]
        let l:line2 = l:pos[l:i+2]
        let l:line3 = l:pos[l:i+3]
        let l:line4 = l:pos[l:i+4]
        let l:i     = l:i - 5
        if l:type == 'add'
            call s:approveAddBlock(l:line1, l:line2, l:line3, l:line4)
        elseif l:type == 'chg'
            call s:approveChgBlock(l:line1, l:line2, l:line3, l:line4)
        elseif l:type == 'del'
            call s:approveDelBlock(l:line1, l:line2, l:line3, l:line4)
        endif
    endwhile
endf
func! s:DenyChanges() range
    call s:loadConfig()
    let l:pos = s:tellPos(a:firstline, a:lastline)
    let l:i   = len(l:pos) - 5
    while l:i >= 0
        let l:type  = l:pos[l:i]
        let l:line1 = l:pos[l:i+1]
        let l:line2 = l:pos[l:i+2]
        let l:line3 = l:pos[l:i+3]
        let l:line4 = l:pos[l:i+4]
        let l:i     = l:i - 5
        if l:type == 'add'
            call s:denyAddBlock(l:line1, l:line2, l:line3, l:line4)
        elseif l:type == 'chg'
            call s:denyChgBlock(l:line1, l:line2, l:line3, l:line4)
        elseif l:type == 'del'
            call s:denyDelBlock(l:line1, l:line2, l:line3, l:line4)
        endif
    endwhile
endf
" Part 5: Static check
func! s:FilterStaticCheck()
    call s:loadConfig()
    let l:linerange = {}
    for l:item in getqflist()
        let l:curlines = s:splitKeywordLine(l:item.text)
        if len(l:curlines) > 0
            let l:fname = bufname(l:item.bufnr)
            if has_key(l:linerange, l:fname) < 1
                call extend(l:linerange, {l:fname : []})
            endif
            let l:total1 = str2nr(l:curlines[0])
            let l:total2 = str2nr(l:curlines[2])
            let l:total3 = str2nr(l:curlines[4])
            let l:total4 = str2nr(l:curlines[6])
            if l:total1 > 0
                let l:pos = l:total1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode'] * 2
            elseif l:total2 > 0
                let l:pos = l:total2 + l:total3 + 5 + b:config['options']['show_reason']
            elseif l:total4 > 0
                let l:pos = l:total4 + 4 + b:config['options']['show_reason']
            endif
            call extend(l:linerange[l:fname], [l:item.lnum - 1, l:item.lnum - 1 + l:pos])
        endif
    endfor
    let l:pos = 1
    while l:pos <= line('$')
        let l:linetext = getline(l:pos)
        let l:parts = split(l:linetext, "\t")
        if len(l:parts) > 2
            if has_key(l:linerange, l:parts[0]) < 1
                call setline(l:pos, "-1\t" . l:linetext)
            else
                let l:idx = 0
                let l:lineno = str2nr(l:parts[1])
                while l:idx < len(l:linerange[l:parts[0]])
                    if (l:lineno >= l:linerange[l:parts[0]][l:idx]) && (l:lineno <= l:linerange[l:parts[0]][l:idx + 1])
                        break
                    endif
                    let l:idx = l:idx + 2
                endwhile
                if l:idx < len(l:linerange[l:parts[0]])
                    call setline(l:pos, "1\t" . l:linetext)
                else
                    call setline(l:pos, "0\t" . l:linetext)
                endif
            endif
        endif
        let l:pos = l:pos + 1
    endwhile
endf
func! s:StaticCheck(allfiles, loopcheck)
    call s:loadConfig()
    if a:allfiles == 1
        let l:filelist = s:fileList(0)
    else
        let l:filelist = s:fileList(1)
    endif
    if a:loopcheck == 1
        let l:cmd = "edit +ModifyTagListStaticCheck\\ 1\\ " . bufnr("") . " "
    else
        let l:cmd = "edit +ModifyTagListStaticCheck\\ 0\\ " . bufnr("") . " "
    endif
    for l:curfile in l:filelist
        silent! exe  l:cmd . l:curfile
    endfor
endf
" Part 6: Diff modified files
func! s:SumModifiedFiles()
    call s:loadConfig()
    call append(line('$'), b:config['diff']['tag1'])
    call append(line('$'), "")
    call append(line('$'), b:config['diff']['tag2'])
    call append(line('$'), expand("%:p:h:gs?\\?/?"))
    call append(line('$'), b:config['diff']['tag3'])
    call append(line('$'), "")
    call append(line('$'), b:config['diff']['tag4'])
    let l:lasttext = ''
    for l:item in getqflist()
        let l:text = bufname(l:item.bufnr)
        if l:lasttext != l:text
            call append(line('$'), l:text)
            let l:lasttext = l:text
        endif
    endfor
    call append(line('$'), b:config['diff']['tag5'])
endf
func! s:MakeVimScript()
    call s:loadConfig()
    silent! exe "normal gg"
    let l:lineno1   = search(b:config['diff']['tag1'])
    let l:lineno2   = search(b:config['diff']['tag2'])
    let l:lineno3   = search(b:config['diff']['tag3'])
    let l:lineno4   = search(b:config['diff']['tag4'])
    if b:config['diff']['tag5'] == ''
        let l:lineno5   = line('$')
    else
        let l:lineno5   = search(b:config['diff']['tag5']) - 1
    endif
    if (l:lineno1 > 0) && (l:lineno2 == l:lineno1+2) && (l:lineno3 == l:lineno2+2) && (l:lineno4 == l:lineno3+2) && (l:lineno5 > l:lineno4)
        let l:dir1 = fnamemodify(getline(l:lineno1+1), ':p:gs?\\?/?')
        let l:dir2 = fnamemodify(getline(l:lineno2+1), ':p:gs?\\?/?')
        let l:dir3 = fnamemodify(getline(l:lineno3+1), ':p:gs?\\?/?')
        let l:lineno1   = line('$')
        while l:lineno4 < lineno5
            let l:lineno4 = l:lineno4 + 1
            let l:curfile = fnamemodify(getline(l:lineno4), ':gs?\\?/?')
            call append(line('$'), ':ModifyTagDiff2Html ' . l:dir1 . l:curfile . ' ' . l:dir2 . l:curfile . ' ' . l:dir3 . l:curfile . '.html')
        endwhile
        silent! exe "normal gg" . l:lineno1 . "dd"
    else
        echo "Information loss or Tag missing\n" . l:lineno1 . "\t" . l:lineno2 . "\t" . l:lineno3 . "\t" . l:lineno4 . "\t" . l:lineno5
    endif
endf
func! s:Diff2Html(oldfile, newfile, outfile)
    call s:loadConfig()
    silent! exe 'e ' . a:newfile
    silent! exe 'diffthis'
    silent! exe 'vsplit ' . a:oldfile
    silent! exe 'diffthis'
    if b:config['diff']['diffall'] > 0
        silent! exe 'normal zR'
    endif
    silent! exe 'TOhtml'
    silent! exe 'only'
    silent! exe 'buf Diff.html'
    call s:createPath(a:outfile)
    silent! exe 'w ' . a:outfile
    silent! exe 'bd ' . a:oldfile
    silent! exe 'bd ' . a:oldfile . '.html'
    silent! exe 'bd ' . a:newfile
    silent! exe 'bd ' . a:newfile . '.html'
    silent! exe 'bd! Diff.html'
endf
" Part N: Inner function
func! s:_(txt)
    return a:txt
endf
func! s:constructStartLine()
    let l:output = b:config['tag']['tag_start']
    return l:output
endf
func! s:constructEndLine()
    let l:output = b:config['tag']['tag_end']
    return l:output
endf
func! s:constructKeyword()
    let l:output = '[' . join(b:config['options']['codes'], '][') .']'
    return l:output
endf
func! s:constructKeywordLine(type)
    if a:type == 'add'
        let l:addtag = 'ADD[]_[]'
    elseif a:type == 'chg'
        let l:addtag = 'CHG[]_[] -> []_[]'
    elseif a:type == 'del'
        let l:addtag = 'DEL[]_[]'
    endif
    let l:curtime = strftime(b:config['tag']['tag_timef'])
    let l:output = b:config['tag']['cmt_start'] . l:addtag . b:config['tag']['tag_sep'] . s:constructKeyword() . b:config['tag']['tag_sep'] . l:curtime . b:config['tag']['tag_sep'] . s:_(b:config['options']['user']) . b:config['tag']['cmt_end']
    return l:output
endf
func! s:constructReasonLine()
    let l:rlist = map(copy(b:config['options']['reasons']), 's:_(v:val)')
    call insert(l:rlist, 'Reason')
    let l:choice = SelectList(l:rlist, -1)
    if l:choice <= 0
        let l:msg = ''
        while l:msg =~ '^\s*$'
            let l:msg    = input('Input Reason: ', '')
        endwhile
    else
        let l:msg    = l:rlist[l:choice]
    endif
    let l:output = b:config['tag']['cmt_start'] . l:msg . b:config['tag']['cmt_end']
    return l:output
endf
func! s:constructIfLine(type)
    if a:type == 'add'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#if ' . b:config['tag']['tag_const_true']
            else
                let l:addtag = '#ifndef ' . b:config['tag']['tag_co']
            endif
        else
            let l:addtag = ''
        endif
    elseif a:type == 'chg'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#if ' . b:config['tag']['tag_const_false']
            else
                let l:addtag = '#ifdef ' . b:config['tag']['tag_co']
            endif
        else
            let l:addtag = '#if ' . b:config['tag']['tag_const_false']
        endif
    elseif a:type == 'del'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#if ' . b:config['tag']['tag_const_false']
            else
                let l:addtag = '#ifdef ' . b:config['tag']['tag_co']
            endif
        else
            let l:addtag = '#if ' . b:config['tag']['tag_const_false']
        endif
    endif
    return l:addtag
endf
func! s:constructElseLine(type)
    if a:type == 'add'
        let l:addtag = ''
    elseif a:type == 'chg'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#else'
            else
                let l:addtag = '#else /* ' . b:config['tag']['tag_co'] . ' */'
            endif
        else
            let l:addtag = '#else'
        endif
    elseif a:type == 'del'
        let l:addtag = ''
    endif
    return l:addtag
endf
func! s:constructEndifLine(type)
    if a:type == 'add'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#endif'
            else
                let l:addtag = '#endif /* ' . b:config['tag']['tag_co'] . ' */'
            endif
        else
            let l:addtag = ''
        endif
    elseif a:type == 'chg'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#endif'
            else
                let l:addtag = '#endif /* ' . b:config['tag']['tag_co'] . ' */'
            endif
        else
            let l:addtag = '#endif'
        endif
    elseif a:type == 'del'
        if b:config['tag']['tag_mode'] == 1
            if b:config['tag']['tag_co'] == ''
                let l:addtag = '#endif'
            else
                let l:addtag = '#endif /* ' . b:config['tag']['tag_co'] . ' */'
            endif
        else
            let l:addtag = '#endif'
        endif
    endif
    return l:addtag
endf
func! s:encodeDeleteBlock(line1, line2)
    if b:config['tag']['rm_prefix'] != ''
        let l:curline = a:line1
        while l:curline <= a:line2
            let l:text = getline(l:curline)
            call setline(l:curline, b:config['tag']['rm_prefix'] . l:text)
            let l:curline = l:curline + 1
        endwhile
    endif
endf
func! s:decodeDeleteBlock(line1, line2)
    if b:config['tag']['rm_prefix'] != ''
        let l:curline = a:line1
        let l:prelen  = strlen(b:config['tag']['rm_prefix'])
        while l:curline <= a:line2
            let l:text = getline(l:curline)
            if stridx(l:text, b:config['tag']['rm_prefix']) == 0
                call setline(l:curline, strpart(l:text, l:prelen))
            endif
            let l:curline = l:curline + 1
        endwhile
    endif
endf
func! s:countList()
    let l:rangelist = s:modifyList()
    let l:cntlist   = []
    " count source lines
    let l:i = 0
    while l:i < len(l:rangelist)
        let l:type  = l:rangelist[l:i]
        let l:line1 = l:rangelist[l:i+1]
        let l:line2 = l:rangelist[l:i+2]
        if l:type == 'add'
            call add(l:cntlist, 'add')
            call add(l:cntlist, l:line1+1)
            let l:cnt = s:countSourceLines(l:line1+2+b:config['options']['show_reason']+b:config['tag']['tag_mode'],l:line2-1-b:config['tag']['tag_mode'])
            call extend(l:cntlist, l:cnt)
        elseif l:type == 'chg'
            call add(l:cntlist, 'chg')
            call add(l:cntlist, l:line1+1)
            call cursor(l:line1+2+b:config['options']['show_reason'], 1)
            call searchpair('#if','#else','#endif')
            let l:midline = line('.')
            let l:cnt = s:countSourceLines(l:line1+3+b:config['options']['show_reason'],l:midline-1)
            call extend(l:cntlist, l:cnt)
            let l:cnt = s:countSourceLines(l:midline+1,l:line2-2)
            call extend(l:cntlist, l:cnt)
        elseif l:type == 'del'
            call add(l:cntlist, 'del')
            call add(l:cntlist, l:line1+1)
            let l:cnt = s:countSourceLines(l:line1+3+b:config['options']['show_reason'],l:line2-2)
            call extend(l:cntlist, l:cnt)
        endif
        let l:i   = l:i + 3
    endwhile
    return l:cntlist
endf
func! s:modifyList()
    silent! exe "normal gg"
    let l:rangelist = []
    let l:startline = escape(s:constructStartLine(), s:ptn_escape)
    let l:keyline   = s:constructKeyword()
    let l:endline   = escape(s:constructEndLine(), s:ptn_escape)
    let l:lineno1   = search(l:startline)
    while l:lineno1 > 0
        let l:keylinetext = getline(l:lineno1 + 1)
        if stridx(l:keylinetext, l:keyline) > 0
            call cursor(l:lineno1, 1)
            let l:lineno2 = searchpair(l:startline, '', l:endline)
            if l:lineno2 > l:lineno1
                if stridx(l:keylinetext, 'ADD[') > 0
                    call add(l:rangelist, 'add')
                elseif stridx(l:keylinetext, 'CHG[') > 0
                    call add(l:rangelist, 'chg')
                elseif stridx(l:keylinetext, 'DEL[') > 0
                    call add(l:rangelist, 'del')
                endif
                call add(l:rangelist, l:lineno1)
                call add(l:rangelist, l:lineno2)
            endif
        endif
        let l:lineno2 = search(l:startline)
        if l:lineno2 <= l:lineno1
            let l:lineno1 = -1
        else
            let l:lineno1 = l:lineno2
        endif
    endwhile
    return l:rangelist
endf
func! s:countSourceLines(startlineno, endlineno)
    silent! redir => dummy
    call s:decodeDeleteBlock(a:startlineno, a:endlineno)
    " delete lines after range
    if a:endlineno < line('$')
        silent! exe "normal ".(a:endlineno+1)."G"
        silent! exe "normal ".(line("$")-a:endlineno)."dd"
    endif
    " delete lines before range
    if a:startlineno > 1
        silent! exe "normal gg"
        silent! exe "normal ".(a:startlineno-1)."dd"
    endif
    call s:rmComment()
    " remove empty line
    silent! g+^\s*$+d
    let l:count = line("$")
    silent undo
    redir END
    return [a:endlineno-a:startlineno+1, l:count]
endf
func! s:rmComment()
    " delete comment //...
    silent! %s+//.*$++g
    " change multi-line comment into one-line comments
    call cursor(1, 1)
    let l:cmtstart = searchpos('/\*', 'cWe')
    while l:cmtstart[0] > 0
        let l:cmtstop = searchpos('\*/', 'We')
        if l:cmtstop[0] > 0
            if l:cmtstop[0] > l:cmtstart[0]
                " multi-line comment
                call setline(l:cmtstart[0], getline(l:cmtstart[0]) . '\t*/')
                let l:i = l:cmtstart[0] + 1
                while l:i < l:cmtstop[0]
                    call setline(l:i, '/*\t' . getline(l:i) . '\t*/')
                    let l:i = l:i + 1
                endwhile
                call setline(l:cmtstop[0], '/*\t' . getline(l:cmtstop[0]))
            else
                " one-line comment
            endif
        else
            " cannot find the close comment
            break
        endif
        let l:cmtstart = searchpos('/\*', 'We')
    endwhile
    " delete comment /*...*/
    silent! %s+/\*.*\*/++g
    " delete tailing space
    silent! %s+\s\+$++g
endf
func! s:fileList(qflist)
    if a:qflist == 1
        let l:filelist = []
        for l:qfitem in getqflist()
            let l:curfile = bufname(l:qfitem.bufnr)
            if index(l:filelist, l:curfile) < 0
                call add(l:filelist, l:curfile)
            endif
        endfor
    else
        let l:filelist = split(glob(expand("%:p:h:gs?\\?/?") . "/**/*.{c,cxx,cpp,h,hxx,hp}"),"\n")
    endif
    return l:filelist
endf
func! s:splitKeywordLine(linetext)
    let l:keyword  = s:constructKeyword()
    let l:text = a:linetext
    if stridx(l:text, l:keyword) > 0
        let l:text = substitute(l:text, escape(b:config['tag']['cmt_start'], s:ptn_escape), '', '')
        let l:text = substitute(l:text, escape(b:config['tag']['cmt_end'], s:ptn_escape), '', '')
        let l:text = substitute(l:text, escape(b:config['tag']['tag_sep'] . l:keyword . b:config['tag']['tag_sep'], s:ptn_escape), ':', '')
        " add ':' between author and date
        let l:text = substitute(l:text, escape(b:config['tag']['tag_sep'], s:ptn_escape), ':', '')
        let l:text = substitute(l:text, '\CADD\[\(\d*\)\]_\[\(\d*\)\]', '\1:\2::::::', '')
        let l:text = substitute(l:text, '\CCHG\[\(\d*\)\]_\[\(\d*\)\] -> \[\(\d*\)\]_\[\(\d*\)\]', '::\1:\2:\3:\4::', '')
        let l:text = substitute(l:text, '\CDEL\[\(\d*\)\]_\[\(\d*\)\]', '::::::\1:\2', '')
        " sum lines
        let l:pos = match(l:text, ':', 0, 9)
        let l:curlines = split(strpart(l:text, 0, l:pos), ':', 1)
        call add(l:curlines, strpart(l:text, l:pos+1))
        return l:curlines
    else
        return []
    endif
endf
func! s:tellPos(startlineno, endlineno)
    let l:oldpos    = getpos('.')
    let l:rangelist = s:modifyList()
    let l:startline = a:startlineno
    let l:endline   = a:endlineno
    let l:grouplist = []
    let l:i         = 0
    while l:i < len(l:rangelist)
        let l:type  = l:rangelist[l:i]
        let l:line1 = l:rangelist[l:i+1]
        let l:line2 = l:rangelist[l:i+2]
        let l:i = l:i + 3
        if l:startline < l:line1
            let l:startline = l:line1
            if l:startline > l:endline
                break
            endif
        endif
        if l:startline <= l:line2
            call add(l:grouplist, l:type)
            call add(l:grouplist, l:line1)
            call add(l:grouplist, l:line2)
            call add(l:grouplist, l:startline)
            if l:endline <= l:line2
                call add(l:grouplist, l:endline)
                let l:startline = l:endline + 1
                break
            else
                call add(l:grouplist, l:line2)
                let l:startline = l:line2 + 1
            endif
        endif
    endwhile
    call cursor(l:oldpos)
    return l:grouplist
endf
func! s:splitChgBlock(startline, endline)
    call cursor(a:startline + 2 + b:config['options']['show_reason'], 1)
    call searchpair('#if','#else','#endif')
    let l:endtext = getline(a:endline)
    let l:midline = line('.')
    " change part after #else into an ADD block
    " #endif for ADD block
    let l:ifelend = s:constructEndifLine('add')
    if l:ifelend != ''
        call setline(a:endline-1, l:ifelend)
    else
        silent! exe "normal ".(a:endline - 1)."Gdd"
    endif
    let l:curlineno = l:midline
    " copy start line
    let l:linetext  = getline(a:startline)
    call append(l:curlineno, l:linetext)
    let l:curlineno = l:curlineno + 1
    " copy keyword line
    let l:linetext  = getline(a:startline + 1)
    let l:linetext  = substitute(l:linetext, '\CCHG\[\d*\]_\[\d*\] -> \[\d*\]_\[\d*\]', 'ADD[]_[]', '')
    call append(l:curlineno, l:linetext)
    let l:curlineno = l:curlineno + 1
    " copy reason line
    if b:config['options']['show_reason'] > 0
        let l:linetext  = getline(a:startline + 2)
        call append(l:curlineno, l:linetext)
        let l:curlineno = l:curlineno + 1
    endif
    " add #if according to b:config['tag']['tag_mode']
    let l:ifelend = s:constructIfLine('add')
    if l:ifelend != ''
        call append(l:curlineno, l:ifelend)
        let l:curlineno += 1
    endif
    " change part before #else into an DEL block
    " #endif for DEL block
    let l:ifelend = s:constructEndifLine('del')
    call setline(l:midline, l:ifelend)
    " copy end line
    call append(l:midline, l:endtext)
    " modify keyword line
    let l:linetext  = getline(a:startline + 1)
    let l:linetext  = substitute(l:linetext, '\CCHG\[\d*\]_\[\d*\] -> \[\d*\]_\[\d*\]', 'DEL[]_[]', '')
    call setline(a:startline+1, l:linetext)
    return l:midline
endf
func! s:approveAddBlock(blockline1, blockline2, appline1, appline2)
    if a:appline1 <= a:blockline1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        "approve region begins at the beginning of the block
        if a:appline2 >= a:blockline2 - 1 - b:config['tag']['tag_mode']
            "approve region ends at the ending of the block
            silent! exe "normal ".(a:blockline2 - b:config['tag']['tag_mode'])."G".(b:config['tag']['tag_mode'] + 1)."dd"
            silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + b:config['tag']['tag_mode'] + 2)."dd"
        else
            let l:applines = a:appline2 - (a:blockline1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode'])
            if l:applines > 0
                silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + b:config['tag']['tag_mode'] + 2)."dd".l:applines."jp"
            elseif l:applines == 0
                silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + b:config['tag']['tag_mode'] + 2)."ddp"
            endif
        endif
    else
        if a:appline2 >= a:blockline2 - 1 - b:config['tag']['tag_mode']
            "approve region ends at the ending of the block
            let l:applines = a:blockline2 - 1 - b:config['tag']['tag_mode'] - a:appline1
            if l:applines >= 0
                silent! exe "normal ".(a:blockline2-b:config['tag']['tag_mode'])."G".(b:config['tag']['tag_mode'] + 1)."dd".(l:applines+1)."kP"
            endif
        else
            silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + b:config['tag']['tag_mode'] + 2)."Y".a:appline2."Gp"
            silent! exe "normal ".(a:blockline2 + b:config['options']['show_reason'] + 2)."G".(b:config['tag']['tag_mode'] + 1)."Y".a:appline1."GP"
        endif
    endif
endf
func! s:approveDelBlock(blockline1, blockline2, appline1, appline2)
    if a:appline1 <= a:blockline1 + 3 + b:config['options']['show_reason']
        "approve region begins at the beginning of the block
        if a:appline2 >= a:blockline2 - 2
            "approve region ends at the ending of the block
            silent! exe "normal ".a:blockline1."G".(a:blockline2 - a:blockline1 + 1)."dd"
        else
            let l:applines = a:appline2 - (a:blockline1 + 3 + b:config['options']['show_reason'])
            if l:applines >= 0
                silent! exe "normal ".(a:blockline1 + 3 + b:config['options']['show_reason'])."G".(l:applines + 1)."dd"
            endif
        endif
    else
        if a:appline2 >= a:blockline2 - 2
            "approve region ends at the ending of the block
            let l:applines = a:blockline2 - 2 - a:appline1
            if l:applines >= 0
                silent! exe "normal ".a:appline1."G".(l:applines + 1)."dd"
            endif
        else
            silent! exe "normal ".a:appline1."G".(a:appline2 - a:appline1 + 1)."dd"
        endif
    endif
endf
func! s:approveChgBlock(blockline1, blockline2, appline1, appline2)
    let l:midline = s:splitChgBlock(a:blockline1, a:blockline2)
    if l:midline <= a:appline1
        "approve region locates after #else
        let l:newappline1   = a:appline1 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newappline2   = a:appline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newblockline2 = a:blockline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        if l:newappline1 > l:newblockline2
            let l:newappline1 = l:newblockline2
        endif
        if l:newappline2 > l:newblockline2
            let l:newappline2 = l:newblockline2
        endif
        call s:approveAddBlock(l:midline + 2, l:newblockline2, l:newappline1, l:newappline2)
    elseif l:midline < a:appline2
        let l:newappline2   = a:appline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newblockline2 = a:blockline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        if l:newappline2 > l:newblockline2
            let l:newappline2 = l:newblockline2
        endif
        call s:approveAddBlock(l:midline + 2, l:newblockline2, l:midline + 2, l:newappline2)
        call s:approveDelBlock(a:blockline1, l:midline + 1, a:appline1, l:midline + 1)
    else
        "approve region locates before #else
        call s:approveDelBlock(a:blockline1, l:midline + 1, a:appline1, a:appline2)
    endif
endf
func! s:denyAddBlock(blockline1, blockline2, appline1, appline2)
    if a:appline1 <= a:blockline1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        "deny region begins at the beginning of the block
        if a:appline2 >= a:blockline2 - 1 - b:config['tag']['tag_mode']
            "deny region ends at the ending of the block
            silent! exe "normal ".a:blockline1."G".(a:blockline2 - a:blockline1 + 1)."dd"
        else
            let l:applines = a:appline2 - (a:blockline1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode'])
            if l:applines >= 0
                silent! exe "normal ".(a:blockline1 + 2 + b:config['options']['show_reason'] + b:config['tag']['tag_mode'])."G".(l:applines + 1)."dd"
            endif
        endif
    else
        if a:appline2 >= a:blockline2 - 1 - b:config['tag']['tag_mode']
            "deny region ends at the ending of the block
            let l:applines = a:blockline2 - 1 - b:config['tag']['tag_mode'] - a:appline1
            if l:applines >= 0
                silent! exe "normal ".a:appline1."G".(l:applines + 1)."dd"
            endif
        else
            silent! exe "normal ".a:appline1."G".(a:appline2 - a:appline1 + 1)."dd"
        endif
    endif
endf
func! s:denyDelBlock(blockline1, blockline2, appline1, appline2)
    if a:appline1 <= a:blockline1 + 3 + b:config['options']['show_reason']
        "deny region begins at the beginning of the block
        if a:appline2 >= a:blockline2 - 2
            "deny region ends at the ending of the block
            call s:decodeDeleteBlock(a:blockline1, a:blockline2)
            silent! exe "normal ".(a:blockline2 - 1)."G2dd"
            silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + 3)."dd"
        else
            call s:decodeDeleteBlock(a:blockline1, a:appline2)
            let l:applines = a:appline2 - (a:blockline1 + 3 + b:config['options']['show_reason'])
            if l:applines > 0
                silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + 3)."dd".l:applines."jp"
            elseif l:applines == 0
                silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + 3)."ddp"
            endif
        endif
    else
        if a:appline2 >= a:blockline2 - 2
            "deny region ends at the ending of the block
            call s:decodeDeleteBlock(a:appline1, a:blockline2)
            let l:applines = a:blockline2 - 2 - a:appline1
            if l:applines >= 0
                silent! exe "normal ".(a:blockline2-1)."G2dd".(l:applines+1)."kP"
            endif
        else
            call s:decodeDeleteBlock(a:appline1, a:appline2)
            silent! exe "normal ".a:blockline1."G".(b:config['options']['show_reason'] + 3)."Y".a:appline2."Gp"
            silent! exe "normal ".(a:blockline2 + 3)."G2Y".a:appline1."GP"
        endif
    endif
endf
func! s:denyChgBlock(blockline1, blockline2, appline1, appline2)
    let l:midline = s:splitChgBlock(a:blockline1, a:blockline2)
    if l:midline <= a:appline1
        "deny region locates after #else
        let l:newappline1   = a:appline1 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newappline2   = a:appline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newblockline2 = a:blockline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        if l:newappline1 > l:newblockline2
            let l:newappline1 = l:newblockline2
        endif
        if l:newappline2 > l:newblockline2
            let l:newappline2 = l:newblockline2
        endif
        call s:denyAddBlock(l:midline + 2, l:newblockline2, l:newappline1, l:newappline2)
    elseif l:midline < a:appline2
        let l:newappline2   = a:appline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        let l:newblockline2 = a:blockline2 + 3 + b:config['options']['show_reason'] + b:config['tag']['tag_mode']
        if l:newappline2 > l:newblockline2
            let l:newappline2 = l:newblockline2
        endif
        call s:denyAddBlock(l:midline + 2, l:newblockline2, l:midline + 2, l:newappline2)
        call s:denyDelBlock(a:blockline1, l:midline + 1, a:appline1, l:midline + 1)
    else
        "deny region locates before #else
        call s:denyDelBlock(a:blockline1, l:midline + 1, a:appline1, a:appline2)
    endif
endf
func! s:findStaticCheck(type)
    " type 1:loop  0:divide zero
    call s:cleanCode(1)
    call cursor(1, 1)
    let l:lines = []
    if a:type == 1
        let l:pattern = "\\C\\<for\\>\\|\\<while\\>"
    elseif a:type == 0
        let l:pattern = "/\\|%"
    endif
    while search(l:pattern, "eW") > 0
        let l:curno = line('.')
        if index(l:lines, l:curno) < 0
            call add(l:lines, l:curno)
        endif
    endwhile
    silent! undo
    return l:lines
endf
func! s:ListStaticCheck(loopcheck, outnr)
    silent! exe "FencAutoDetect"
    let l:curfile = expand("%:p")
    if a:loopcheck == 1
        let l:linenos = s:findStaticCheck(1)
    else
        let l:linenos = s:findStaticCheck(0)
    endif
    let l:outlines = []
    for l:curno in l:linenos
        let l:linetext = substitute(getline(l:curno), "\t", " ", "g")
        call add(l:outlines, l:curno . "\t" . substitute(l:linetext, "^\\s\\+", "", ""))
    endfor
    call s:closebuffer()
    silent! exe "buf " . a:outnr
    if b:config['diff']['grep_engine'] <= 0
        let l:basepath = expand("%:p:h")
        let l:curfile = strpart(l:curfile, len(l:basepath)+1)
    endif
    for l:linetext in l:outlines
        call append('$', l:curfile . "\t" . l:linetext)
    endfor
endf
func! s:rmInvalidCode()
    silent! exe "normal gg"
    let l:startline = search('^\s*#\s*if\s\+0\>')
    while l:startline > 0
        let l:midline = searchpair('^\s*#\s*if','^\s*#\s*else','^\s*#\s*endif')
        if getline(l:midline) =~ "endif"
            let l:stopline = l:midline
        else
            let l:stopline = searchpair('^\s*#\s*if','^\s*#\s*else','^\s*#\s*endif')
        endif
        silent! exe l:startline . ',' . l:midline . 's/.*//'
        silent! exe l:stopline . 's/.*//'
        let l:startline = search('^\s*#\s*if\s\+0\>')
    endwhile
    let l:startline = search('^\s*#\s*if\s\+1\>')
    while l:startline > 0
        let l:midline = searchpair('^\s*#\s*if','^\s*#\s*else','^\s*#\s*endif')
        let l:stopline = searchpair('^\s*#\s*if','^\s*#\s*else','^\s*#\s*endif')
        silent! exe l:startline . 's/.*//'
        silent! exe l:midline . ',' . l:stopline . 's/.*//'
        let l:startline = search('^\s*#\s*if\s\+1\>')
    endwhile
endf
func! s:cleanCode(keepempty)
    call s:rmInvalidCode()
    call s:rmComment()
    if a:keepempty <= 0
        " remove empty line
        silent! g+^\s*$+d
    endif
endf
func! s:createPath(filename)
    let l:filepath = fnamemodify(a:filename, ':p:h')
    if !isdirectory(l:filepath)
        call mkdir(l:filepath, 'p')
    endif
endf
func! s:rootpath()
    return SpaceVim#plugins#projectmanager#current_root()
endf
func! s:closebuffer()
    silent! exe "bdelete"
    " call SpaceVim#mapping#close_current_buffer()
endf
