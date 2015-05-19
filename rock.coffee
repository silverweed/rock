###
 Rock, a really silly language
 by silverweed
 
 A Rock program is made by a series of lines and labels, like assembly.
 A line may only consist of:
 *) a label:
     mylabel:
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
     call label
 *) a builtin statement:
     say expr
 where expr may be:
 *) number
 *) "string
 *) variable name
 *) operand1 <op> operand2
 *) ? variable name (checks for existance)
 The default context contains the 'true', 'false', and 'nil' variables
 (which may be reassigned)
###

# the whole program
_program = []
# map labels -> lineno
_labels = {}
# symbol table
STD_CONTEXT =
	'true': true
	'false': false
	'nil': null
_context = STD_CONTEXT

# current lineno (lines start at 1)
_lineno = 1

reset_program = ->
	_program = []
	_labels = {}
	_context = STD_CONTEXT
	_lineno = 1

# reads the whole program in a table { lineno: line }
read_program = (input) ->
	i = 1
	for line in input.split '\n'
		line = line.trim()
		continue if handle_label_or_comment line, i
		_program[i-1] = line
		i += 1

# skips lines beginning with # and assigns labels to line numbers
handle_label_or_comment = (line, lineno) ->
	return true if line.length < 1 or line[0..1] == '--'
	tok = line.split /\s+/
	fst = tok[0]
	if fst[fst.length-1] == ':' # label
		_labels[fst[0..fst.length-2]] = lineno
		return true
	return false

# executes line #lineno and returns new lineno to execute
execute_line = (lineno, line) ->
	tok = line.split /\s+/
	fst = tok[0]
	
	if $debuglv >= 3
		debug "tokens:"
		debug "  #{t}" for t in tok

	if fst == 'jump'
		# unconditional jump (jump label or jump #lineno)
		fstch = tok[1][0]
		if fstch == '#'
			return tonumber tok[1][1..]
		if fstch == '@'
			return _context[tok[1][1..]]
		if _labels[tok[1]] == undefined
			err "Label #{tok[1]} not found!"
			return
		debug "Jump to label #{tok[1]} @ line #{_labels[tok[1]]}"
		return _labels[tok[1]]

	if fst == 'jumpif'
		# conditional jump (jumpif label expr or jumpif #lineno expr)
		labelno = 0
		fstch = tok[1][0]
		if fstch == '#'
			labelno = tonumber tok[1][1..]
		else if fstch == '@'
			labelno = _context[tok[1][1..]]
		else
			if _labels[tok[1]] == undefined
				err "Label #{tok[1]} not found!"
				return
			else
				labelno = _labels[tok[1]]
		if evaluate tok[2..]
			debug "Condition true on jump to label #{tok[1]} @ line #{labelno}"
			return labelno
		else
			debug "Condition false on jump to label #{tok[1]} @ line #{labelno}"
			return lineno + 1
	
	if fst == 'call'
		# like jump, but also sets variable $ra to (lineno + 1) to provide a return point 
		# to the subroutine called (this only accepts a label as argument)
		if _labels[tok[1]] == undefined
			err "Label #{tok[1]} not found!"
			return
		_context['$ra'] = lineno + 1
		return _labels[tok[1]]

	if fst == 'del'
		# delete variable (del a)
		_context[tok[1]] = undefined
		debug "Deleted variable #{tok[1]} from context"
		return lineno + 1

	if fst == 'die'
		return -1

	if fst == 'say'
		print evaluate tok[1..]
		return lineno + 1

	if tok[1] == '='
		# var (re)assign (a = expr)
		if _context[fst] == undefined
			err "Variable #{fst} not in context!"
			return
		_context[fst] = evaluate tok[2..]
		debug "Var reassign: #{fst} = #{_context[fst]}"
		return lineno + 1

	if tok[1] == ':='
		#var first assign (a := expr) - may shadow a pre-existing variable
		_context[fst] = evaluate tok[2..]
		debug "Var define: #{fst} := #{_context[fst]}"
		return lineno + 1
	
	err "[aborted] Invalid line: #{line} @ #{lineno}"

	return lineno + 1

get = (name) ->
	a = parseFloat name
	if a == a
		return a
	return _context[name] # may be nil

# evaluates a series of tokens, which may be:
# var1 (arith-op) var2
# number
# "string with spaces too
# variable
evaluate = (toks) ->
	# string
	if toks[0][0] == '"'
		toks[0] = toks[0][1..]
		return toks.join ' '
	
	# builtin
	switch toks[0]
		when '?'
			return _context[toks[1]] != undefined
		when 'floor'
			return Math.floor get toks[1]

	# number or variable
	if toks.length == 1
		return get toks[0]

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
		when '..'
			return "#{op1} #{op2}"
		when '&&'
			return op1 and op2
		when '||'
			return op1 or op2
		when '>', 'gt'
			return op1 > op2
		when '==', 'is'
			return op1 == op2
		when '<', 'lt'
			return op1 < op2
		when '<>', 'ne', 'isnt'
			return op1 != op2
		when '>=', 'ge'
			return op1 >= op2
		when '<=', 'le'
			return op1 <= op2
		when '%'
			return op1 % op2

	err "Invalid operation: #{toks.join ' '}"

# utils
err = (msg) ->
	$out.innerHTML += "<p class='err'>[#{_lineno}] ERR: #{msg}</p>"
	$out.innerHTML += "<p class='err'>&emsp;-> <code>#{_program[_lineno]}</code></p>"

print = (msg) ->
	$out.innerHTML += "<p class='out'>#{msg}</p>"

debug = (msg, lv = 1) ->
	$out.innerHTML += "<p class='debug'>#{msg}</p>" if $debuglv >= lv

dump_program = ->
	console.log "Program:"
	console.log "[#{i}] #{line}" for i, line of _program

dump_labels = ->
	console.log "Labels:"
	console.log "#{label} @ line #{lineno}" for label, lineno of _labels

# main
$debuglv = 0
MAX_CYCLES = 100000

executeRock = (code) ->
	reset_program()
	read_program code
	dump_program()
	dump_labels()
	cycles = 0
	while _lineno > 0 and _lineno <= _program.length
		debug "Executing: [#{_lineno}] #{_program[_lineno-1]}", 2
		if cycles > MAX_CYCLES
			err "Cycle limit exceeded: #{MAX_CYCLES}"
			break
		_lineno = execute_line _lineno, _program[_lineno-1]
		++cycles
