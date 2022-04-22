" dependencies:
"   skywind3000/asyncrun.vim

let g:et#openwith = get(g:, 'et#openwith', {})
let g:et#languages = get(g:, 'et#languages', {})
let g:et#dep = {'asyncrun': exists(':AsyncRun')
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

func! et#Execute(whole, force) abort
	let l:posinfo = s:srcblock(a:whole)
	let l:poslen = len(l:posinfo)
	if l:poslen > 0
		let l:posidx = l:poslen
		while l:posidx > 0
			let l:posidx = l:posidx - 1
			let l:pos = l:posinfo[l:posidx]
			redraw
			echo 'Executing ' . (l:poslen - l:posidx) . '/' . l:poslen . ' at lines between ' . l:pos[0] . ' and ' . l:pos[1]

			" parse params
			let l:firstline = getline(l:pos[0])
			let l:startline = strpart(l:firstline, l:pos[2])
			let l:prefix = strpart(l:firstline, 0, l:pos[2])
			let l:params = split(l:startline, ' \+')
			call remove(l:params, 0)
			let l:tmpfile = tempname()
			let l:info = {'#language': l:params[0], '#tmpname': l:tmpfile, '#cache': -1, '#pos': l:pos, '#prefix': l:prefix}
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

			if l:run > 0
				let l:lines = getline(l:pos[0]+1, l:pos[1])
				" get script lines
				let l:i = 0
				let l:scripts = []
				let l:escape = 0
				if has_key(l:info, ':escape') && (index(l:info[':escape'], 'html_close_cmt') >= 0)
					let l:escape = 1
				endif
				while l:i < len(l:lines) - 1
					if l:escape > 0
						if stridx(l:lines[l:i], '-->') >= 0
							let l:lines[l:i] = substitute(l:lines[l:i], '-->', '--\&gt;', 'g')
							call setline(l:pos[0] + 1 + l:i, l:lines[l:i])
						endif
						call add(l:scripts, substitute(strpart(l:lines[l:i], l:pos[2]), '--&gt;', '-->', 'g'))
					else
						call add(l:scripts, strpart(l:lines[l:i], l:pos[2]))
					endif
					let l:i = l:i + 1
				endwhile
				let l:md5 = sha256(join(l:scripts, "\n"))
				let l:info['#md5'] = l:md5
				let l:info['#scripts'] = l:scripts
				" check cache
				if has_key(l:info, ':cache')
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
							if strpart(l:aa[0], 1, len(l:aa[0]) - 2) == l:info['#md5']
								if a:force > 0
									let l:info['#cache'] = l:i
								else
									let l:run = -1
								endif
							else
								let l:info['#cache'] = l:i
							endif
						else
							let l:info['#cache'] = 0
						endif
					endif
				endif
				let l:languages = get(g:, 'et#languages', {})
				" create dir if necessary
				if has_key(l:info, ':file') && (len(l:info[':file']) > 0)
					silent! exe 'cd %:h'
					for l:item in l:info[':file']
						let l:item = fnamemodify(l:item, ':p:h')
						if isdirectory(l:item) > 0
						else
							call mkdir(l:item, 'p')
						endif
					endfor
					silent! exe 'cd -'
				endif
				" save script in temporary file
				call l:languages[l:info['#language']]['setup'](l:info)
				" run script
				let l:info['#result'] = split(l:languages[l:info['#language']]['run'](l:info), '\n')
				call l:languages[l:info['#language']]['teardown'](l:info)
			endif
		endwhile
		redraw
		if l:run < 0
			echo 'No changes after last execution. Use "Shift-F7" to run by force.'
		else
			echo 'Finished ' . l:poslen
		endif
	else
		echo 'No src block found. Use "Ctrl-F7" to run all src blocks in the file by force.'
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

func! s:srcblock(whole) abort
	let l:currow = line('.')
	let l:curcol = col('.')
	let l:pos = []
	if a:whole > 0
		silent! exe "normal gg0"
		let l:row1 = l:currow
		let l:row2 = l:currow
		while ((l:row1 > 0) && (l:row2 > 0))
			let l:row1 = search('\c#+begin_src\>', 'W')
			let l:col1 = col('.')
			let l:row2 = search('\c#+end_src\>', 'W')
			let l:col2 = col('.')
			" in case of unmatched begin/end pairs
			let l:row3 = search('\c#+begin_src\>', 'bW')
			if l:row3 > l:row1
				let l:row1 = l:row3
				let l:col1 = col('.')
			endif
			call cursor(l:row2, l:col2)
			if (l:row1 > 0) && (l:row2 > 0) && (l:col1 == l:col2)
				call add(l:pos, [l:row1, l:col1, l:row2, l:col2])
			endif
		endwhile
	else
		silent! exe "normal $"
		let l:row1 = search('\c#+begin_src\>', 'bW')
		let l:col1 = col('.')
		let l:row2 = search('\c#+end_src\>', 'W')
		let l:col2 = col('.')
		if (l:row1 > 0) && (l:row2 > 0) && (l:currow <= l:row2) && (l:col1 == l:col2)
			call add(l:pos, [l:row1, l:col1, l:row2, l:col2])
		endif
	endif
	call cursor(l:currow, l:curcol)
	let l:result = []
	for [l:row1, l:col1, l:row2, l:col2] in l:pos
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
			call add(l:result, [l:row1, l:row2, l:col1])
		endif
	endfor
	return l:result
endf

silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/text.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/plantuml.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/python.vim'
silent! exe 'source ' . expand("<sfile>:p:h") . '/lang/dot.vim'
