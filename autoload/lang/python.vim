let g:et#bin_python = get(g:, 'et#bin_python', exepath('python'))

func! s:python_setup(info) abort
	let l:scripts = copy(a:info['#scripts'])
	silent! exe 'e ' . a:info['#tmpname']
	call append(line('$'), l:scripts)
	silent! exe 'normal dd'
	silent! exe 'w ++enc=utf-8'
	silent! exe 'bd'
endf

func! s:python_check(info) abort
	let l:result = 1
	if (g:et#bin_python == '') || (!executable(g:et#bin_python))
		let l:result = 0
	endif
	return l:result
endf

func! s:python_run(info) abort
	let l:cmd = ''
	let l:cmd = shellescape(g:et#bin_python)
	let l:cmd = l:cmd . ' ' . shellescape(a:info['#tmpname'])
	if has_key(a:info, ':cmdline') && (len(a:info[':cmdline']) > 0)
		let l:cmd = l:cmd . ' ' . join(a:info[':cmdline'], ' ')
	endif
	silent! exe 'cd %:h'
	let l:result = system(l:cmd)
	" rename outfile
	silent! exe 'cd -'
	return l:result
endf

func! s:python_teardown(info) abort
	call delete(a:info['#tmpname'])
	if a:info['#cache'] > 0
		let l:linecheck = getline(a:info['#cache'])
		let l:aa = matchstrpos(l:linecheck, '\[[0-9a-z]\+\]')
		let l:linecheck = strpart(l:linecheck, 0, l:aa[1] + 1) . a:info['#md5'] . strpart(l:linecheck, l:aa[2] - 1)
		call setline(a:info['#cache'], l:linecheck)
	elseif a:info['#cache'] == 0
		call append(a:info['#pos'][1], a:info['#prefix'] . '#+RESULTS['. a:info['#md5'] . ']')
	endif
	if has_key(a:info, ':output')
		if a:info['#cache'] > 0
			let l:lineidx = a:info['#cache']
		elseif a:info['#cache'] == 0
			let l:lineidx = a:info['#pos'][1] + 1
		else
			let l:lineidx = a:info['#pos'][1]
		endif
		let l:line1 = ''
		let l:line2 = ''
		let l:ptn = '{content}'
		if len(a:info[':output']) == 0
			" :output
		else
			" :output result_fmt
			let l:ptn = strpart(a:info[':output'][0], 1, len(a:info[':output'][0]) - 2)
			if len(a:info[':output']) > 1
				" :output result_fmt prefix_fmt
				let l:line1 = strpart(a:info[':output'][1], 1, len(a:info[':output'][1]) - 2)
				let l:line1 = substitute(l:line1, '{prefix}', a:info['#prefix'], 'g')
				let l:line1 = substitute(l:line1, '{space}', ' ', 'g')
				let l:line1 = substitute(l:line1, '{tab}', '\t', 'g')
				let l:line1 = substitute(l:line1, '\\\([{}]\)', '\1', 'g')
			elseif len(a:info[':output']) > 2
				" :output result_fmt prefix_fmt suffix_fmt
				let l:line2 = strpart(a:info[':output'][2], 1, len(a:info[':output'][2]) - 2)
				let l:line2 = substitute(l:line2, '{prefix}', a:info['#prefix'], 'g')
				let l:line2 = substitute(l:line2, '{space}', ' ', 'g')
				let l:line2 = substitute(l:line2, '{tab}', '\t', 'g')
				let l:line2 = substitute(l:line2, '\\\([{}]\)', '\1', 'g')
			endif
		endif
		if l:line1 != ''
			call append(l:lineidx, l:line1)
			let l:lineidx = l:lineidx + 1
		endif
		let l:i = 0
		while l:i < len(a:info['#result'])
			let l:line = substitute(l:ptn, '{prefix}', a:info['#prefix'], 'g')
			let l:line = substitute(l:line, '{content}', a:info['#result'][l:i], 'g')
			let l:line = substitute(l:line, '{space}', ' ', 'g')
			let l:line = substitute(l:line, '{tab}', '\t', 'g')
			let l:line = substitute(l:line, '\\\([{}]\)', '\1', 'g')
			call append(l:lineidx, l:line)
			let l:lineidx = l:lineidx + 1
			let l:i = l:i + 1
		endwhile
		if l:line2 != ''
			call append(l:lineidx, l:line2)
		endif
	endif
endf

let g:et#languages['python'] = {'setup': function('s:python_setup'), 'check': function('s:python_check'), 'run': function('s:python_run'), 'teardown': function('s:python_teardown')}
