if polyglot#init#is_disabled(expand('<sfile>:p'), 'css', 'after/syntax/reason/styled.vim')
  finish
endif

if exists('b:current_syntax')
  let s:current_syntax = b:current_syntax
  unlet b:current_syntax
endif

let b:styled_nested_syntax = 1
syn include @CssSyntax syntax/css.vim
unlet b:styled_nested_syntax

if exists('s:current_syntax')
  let b:current_syntax = s:current_syntax
endif

syntax region styledPpxEncl start=+\[%cx+ end=+\]+ keepend contains=styledBody
syntax region styledPpxEncl start=+\[%styled+ end=+\]+ keepend contains=styledBody
syntax region styledBody start=+{|+ end=+|}+ contains=@CssSyntax contained
