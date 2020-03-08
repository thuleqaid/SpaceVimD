let g:et#bin_java = get(g:, 'et#bin_java', exepath('java'))
let g:et#bin_plantuml = get(g:, 'et#bin_plantuml', '')

func! s:plantuml_setup(info) abort
	let l:scripts = copy(a:info['#scripts'])
	"call insert(l:scripts, "@startuml", 0)
	"call add(l:scripts, "@enduml")
	silent! exe 'e ' . a:info['#tmpname']
	call append(line('$'), l:scripts)
	silent! exe 'normal dd'
	silent! exe 'w ++enc=utf-8'
	silent! exe 'bd'
endf

func! s:plantuml_check(info) abort
	let l:result = 1
	if (g:et#bin_java == '') || (!executable(g:et#bin_java))
		let l:result = 0
	endif
	if (g:et#bin_plantuml == '') || (!filereadable(g:et#bin_plantuml))
		let l:result = 0
	endif
	if !has_key(a:info, ':file')
		let l:result = 0
	elseif len(a:info[':file']) <= 0
		let l:result = 0
	endif
	return l:result
endf

func! s:plantuml_run(info) abort
	let l:cmd = ''
	let l:cmd = shellescape(g:et#bin_java) . ' -jar ' . shellescape(g:et#bin_plantuml)
	if has_key(a:info, ':cmdline') && (len(a:info[':cmdline']) > 0)
		let l:cmd = l:cmd . ' ' . join(a:info[':cmdline'], ' ')
	endif
	let l:cmd = l:cmd . ' -t' . tolower(strpart(a:info[':file'][0], strridx(a:info[':file'][0], '.') + 1))
	let l:cmd = l:cmd . ' ' . shellescape(a:info['#tmpname'])
	silent! exe 'cd %:h'
	let l:result = system(l:cmd)
	" rename outfile
	call rename(strpart(a:info['#tmpname'], 0, strridx(a:info['#tmpname'], '.')) . strpart(a:info[':file'][0], strridx(a:info[':file'][0], '.')), fnamemodify(a:info[':file'][0], ":p"))
	silent! exe 'cd -'
	return l:result
endf

func! s:plantuml_teardown(info) abort
	call delete(a:info['#tmpname'])
	if a:info['#cache'] > 0
		let l:linecheck = getline(a:info['#cache'])
		let l:aa = matchstrpos(l:linecheck, '\[[0-9a-z]\+\]')
		let l:linecheck = strpart(l:linecheck, 0, l:aa[1] + 1) . a:info['#md5'] . strpart(l:linecheck, l:aa[2] - 1)
		call setline(a:info['#cache'], l:linecheck)
	elseif a:info['#cache'] == 0
		call append(a:info['#pos'][1], a:info['#prefix'] . '#+RESULTS['. a:info['#md5'] . ']')
	endif
endf

let g:et#languages['plantuml'] = {'setup': function('s:plantuml_setup'), 'check': function('s:plantuml_check'), 'run': function('s:plantuml_run'), 'teardown': function('s:plantuml_teardown')}
