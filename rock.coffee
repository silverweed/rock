###
 Rock, a really silly language
 by silverweed
 
 A Rock program is made by a series of lines and labels, like assembly.
 A line may only consist of:
 *) a label:
     mylabel:
 *) a function definition:
     myfunction: par1 par2 ...
 *) a var definition:
     myvar := expr
 *) a var reassign:
     myvar = expr
 *) a jump directive:
     jump label
     OR
     jump #lineno
     OR
     jump @varname (varname must contain the lineno)
 *) a conditional jump directive:
     jumpif label expr
     OR
     jumpif #lineno expr
     OR
     jump @varname expr (varname must contain the lineno)
 *) a call directive (like jump, but fills variable $ra with lineno+1, used
    for 'function' calls)
     call label [par1 ...]
 *) a builtin statement:
     say expr
 where expr may be:
 *) number
 *) "string
 *) variable name
 *) operand1 <op> operand2
 *) a builtin (e.g. ? variable)
 The default context contains the 'True', 'False', and 'Nil' variables.
 Variables starting with an uppercase letter are constants and cannot be re-assigned
 in the same context (but may be shadowed).
###

# the whole program
_program = []
# map labels -> { lineno, [param names] }
# (normal labels have only lineno, functions have also param names)
_labels = {}
# symbol table
STD_CONTEXT =
	'True': true
	'False': false
	'Nil': null

_context = [STD_CONTEXT]

# meta variables
$debuglv = 0
$maxCycles = 100000

# gets variable x from context, starting from the inmost one to the outmost.
getvar = (x) ->
	for i in [_context.length-1..0]
		if _context[i].hasOwnProperty x
			debug "Found variable #{x} in context ##{i}", 2
			return _context[i][x]
	return undefined

setvar = (x, val, create_new = false) ->
	unless create_new
		if x[0].match /[A-Z]/
			err "Cannot reassign constant #{x}!"
			return
		for i in [_context.length-1..0]
			if _context[i].hasOwnProperty x
				_context[i][x] = val
				debug "Reassigned var #{x} = #{val} in context ##{i}", 2
				return
		err "Variable #{x} not found in any context!"
	else
		_context[_context.length-1][x] = val
		debug "Created new variable #{x} = #{val} in context ##{_context.length-1}", 2

# current lineno (lines start at 1)
_lineno = 1

reset_program = ->
	_program = []
	_labels = {}
	_context = [STD_CONTEXT]
	_lineno = 1
	console.log "Program reset."

# reads the whole program in a table { lineno: line }
read_program = (input) ->
	i = 1
	for line in input.split '\n'
		line = line.trim()
		continue if handle_meta line, i
		_program[i-1] = line
		i += 1

# skips lines beginning with --, assigns labels to line numbers and reads 
# meta directives starting with #
handle_meta = (line, lineno) ->
	return true if line.length < 1 or line[0..1] == '--'
	tok = line.split /\s+/
	fst = tok[0]
	if fst[0] == '#'
		meta_directive fst[1..], tok[1..]
		return true
	if fst[fst.length-1] == ':' # label (or function)
		if tok.length is 1
			# simple label
			_labels[fst[0..fst.length-2]] = { lineno: lineno }
		else
			# function definition
			_labels[fst[0..fst.length-2]] = { lineno: lineno, params: tok[1..] }
		return true
	return false

meta_directive = (dir, params) ->
	switch dir
		when 'limit'
			mc = parseInt params[0], 10
			if mc == mc
				$maxCycles = mc
				debug "[meta] $maxCycles set to #{$maxCycles}"
		when 'debug'
			db = parseInt params[0], 10
			if db == db
				$debuglv = db
				debug "[meta $debuglv set to #{$debuglv}"

# executes line #lineno and returns new lineno to execute
execute_line = (lineno, line) ->
	tok = line.split /\s+/
	fst = tok[0]
	
	if $debuglv >= 3
		debug "tokens:"
		debug "  #{t}" for t in tok

	switch fst
		when 'jump'
			# unconditional jump (jump label or jump #lineno)
			fstch = tok[1][0]
			if fstch == '#'
				return tonumber tok[1][1..]
			if fstch == '@'
				return getvar tok[1][1..]
			unless _labels[tok[1]]?.lineno?
				err "Label #{tok[1]} not found!"
				return
			debug "Jump to label #{tok[1]} @ line #{_labels[tok[1]].lineno}"
			return _labels[tok[1]].lineno

		when 'jumpif'
			# conditional jump (jumpif label expr or jumpif #lineno expr)
			labelno = 0
			fstch = tok[1][0]
			if fstch == '#'
				labelno = tonumber tok[1][1..]
			else if fstch == '@'
				labelno = getvar tok[1][1..]
			else
				unless _labels[tok[1]]?.lineno?
					err "Label #{tok[1]} not found!"
					return
				else
					labelno = _labels[tok[1]].lineno
			if evaluate tok[2..]
				debug "Condition true on jump to label #{tok[1]} @ line #{labelno}"
				return labelno
			else
				debug "Condition false on jump to label #{tok[1]} @ line #{labelno}"
				return lineno + 1
	
		when 'call'
			# like jump, but also sets variable $ra to (lineno + 1) to provide a return point 
			# to the subroutine called (this only accepts a label as argument)
			unless _labels[tok[1]]?.lineno?
				err "Label #{tok[1]} not found!"
				return
			# save return address in current scope
			setvar '$ra', lineno + 1, true
			# create new context
			_context.push {}
			# bind call arguments to function's named parameters (if any)
			if _labels[tok[1]].params?
				params = {}
				for i in [0...Math.min _labels[tok[1]].params.length, tok[2..].length]
					pname = _labels[tok[1]].params[i]
					pval = get tok[2+i]
					params[pname] = pval
					setvar pname, pval, true
			debug "Function call: #{tok[1]}(" +
				"#{if params? and Object.keys(params).length > 1 then '\n\t\t' else ''}" +
				"#{("#{pn}=#{dump pv}: #{type pv}" for pn, pv of params).join '\n\t\t'})"
			debug "Creating new context. Current context chain length: #{_context.length}", 2
			return _labels[tok[1]].lineno

		when 'del'
			# delete variable (del a)
			setvar tok[1], undefined
			debug "Deleted variable #{tok[1]} from context"
			return lineno + 1
	
		when 'return'
			if _context.length is 1
				err "Cannot return from top level!"
				return
			# if a return value is set, save it from local context
			res = if tok.length > 1 then evaluate(tok[1..]) else undefined
			# delete inmost context
			_context.pop()
			debug "Destroying local context. Current context chain length: #{_context.length}", 2
			ra = getvar('$ra')
			if ra == undefined
				err "No return address in current context!"
				return
			# set $res to the return value (may be undefined)
			setvar '$res', res, true
			return ra

		when 'die'
			return -1

		when'say', 'put'
			fnc = if fst is 'say' then print else printnb
			expr = evaluate tok[1..]
			switch typeof expr
				when 'string', 'number'
					fnc expr
				else
					fnc dump expr
			return lineno + 1

	switch tok[1]
		when '='
			# var (re)assign (a = expr)
			# check if array assignment
			m = fst.match /([^\[]+)\[(.+)\]/
			if m
				v = getvar m[1]
				if v instanceof Array
					i = get m[2]
					val = evaluate tok[2..]
					v[i] = val
					debug "Var reassign: #{m[1]}[#{i}] = #{dump val}: #{type val}"
				else
					err "Variable #{m[1]} is not an array, but a #{type v}!"
					return
			else
				if getvar(fst) == undefined
					err "Variable #{fst} not in context!"
					return
				val = evaluate tok[2..]
				setvar fst, val
				debug "Var reassign: #{fst} = #{dump val}: #{type val}"
			return lineno + 1

		when ':='
			#var first assign (a := expr) - may shadow a pre-existing variable
			val = evaluate tok[2..]
			setvar fst, val, true
			debug "Var define: #{fst} := #{dump val}: #{type val}"
			return lineno + 1
	
	err "[aborted] Invalid line: #{line} @ #{lineno}"

	return lineno + 1

# given a literal 'name', resolves it in a value.
# i.e. - if name is a number, return that number,
# else return the value of the variable 'name'.
# TODO: also resolve string values
get = (name) ->
	return undefined unless name?
	a = parseFloat name
	return a if a == a # a is not NaN => a is number
	m = name.match /([^\[]+)\[(.+)\]/
	if m
		debug "m: #{m} (1: #{m[1]}, 2: #{m[2]})", 2
		v = getvar m[1]
		if v instanceof Array or typeof v is 'string'
			return v[get m[2]]
		else
			err "Variable #{v} is not an array or string, but a #{type v}!"
			return
	return getvar name # return variable - may be nil

type = (v) -> if v instanceof Array then 'array' else typeof v

dump = (v) ->
	s = ""
	if v instanceof Array
		s = "["
		for el in v
			s += "#{dump el}, "
		s = s[0..-3]
		s += "]"
		return s
	if typeof v is 'string'
		return "'#{v}'"
	return v

# evaluates a series of tokens, which may be:
# var1 (arith-op) var2
# number
# "string with spaces too
# variable
evaluate = (toks) ->

	switch toks[0][0]
		when '"'
			# string
			toks[0] = toks[0][1..]
			return toks.join ' '

		when '['
			# array
			toks[0] = toks[0][1..]
			v = []
			if toks.join('').length > 0
				v.push(get tok) for tok in toks
			return v
	
	# builtin
	switch toks[0]
		when '?'
			return evaluate(toks[1..]) != undefined
		when 'floor'
			return Math.floor evaluate toks[1..]
		when 'len'
			exp = evaluate toks[1..]
			if exp?.length?
				return exp.length
			else
				err "#{exp} has no 'len' attribute! (it's a #{type exp})"
				return
		when 'append'
			v = get toks[1]
			unless v instanceof Array
				err "Cannot append to #{dump toks[1]}! (not an array, but a #{type toks[1]})"
				return
			for t in toks[2..]
				val = get t
				# don't append empty arrays
				continue if val?.length < 1
				v.push val
			return v
		when 'flatten'
			# recursively flatten array
			# (from: https://gist.github.com/th507/5158907)
			eq = (a, b) ->
				i = Math.max a.length, b.length, 1
				true while i-- >= 0 && a[i] == b[i]
				i == -2
			r = []
			ary = evaluate toks[1..]
			while !eq r, ary
				r = ary
				ary = [].concat.apply [], ary
			return ary
		when 'slice'
			# slice <array> <begin> [end]
			str = get toks[1]
			t = type str
			if t isnt 'array' and t isnt 'string'
				err "Cannot slice #{dump toks[1]} (not an array but a #{t})"
				return
			b = get toks[2]
			e = get toks[3]
			if typeof e is 'number'
				return str[b..e]
			return str[b..]

	# number or variable
	if toks.length == 1
		return get toks[0]

	# negation
	if toks[0] == 'not'
		return not evaluate toks[1..]

	# binary operation
	op1 = get toks[0]
	op2 = get toks[2]
	debug "op1: #{op1}, op2: #{op2}, op: #{toks[1]}"
	switch toks[1]
		when '+'
			return op1 + op2
		when '-'
			return op1 - op2
		when '*'
			return op1 * op2
		when '/'
			return op1 / op2
		when '^'
			return op1 ** op2
		when 'xor'
			return op1 ^ op2
		when '..'
			return "#{op1} #{op2}"
		when '&&'
			return op1 and op2
		when '||'
			return op1 or op2
		when '>'
			return op1 > op2
		when '==', 'is'
			return op1 == op2
		when '<'
			return op1 < op2
		when '<>', 'isnt'
			return op1 != op2
		when '>='
			return op1 >= op2
		when '<='
			return op1 <= op2
		when '%'
			return op1 % op2

	err "Invalid operation: #{toks.join ' '}"

# utils
htmlify = (str) ->
	if str?.replace?
		str.replace(/\n/g,'<br>').replace(/\t/g,'&emsp;').replace(/\s/g,'&nbsp;')
	else
		str

err = (msg) ->
	$out.innerHTML += "<p class='err'>[#{_lineno}] ERR: #{htmlify msg}</p>"
	$out.innerHTML += "<p class='err'>&emsp;-> <code>#{_program[_lineno-1]}</code></p>"

print = (msg) ->
	$out.innerHTML += "#{htmlify msg}<br/>"

printnb = (msg) ->
	$out.innerHTML += htmlify msg

debug = (msg, lv = 1) ->
	$out.innerHTML += "<p class='debug'>#{htmlify msg}</p>" if $debuglv >= lv

dump_program = ->
	console.log "Program:"
	console.log "[#{i}] #{line}" for i, line of _program

dump_labels = ->
	console.log "Labels:"
	console.log "#{label} @ line #{lineno}" for label, lineno of _labels

dump_context = ->
	console.log "Context:"
	console.log "#{x} = #{v}" for x, v of _context[0]
# main

executeRock = (code) ->
	reset_program()
	read_program code
	dump_program()
	dump_labels()
	dump_context()
	cycles = 0
	while _lineno > 0 and _lineno <= _program.length
		debug "Executing: [#{_lineno}] #{_program[_lineno-1]}", 2
		if cycles > $maxCycles
			err "Cycle limit exceeded: #{$maxCycles}"
			break
		_lineno = execute_line _lineno, _program[_lineno-1]
		++cycles
