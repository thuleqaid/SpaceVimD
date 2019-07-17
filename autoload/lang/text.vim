func! s:text_setup(info) abort
	let l:scripts = copy(a:info['#scripts'])
	silent! exe 'e ' . a:info['#tmpname']
	call append(line('$'), l:scripts)
	silent! exe 'normal dd'
	silent! exe 'w ++enc=utf-8'
	silent! exe 'bd'
endf

func! s:text_check(info) abort
	let l:result = 1
	if !has_key(a:info, ':file')
		let l:result = 0
	elseif len(a:info[':file']) <= 0
		let l:result = 0
	endif
	return l:result
endf

func! s:text_run(info) abort
	silent! exe 'cd %:h'
	" rename outfile
	call rename(a:info['#tmpname'], fnamemodify(a:info[':file'][0], ":p"))
	silent! exe 'cd -'
	return ''
endf

func! s:text_teardown(info) abort
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

let g:et#languages['text'] = {'setup': function('s:text_setup'), 'check': function('s:text_check'), 'run': function('s:text_run'), 'teardown': function('s:text_teardown')}
