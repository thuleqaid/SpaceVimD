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
				if l:servercnt == 1
					let l:target = l:servers[0]
				elseif l:servercnt > 1
					let l:choice = ListAndSelect("Select Vim Instance:", l:servers, 0)
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

nmap <F9> :call ip#moveToOtherProcess()<CR>
