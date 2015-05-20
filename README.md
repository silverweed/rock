The Rock programming language
-----------------------------

Rock is a very simple and minimal programming language with assembly-like syntax.

There are currently 2 Rock interpreters: the [original one](https://gist.github.com/silverweed/6a1abee2ae421fb65b60#file-rock-moon), written in MoonScript, and the one hosted in this repository, which was born as a translation of the first in CoffeeScript (in order to be usable from a browser).

Currently, the MoonScript interpreter implements the old language specs, while the CoffeeScript
one is being updated to the new ones.

## Language specs (latest, unstable) ##
A Rock program is made by a series of lines and labels, like assembly.
A line may only consist of:

*  a label: `mylabel:`

*  a var definition:
`myvar := expr`

*  a var reassign:
`myvar = expr`

*  a jump directive:
```jump label
    OR
    jump #lineno
    OR
    jump @varname (varname must contain the lineno)```

*  a conditional jump directive:
    ```jumpif label expr
    OR
    jumpif #lineno expr
    OR
    jump @varname expr (varname must contain the lineno)```

*  a call directive (like jump, but used for function calls)
    ```call label```

* a return directive (must be used from a function)
    ```return expr```

*  a builtin statement:  
    - ```say expr```

where expr may be:  
*  number (integer or floating)
*  "string
*  [val1 val2 ... (array)
*  variable name
*  operand1 (op) operand2
*  a builtin expr (like `? var`)

(For the list of binary operators available, [look here](https://github.com/silverweed/rock/blob/master/rock.coffee#L277))

#### Notes ####
* The scope is made up by a chain of contexts, having the standard context as a root.
  A new context is created whenever a `call` is made and destroyed upon a `return`.

* The default context contains the 'true', 'false', and 'nil' variables
(which may be reassigned and are not treated specially)

* Variable definitions `a := x` *can* overwrite previously defined variables.
  Variable assignments, on the other hand, require the variable to exist.

* Variables starting with an Uppercase letter are constants and cannot be
  reassigned (but may be shadowed via `:=`)

* Arrays can be referenced via `array[index]`; elements can be reassigned via
  `array[index] = expr`. Arrays can contain mixed values: `a := [1 "two" 3`

### Functions ###
Functions are special labels which may have one or more named parameters, like:  
```factorial: n```

A function must be called via `call <functionname> [list of parameters]`, like:  
```call factorial 5```

Upon calling the function, the `$ra` internal variable is filled with `lineno+1`,
which allows the function to return to the place where it was called from after
a `return`.

A `return` statement (which MUST terminate the function) may specify an expression
which will become the return value of the function. This value will be available
in the `$res` special variable in the outer scope of the function after it returns.

The local scope allows the functions to be recursive with no problems:
```
-- factorial recursive function
fact: n
  jumpif fact_base n is 1
  m := n - 1
  call fact m
  return $res * n
fact_base:
  return 1
```

The naming convention for the labels (not enforced by the language) is the following:

* internally, all functions use labels with names prefixed by
  function_name_*

This reduces the possibility of name clashing with the labels.

### Meta statements ###
The language allows to insert meta-statements which modify the interpreter's behaviour.

The meta-statements currently recognized are:

1. #limit <cycle number>: sets the max number of cycles the interpreter will attempt
   to perform (e.g. `#limit 100000`)
2. #debug <debuglv>: sets the debug level (e.g. `#debug 3`)
