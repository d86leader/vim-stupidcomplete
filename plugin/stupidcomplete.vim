" Description: A small indent-based usercomplete function for vim
" Maintainer:	some non-disclosing walrus

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_stupidcomplete')
	finish
endif
let g:loaded_stupidcomplete = 1

if exists("b:stupidcomplete_word_regex")
	let s:re = b:stupidcomplete_word_regex
elseif exists("g:stupidcomplete_word_regex")
	let s:re = g:stupidcomplete_word_regex
else
	let s:re = '\m[A-Za-z0-9_]'
endif

fun! s:matchall(haystack, pattern)
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

fun! s:fetch_matches(str, base, line_nr)
	"not preceded by a-word symbol + sabsolutely no magic, don't ignore case + word + not inside quotes
"	let expr = '\V\C' . a:base . s:re . '*' . '\v(([^"\\]*(\\.|"([^"\\]*\\.)*[^"\\]*"))*[^"]*$)@='
	"not preceded by a-word symbols; absolutely no magic, don't ignore case
	let expr = '\('.s:re.'\)\@<!'.'\V\C' . a:base . s:re . '*'
	let matches = s:matchall(a:str, expr)
	"map matches into a neat dicionary which will be returned for completion
	return map(matches, '{"word" : v:val, "info" : "Defined at line " . a:line_nr . ": " . a:str}')
endfun

fun! Stupidcomplete(findstart, base)
	if a:findstart
		" locate the start of the word
		let line = getline('.')
		let startpos = col('.') - 1
		while startpos > 0 && line[startpos - 1] =~ s:re
			let startpos -= 1
		endwhile

		"initialize the word matching expression
		if exists("b:stupidcomplete_word_regex")
			let s:re = b:stupidcomplete_word_regex
		elseif exists("g:stupidcomplete_word_regex")
			let s:re = g:stupidcomplete_word_regex
		else
			let s:re = '\m[A-Za-z0-9_]'
		endif

		return startpos
	else
		"do nothing for an empty word
		if a:base == ''
			return {'words': []}
		endif

		"matches :: [ {word : a, abbr : a, menu : a, info : a, kind : char,  } ] <= String a
		let matches   = []

		"find matches before current line based on indent
		let cline     = line('.')
		let cindent   = indent(cline)
		let all_lines = []
		while cline > 1
			let cline   = cline - 1
			if indent(cline) > cindent
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
			if indent(cline) > cindent
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
