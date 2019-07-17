" dependencies:
"   skywind3000/asyncrun.vim
"   vim-scripts/md5.vim

let g:et#openwith = get(g:, 'et#openwith', {})
let g:et#languages = get(g:, 'et#languages', {})
let g:et#dep = {'md5': exists('*md5#md5')
             \ ,'asyncrun': exists(':AsyncRun')
             \ }

func! et#OpenWith() abort
	silent! exe 'cd %:h'
	let l:fullname = expand("<cfile>:p")
	let l:fileext = tolower(fnamemodify(l:fullname, ":t:e"))
	silent! exe 'cd -'
	let l:extdict = get(g:, 'et#openwith', {})
	if has_key(l:extdict, l:fileext)
		if g:et#dep['asyncrun']
			silent! execute 'AsyncRun ' . shellescape(get(l:extdict, l:fileext)) . ' ' . shellescape(l:fullname)
		else
			call system(shellescape(get(l:extdict, l:fileext)) . ' ' . shellescape(l:fullname))
		endif
	else
		echo l:fileext . ' is not registered.'
	endif
endf

func! et#Execute() abort
	let l:pos = s:srcblock()
	if l:pos[1] > l:pos[0]
		let l:lines = getline(l:pos[0], l:pos[1])
		" get script lines
		let l:i = 1
		let l:scripts = []
		let l:prefix = strpart(l:lines[0], 0, l:pos[2])
		while l:i < len(l:lines) - 1
			call add(l:scripts, strpart(l:lines[l:i], l:pos[2]))
			let l:i = l:i + 1
		endwhile
		if g:et#dep['md5']
			let l:md5 = md5#md5(join(l:scripts, "\n"))
		else
			let l:md5 = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
		endif
		" parse params
		let l:startline = strpart(l:lines[0], l:pos[2])
		let l:params = split(l:startline, ' \+')
		call remove(l:params, 0)
		let l:tmpfile = tempname()
		let l:info = {'#language': l:params[0], '#tmpname': l:tmpfile, '#md5': l:md5, '#cache': -1, '#pos': l:pos, '#scripts': l:scripts, '#prefix': l:prefix}
		let l:lastkey = ''
		let l:i = 1
		while l:i < len(l:params)
			if l:params[i] =~ '^:'
				let l:lastkey = l:params[i]
				if !has_key(l:info, l:lastkey)
					let l:info[l:lastkey] = []
				endif
			elseif l:lastkey != ''
				call add(l:info[l:lastkey], l:params[i])
			endif
			let l:i = l:i + 1
		endwhile
		let l:run = 1
		" check supported language
		if s:langsupport(l:info) <= 0
			echo l:info['#language'] . ' is not supported.'
			let l:run = 0
		endif
		" check cache
		if has_key(l:info, ':cache') && (l:run > 0)
			if (len(l:info[':cache']) > 0) && (l:info[':cache'][0] =~ '^\cyes$')
				" check last md5
				let l:i = l:pos[1] + 1
				let l:linecheck = getline(l:i)
				let l:checkpat = '^\(' . escape(l:prefix, '/*[]()') . '\)\? *$'
				let l:checkpat2 = '^\(' . escape(l:prefix, '/*[]()') . '\)\?#+RESULTS\[[a-z0-9]\+\]'
				let l:maxi = line('$')
				while (l:i < l:maxi) && (l:linecheck =~ l:checkpat)
					" empty line, check next line
					let l:i = l:i + 1
					let l:linecheck = getline(l:i)
				endwhile
				if l:linecheck =~ l:checkpat2
					let l:aa = matchstrpos(l:linecheck, '\[[0-9a-z]\+\]')
					if g:et#dep['md5']
						if strpart(l:aa[0], 1, len(l:aa[0]) - 2) == l:info['#md5']
							let l:run = 0
							echo 'No changes after last execution.'
						else
							let l:info['#cache'] = l:i
						endif
					else
						let l:info['#cache'] = l:i
					endif
				else
					let l:info['#cache'] = 0
				endif
			endif
		endif
		if l:run > 0
			let l:languages = get(g:, 'et#languages', {})
			" save script in temporary file
			call l:languages[l:info['#language']]['setup'](l:info)
			" run script
			let l:info['#result'] = split(l:languages[l:info['#language']]['run'](l:info), '\n')
			call l:languages[l:info['#language']]['teardown'](l:info)
		endif
	else
		echo 'No src block found'
	endif
endf

func! s:langsupport(info) abort
	let l:result = 0
	let l:languages = get(g:, 'et#languages', {})
	if has_key(l:languages, a:info['#language'])
		let l:result = l:languages[a:info['#language']]['check'](a:info)
	endif
	return l:result
endf

func! s:srcblock() abort
	let l:currow = line('.')
	let l:curcol = col('.')
	silent! exe "normal $"
	let l:row1 = search('\c#+begin_src\>', 'b')
	let l:col1 = col('.')
	let l:row2 = search('\c#+end_src\>')
	let l:col2 = col('.')
	call cursor(l:currow, l:curcol)
	if (l:row1 > 0) && (l:row2 > 0) && (l:currow <= l:row2) && (l:col1 == l:col2)
		let l:col1 = l:col1 - 1
		let l:i = l:row1
		let l:prefix = strpart(getline(l:i), 0, l:col1)
		let l:col2 = 0
		while (l:col2 <=0) && (l:i < l:row2)
			let l:i = l:i + 1
			if l:prefix != strpart(getline(l:i), 0, l:col1)
				let l:col2 = 1
			endif
		endwhile
		if l:col2 <= 0
			return [l:row1, l:row2, l:col1]
		endif
	endif
	return [0, 0, 0]
endf

silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/text.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/plantuml.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/python.vim'

nmap <F7> :call et#Execute()<CR>
nmap <F8> :call et#OpenWith()<CR>
