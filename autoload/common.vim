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
func! LvlDraw(type) range
    let l:suffix = ''
    if a:type == 2
        let l:suffix = '	'
    endif
    let l:levels = s:calcLevels(a:firstline, a:lastline, l:suffix)
    let l:i      = a:firstline
    while l:i <= a:lastline
        if l:levels[l:i - a:firstline][0] < 0
            " empty line
            call setline(l:i, l:levels[l:i - a:firstline][1])
        else
            call setline(l:i, l:levels[l:i - a:firstline][1] . substitute(getline(l:i), '^' . s:indent . '\+', '', ''))
        endif
        let l:i = l:i + 1
    endwhile
endf
func! RootPath(...) abort
    let l:rootpattern = [".git", ".svn", ".hg", ".root"]
    if a:0 > 0
        let l:rootpattern = l:rootpattern + a:1
    endif
    let l:curpath = expand("%:p:h")
    while 1
        for l:item in readdir(l:curpath)
            if index(l:rootpattern, l:item) >= 0
                if has('win32unix')
                  " convert cygwin path to windows path
                  let l:curpath = substitute(system('cygpath -wa ' . l:curpath), "\n$", '', '')
                  let l:curpath = substitute(l:curpath, '\', '/', 'g')
                elseif has('win32')
                  let l:curpath = substitute(l:curpath, '\', '/', 'g')
                endif
                return l:curpath
            endif
        endfor
        let l:newpath = fnamemodify(l:curpath, ":h")
        if l:newpath == l:curpath
            return ""
        else
            let l:curpath = l:newpath
        endif
    endwhile
endf
func! InputRelPath() abort
    let l:col = col(".") - 1
    let l:line = getline(".")
    let l:fname1 = expand("%:p:h")
    let l:fname2 = input("File: ", l:fname1, "file")
    let l:parts1 = split(substitute(l:fname1, '\', '/', 'g'), '/')
    let l:parts2 = split(substitute(l:fname2, '\', '/', 'g'), '/')
    if len(l:parts2) > 0
        if l:parts1[0] == l:parts2[0]
            let l:idx = 0
            while (l:idx < len(l:parts1)) && (l:idx < len(l:parts2))
                if l:parts1[l:idx] == l:parts2[l:idx]
                    let l:idx = l:idx + 1
                else
                    let l:fname2 = trim(repeat("../", len(l:parts1) - l:idx), "/")
                    while l:idx < len(l:parts2)
                        let l:fname2 = l:fname2 . "/" . l:parts2[l:idx]
                        let l:idx = l:idx + 1
                    endwhile
                endif
            endwhile
        endif
        let l:line = strpart(l:line, 0, l:col) . l:fname2 . strpart(l:line, l:col)
        call setline(".", l:line)
    endif
endf
" Inner functions
" Part 1
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
" Part 2
let s:mark0  = '    '
if &encoding == 'utf-8'
    " utf-8
    let s:mark1  = '┣━'
    let s:mark2  = '┃  '
    let s:mark3  = '┗━'
else
    " cp936
    let s:mark1  = iconv("\xe2\x94\xa3\xe2\x94\x81", "utf-8", &enc)
    let s:mark2  = iconv("\xe2\x94\x83", "utf-8", &enc) . '  '
    let s:mark3  = iconv("\xe2\x94\x97\xe2\x94\x81", "utf-8", &enc)
endif
let s:indent = '\(    \|\t\)'
func! s:calcLevels(linestart, linestop, suffix)
    let l:result = []
    let l:i      = a:linestart
    while l:i <= a:linestop
        let l:parts = split(getline(l:i), s:indent, 1)
        let l:cnt   = 0
        while l:parts[l:cnt] == ''
            let l:cnt = l:cnt + 1
            if l:cnt >= len(l:parts)
                break
            endif
        endwhile
        call add(l:result, (l:cnt>=len(l:parts))?-1:l:cnt)
        let l:i = l:i + 1
    endwhile
    let l:result2 = []
    let l:maxi    = a:linestop - a:linestart + 1
    let l:i       = 0
    while l:i < l:maxi
        let l:val = l:result[0]
        call remove(l:result, 0)
        let l:tmp = s:calcMarks(l:result, l:val)
        let l:prefix = ''
        for l:element in l:tmp
            if l:element == 0
                let l:prefix = l:prefix . s:mark0 . a:suffix
            elseif l:element == 1
                let l:prefix = l:prefix . s:mark1 . a:suffix
            elseif l:element == 2
                let l:prefix = l:prefix . s:mark2 . a:suffix
            elseif l:element == 3
                let l:prefix = l:prefix . s:mark3 . a:suffix
            endif
        endfor
        call add(l:result2, [l:val, l:prefix])
        let l:i = l:i + 1
    endwhile
    return l:result2
endf
func! s:calcMarks(lvlarray, val)
    let l:result = []
    let l:val = a:val
    if l:val < 0
        let l:i = 0
        while l:i < len(a:lvlarray)
            if a:lvlarray[l:i] >= 0
                let l:val = a:lvlarray[l:i]
                break
            endif
            let l:i = l:i + 1
        endwhile
        if l:val < 0
            return l:result
        endif
    endif
    let l:i      = 1
    while l:i <= l:val
        let l:k = (l:i == l:val)?3:0
        let l:j = 0
        while l:j < len(a:lvlarray)
            if a:lvlarray[l:j] == l:i
                let l:k = (l:i == l:val)?1:2
                break
            elseif (a:lvlarray[l:j] >= 0) && (a:lvlarray[l:j] < l:i)
                let l:k = (l:i == l:val)?3:0
                break
            endif
            let l:j = l:j + 1
        endwhile
        if (l:k == 1) && (a:val < 0)
            let l:k = 2
        endif
        call add(l:result, l:k)
        let l:i = l:i + 1
    endwhile
    return l:result
endf

