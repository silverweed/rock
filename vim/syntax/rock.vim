" Poképon vim syntax highlighting file
"
" by Giacomo Parolini
" Dec 2013

if exists("b:current_syntax")
	finish
endif

" Operators
syn match rockOp /\s\(+\|-\|\/\|\*\|==\|<\|>\|ge\|gt\|le\|lt\|is\|isnt\|<>\|<=\|>=\|:=\|=\|\^\)\s/
syn match rockOp /[\[\]]/

" Comment
syn keyword rockTodo TODO FIXME XXX contained
syn match rockComment /--.*/ contains=@Spell,rockTodo

" Buildin / Keywords
syn keyword rockBuiltin floor append flatten len not
syn match rockBuiltin "?"
syn keyword rockKeyword jump jumpif call die del say return

" Special
syn match rockSpecial "\$res"

" Labels
syn match rockParams contained /[a-zA-Z_][a-zA-Z0-9_]*/
syn match rockLabelName contained /[a-zA-Z_][a-zA-Z0-9_]*:/
"syn match rockLabel /[a-zA-Z_][a-zA-Z_0-9]*:/ contains=rockParams
syn region rockLabel start=/[a-zA-Z_][a-zA-Z0-9_]*:/ end=/\n/ contains=rockParams,rockLabelName

" Constants
syn match rockConstant /[A-Z][a-zA-Z0-9_]*/

" Meta-directives
syn match rockMeta /^#.*/

" Numbers / strings
" A integer, including a leading plus or minus
syn match rockNumber /\<[-]\?\d\+\>/ " Decimal numbers
syn match rockNumber /\%(\i\|\$\)\@<![-+]\?\d*\.\@<!\.\d\+\%([eE][+-]\?\d\+\)\?/
syn match rockString /".*/

hi link rockString String
hi link rockNumber Number
hi link rockArray Number
hi link rockKeyword Keyword
hi link rockComment Comment
hi link rockOp Operator
hi link rockTodo Todo
hi link rockBuiltin Function
hi link rockKeyword Keyword
hi link rockMeta Include
hi link rockLabel Type
hi link rockLabelName Type
hi link rockSpecial Special
hi link rockParams Identifier
hi link rockConstant Constant

let b:current_syntax = "rock"


