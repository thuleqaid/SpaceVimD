highlight def MarkWord1  ctermbg=Cyan     ctermfg=Black  guibg=#8CCBEA    guifg=Black
highlight def MarkWord2  ctermbg=Green    ctermfg=Black  guibg=#A4E57E    guifg=Black
highlight def MarkWord3  ctermbg=Yellow   ctermfg=Black  guibg=#FFDB72    guifg=Black
highlight def MarkWord4  ctermbg=Red      ctermfg=Black  guibg=#FF7272    guifg=Black
highlight def MarkWord5  ctermbg=Magenta  ctermfg=Black  guibg=#FFB3FF    guifg=Black
highlight def MarkWord6  ctermbg=Blue     ctermfg=Black  guibg=#9999FF    guifg=Black

let g:mark#groups = get(g:, 'mark#groups', ["MarkWord1", "MarkWord2", "MarkWord3", "MarkWord4", "MarkWord5", "MarkWord6"])
let b:data = [{'pattern': '', 'id': -1}, {'pattern': '', 'id': -1}, {'pattern': '', 'id': -1}, {'pattern': '', 'id': -1}, {'pattern': '', 'id': -1}, {'pattern': '', 'id': -1}]

func! s:EscapeText(text)
    return substitute(escape(a:text, '\' . '^$.*[~'), "\n", '\\n', 'ge')
endf
func! s:nextIndex()
    "if len(b:data) <= 0
    "    call add(b:data, {'pattern': '', 'id': -1})
    "endif
    let l:i = 0
    while l:i < len(b:data)
        if b:data[l:i]['id'] < 0
            return l:i
        endif
        let l:i = l:i + 1
    endwhile
    echom "No empty group available."
    return -1
endf
func! s:selectHighlight() abort
    let l:rows = []
    let l:rows += [['Group', 'Pattern']]
    let l:highmap = []
    let l:highmap += [['Title', 'Title']]
    let l:i = 0
    while l:i < len(b:data)
        if b:data[l:i]['id'] >= 0
            let l:rows += [[g:mark#groups[l:i], b:data[l:i]['pattern']]]
            let l:highmap += [[g:mark#groups[l:i], 'Comment']]
        endif
        let l:i = l:i + 1
    endwhile
    let l:choice = SelectTable(l:rows, l:highmap, -1)
    let l:i = 0
    while l:i < len(b:data)
        if (b:data[l:i]['id'] >= 0) && (l:rows[l:choice][0] == g:mark#groups[l:i]) && (l:rows[l:choice][1] == b:data[l:i]['pattern'])
            return l:i
        endif
        let l:i = l:i + 1
    endwhile
    return -1
endf
func! mark#MarkCurruntWord() abort
    let l:pos = s:nextIndex()
    if l:pos >= 0
        let l:cword = expand('<cword>')
        if !empty(l:cword)
            let l:regexp = s:EscapeText(l:cword)
            " The star command only creates a \<whole word\> search pattern if the
            " <cword> actually only consists of keyword characters. 
            if l:cword =~# '^\k\+$'
                let l:regexp = '\<' . l:regexp . '\>'
            endif
            let l:mid = matchadd(g:mark#groups[l:pos], l:regexp)
            let b:data[l:pos]['pattern'] = l:regexp
            let b:data[l:pos]['id'] = l:mid
        endif
    endif
endf
func! mark#MarkExpression() abort
    let l:pos = s:nextIndex()
    if l:pos >= 0
        let l:regexp = input("Expression: ")
        if !empty(l:regexp)
            let l:mid = matchadd(g:mark#groups[l:pos], l:regexp)
            let b:data[l:pos]['pattern'] = l:regexp
            let b:data[l:pos]['id'] = l:mid
        endif
    endif
endf
func! mark#DeleteHighlight() abort
    let l:pos = s:selectHighlight()
    if l:pos >= 0
        call matchdelete(b:data[l:pos]['id'])
        let b:data[l:pos]['id'] = -1
    endif
endf
func! mark#SearchHighlight() abort
    let l:pos = s:selectHighlight()
    if l:pos >= 0
        call setreg('/', b:data[l:pos]['pattern'])
        exec "normal n"
    endif
endf
func! mark#ClearHighlights() abort
    let l:i = 0
    while l:i < len(b:data)
        if b:data[l:i]['id'] >= 0
            call matchdelete(b:data[l:i]['id'])
            let b:data[l:i]['id'] = -1
        endif
        let l:i = l:i + 1
    endwhile
endf