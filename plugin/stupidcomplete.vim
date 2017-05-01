" Description: A small indent-based usercomplete function for vim
" Maintainer:	some non-disclosing walrus

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_stupidcomplete')
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


fun! s:matchall(haystack, pattern) abort
	let matches = []
	let index   = 0
	let end     = matchend(a:haystack, a:pattern)
	while end != -1
		call add(matches, matchstr(a:haystack, a:pattern, index))
		let  nindex = end
		let  end    = matchend(a:haystack, a:pattern, index)
		let  index  = nindex
	endwhile
	return matches
endfun

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

fun! Stupidcomplete(findstart, base) abort
	if a:findstart
		" FIRST INVOCATION

		"initialize the regex
		if exists("b:stupidcomplete_word_regex")
			let s:re = b:stupidcomplete_word_regex
		elseif exists("g:stupidcomplete_word_regex")
			let s:re = g:stupidcomplete_word_regex
		else
			let s:re = '\m[A-Za-z0-9_]'
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
		let matches   = []

		"find matches before current line based on indent
		let cline     = line('.')
		let cindent   = indent(cline)
		let all_lines = []
		while cline > 1
			let cline   = cline - 1

			"ignore more indented line
			if indent(cline) > cindent
				continue
			endif
			"ignore empty line
			if getline(cline) =~ "^\s*$"
				continue
			endif

			let matches = matches + s:fetch_matches(getline(cline), a:base, cline)
			let cindent = min([cindent, indent(cline)])
		endwhile

		"find matches after current line based on indent
		let cline     = line('.')
		let cindent   = indent(cline)
		let all_lines = []
		while cline < line('$')
			let cline   = cline + 1

			"ignore more indented line
			if indent(cline) > cindent
				continue
			endif
			"ignore empty line
			if getline(cline) =~ "^\s*$"
				continue
			endif

			let matches = matches + s:fetch_matches(getline(cline), a:base, cline)
			let cindent = min([cindent, indent(cline)])
			"specially for haskell: "where" word broadens search
			if match(getline(cline), "where") != -1
				let cindent = cindent + &tabstop
			endif
		endwhile

		"add tag items to completion (should it?)
"		let matches = matches + <SID>tag_matches(base)

		return {'words' : matches}

	endif
endfun

let &cpo = s:save_cpo
unlet s:save_cpo
