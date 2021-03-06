" Description: A small indent-based usercomplete function for vim

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_stupidcomplete') && !exists('g:force_reload_stupidcomplete')
	finish
endif
let g:loaded_stupidcomplete = 1


"setting default variables
if !exists('g:stupidcomplete_lookupquotes')
	let g:stupidcomplete_lookupquotes = 1
endif
if !exists('g:stupidcomplete_ignorecomments')
	let g:stupidcomplete_ignorecomments = 1
endif
if !exists('g:stupidcomplete_all_for_empty')
	let g:stupidcomplete_all_for_empty = 1
endif


fun! s:matchall(haystack, pattern) abort
	let matches = []
	let index   = 0
	let end     = matchend(a:haystack, a:pattern)
	while end != -1
		call add(matches, matchstr(a:haystack, a:pattern, index))
		let  nindex = end
		let  end    = matchend(a:haystack, a:pattern, nindex)
		let  index  = nindex
	endwhile
	return matches
endfun

"function's name is self-descriptive
"note to self: it's probably better to keep str as argument as the match's
"line is used both cut and uncut, and it shouldn't matter much where the
"string is made, in the caller or callee: i hope vim is optimized enough
fun! s:fetch_matches(str, base, line_nr) abort
	"setup regex based on whether to lookup words inside quotes
	if g:stupidcomplete_lookupquotes == 0
		"not preceded by a-word symbols; absolutely no magic, don't ignore case
		let expr = '\('.s:re.'\)\@<!'.'\V\C' . a:base . s:re . '*'
	else
		"not preceded by a-word symbol + absolutely no magic, don't ignore case + word + not inside quotes
		let expr = '\('.s:re.'\)\@<!'.'\V\C' . a:base . s:re . '*' . '\v(([^"\\]*(\\.|"([^"\\]*\\.)*[^"\\]*"))*[^"]*$)@='
	endif

	if g:stupidcomplete_ignorecomments == 0 || s:comm == ""
		let str = a:str
	else
		"strip the string after commentstring
		let i = stridx(a:str, s:comm)
		if i == -1
			let str = a:str
		else
			let str = strpart(a:str, 0, i)
		endif
	endif

	let matches = s:matchall(str, expr)

	"map matches into a neat dicionary which will be returned for completion
	return map(matches, '{"word" : v:val, "info" : "Defined at line " . a:line_nr . ":\n" . a:str}')
endfun

fun! s:is_empty(line_nr) abort
	let str = getline(a:line_nr)

	"most basic check: line literally empty
	if str =~ "^\s*$"
		if exists('g:debug')
			echo 'disregarded line ```' . str . '``` as it is fully empty'
		endif
		
		return 1

	"next: if line starts with comment
	elseif s:comm != "" && stridx(str, s:comm) == 0
		if exists('g:debug')
			echo 'disregarded line ```' . str . '``` as it starts with comment'
		endif
		return 1

	"should add a check if line is an indented comment

	"not empty otherwise
	else
		return 0
	endif
endfun

fun! Stupidcomplete(findstart, base) abort
	if a:findstart
		" FIRST INVOCATION

		"initialize the regex
		if exists("b:stupidcomplete_word_regex")
			let s:re = b:stupidcomplete_word_regex
		elseif exists("g:stupidcomplete_word_regex")
			let s:re = g:stupidcomplete_word_regex
		else
			let s:re = '\m\k'
		endif

		"locate the start of the word
		let line = getline('.')
		let startpos = col('.') - 1
		while startpos > 0 && line[startpos - 1] =~ s:re
			let startpos -= 1
		endwhile

		return startpos

	else
		" SECOND INVOCATION

		"initialize comment string split characters
		if &commentstring == "/*%s*/"
			let s:comm = "//"
		elseif match(&commentstring, "%s") == -1
			let s:comm = ""
		else
			let s:comm = strpart(&commentstring, 0, match(&commentstring, "%s"))
		endif

		"do nothing for an empty word
		if a:base == ''
			return {'words': []}
		endif

		"matches :: [ {word : a, abbr : a, menu : a, info : a, kind : char} ] <= String a
		let matches = []
		"same type; used to collect matches even on more indented lines
		let other_matches = []

		"find matches before current line based on indent
		let cline     = line('.')
		let cindent   = indent(cline)
		let all_lines = []
		while cline > 1
			let cline   = cline - 1

			"from more indented line collect to special array
			if indent(cline) > cindent
				if g:stupidcomplete_all_for_empty
					let other_matches += s:fetch_matches(getline(cline), a:base, cline)
				endif
				continue
			endif
			"ignore empty line
"			if getline(cline) =~ "^\s*$"
			if s:is_empty(cline)
				continue
			endif

			let matches += s:fetch_matches(getline(cline), a:base, cline)
			let cindent = min([cindent, indent(cline)])
		endwhile

		"find matches after current line based on indent
		let cline     = line('.')
		let cindent   = indent(cline)
		let all_lines = []
		while cline < line('$')
			let cline   = cline + 1

			"from more indented line collect to special array
			if indent(cline) > cindent
				if g:stupidcomplete_all_for_empty
					let other_matches += s:fetch_matches(getline(cline), a:base, cline)
				endif
				continue
			endif
			"ignore empty line
"			if getline(cline) =~ "^\s*$"
			if s:is_empty(cline)
				continue
			endif

			let matches += s:fetch_matches(getline(cline), a:base, cline)
			let cindent = min([cindent, indent(cline)])
			"specially for haskell: "where" word broadens search
			if match(getline(cline), "where") != -1
				let cindent = cindent + &tabstop
			endif
		endwhile

		"add tag items to completion (should it?)
"		let matches = matches + <SID>tag_matches(base)

		"if there were no matches, return other matches (if user wants)
		if matches == [] && g:stupidcomplete_all_for_empty
			return {'words' : other_matches}
		else
			return {'words' : matches}
		endif

	endif
endfun

let &cpo = s:save_cpo
unlet s:save_cpo
