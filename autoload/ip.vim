func! ip#moveToOtherProcess() abort
	let l:buf = bufname("%")
	if len(bufname("%")) > 0
		" file exists in current window
		let info = swapinfo(swapname("%"))
		if info["dirty"] > 0
			" file changed after last saving
			echo "Save changes first!"
		else
			" get vim instance list
			let l:servers = split(serverlist(), "\n")
			" remove current instance from the list
			let l:i = 0
			while l:i < len(l:servers)
				if l:servers[l:i] == v:servername
					break
				endif
				let l:i = l:i + 1
			endwhile
			if l:i < len(l:servers)
				call remove(l:servers, l:i)
			endif
			" decide moving to which instance
			let l:servercnt = len(l:servers)
			if l:servercnt > 0
				let l:target = ""
				if len(l:servers) == 1
					let l:target = l:servers[0]
				elseif len(l:servers) > 1
					let l:choice = s:ListAndSelect("Select Vim Instance:", l:servers, 0)
					if l:choice >= 0
						let l:target = l:servers[l:choice]
					else
						echo "Abort"
					endif
				endif
				if len(l:target) > 0
					let l:filename = expand("%:p")
					silent! exe 'bd'
					call remote_send(l:target, ":e " . l:filename . "\n")
				endif
			else
				echo "No instance found!"
			endif
		endif
	else
		echo "No file in the window!"
	endif
endf

function! s:ListAndSelect(title, itemlist, markindex)
	let l:choices = copy(a:itemlist)
	" generate choice-list
	call map(l:choices, '"  " . (v:key + 1) . ". " . v:val')
	" insert '*' at the start of selected item
	if (a:markindex >= 0) && (a:markindex < len(a:itemlist))
		let l:choices[a:markindex] = '*' . l:choices[a:markindex][1:]
	endif
	" set list title
	call insert(l:choices, a:title)
	" ask for user choice
	let l:choice = inputlist(l:choices)
	if (l:choice < 1) || (l:choice > len(a:itemlist))
		let l:choice = 0
	endif
	return l:choice - 1
endfunction

nmap <F9> :call ip#moveToOtherProcess()<CR>
