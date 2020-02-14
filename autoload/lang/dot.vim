let g:et#bin_dot = get(g:, 'et#bin_dot', exepath('dot'))

func! s:dot_setup(info) abort
	let l:scripts = copy(a:info['#scripts'])
	silent! exe 'e ' . a:info['#tmpname']
	call append(line('$'), l:scripts)
	silent! exe 'normal dd'
	silent! exe 'w ++enc=utf-8'
	silent! exe 'bd'
endf

func! s:dot_check(info) abort
	let l:result = 1
	if (g:et#bin_dot == '') || (!executable(g:et#bin_dot))
		let l:result = 0
	endif
	return l:result
endf

func! s:dot_run(info) abort
	let l:cmd = ''
	let l:cmd = shellescape(g:et#bin_dot)
	if has_key(a:info, ':cmdline') && (len(a:info[':cmdline']) > 0)
		let l:cmd = l:cmd . ' ' . join(a:info[':cmdline'], ' ')
	endif
	let l:cmd = l:cmd . ' -T' . tolower(strpart(a:info[':file'][0], strridx(a:info[':file'][0], '.') + 1))
	let l:cmd = l:cmd . ' ' . shellescape(a:info['#tmpname'])
	let l:cmd = l:cmd . ' -o ' . a:info[':file'][0]
	silent! exe 'cd %:h'
	let l:result = system(l:cmd)
	silent! exe 'cd -'
	return l:result

endf

func! s:dot_teardown(info) abort
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

let g:et#languages['dot'] = {'setup': function('s:dot_setup'), 'check': function('s:dot_check'), 'run': function('s:dot_run'), 'teardown': function('s:dot_teardown')}
