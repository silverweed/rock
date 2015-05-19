The Rock programming language
-----------------------------

Rock is a very simple and minimal programming language with assembly-like syntax.

There are currently 2 Rock interpreters: the [original one](https://gist.github.com/silverweed/6a1abee2ae421fb65b60#file-rock-moon), written in MoonScript, and the one hosted in this repository, which is a translation of the first in CoffeeScript (in order to be usable from a browser).

The two interpreters are equipotent, and both implement the language specs v 1.0 (see below).

## Language specs ##
A Rock program is made by a series of lines and labels, like assembly.
A line may only consist of:
*  a label:
    ```mylabel:```
*  a var definition:
    ```myvar := expr```
*  a var reassign:
    ```myvar = expr```
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
*  a call directive (like jump, but fills variable $ra with lineno+1, used
   for 'function' calls)
    ```call label```
*  a builtin statement:  
    - ```say expr```

where expr may be:  
*  number (integer or floating)
*  "string
*  variable name
*  operand1 <op> operand2
*  a builtin expr (like `? var`)


#### Notes ####
* The scope (context) is global, there are no local variables or such.

* The default context contains the 'true', 'false', and 'nil' variables
(which may be reassigned and are not treated specially)

* Variable definitions `a := x` *can* overwrite previously defined variables.
  Variable assignments, on the other hand, require the variable to exist.

### Conventions ###
In Rock, functions are just labeled snippets of code, and have no local
scope.

The function calling convention (not enforced by the language) is the following:

1. a function is called via `call function_name`, not `jump`
2. arguments are passed via the $arg, $arg2, ... variables.
3. return values are passed via the $res, $res2, ... variables.
4. all those variables must be declared by the callee.
5. internally, all functions use labels with names prefixed by
   function_name_*
6. internally, all functions call variables with a leading _.
   This means that all variables starting with a _ should be considered
   clobber-able by any function call.
7. a function should NOT clobber any variable not starting with
   a _ which isn't an $arg or a $res it required.
8. a function should NOT redefine $arg and $res, but only reassign
   them with '=' (this in order to avoid typos etc)
9. a function must end with a `jump @$ra` instruction to return to the callee.

It's good norm that all required $arg, $res, etc are declared on top
of the main.
