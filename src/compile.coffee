### file:   compile.coffee
    made:   5/31/2014
    note:   definition / support for the compile(string) function ###



define = (src) ->
    ### Takes "(define (f x_1 ... x_n) (stuffs))" and gives "function f(x_1, ..., x_n)
        { return stuffs; }", or takes "(define x 3)" and gives "var x = 3;". ###

    suite = parse.blocks(src)
    args = suite.splice(0, 1).pop()

    if parse.is_function(src)
        params = parse.blocks(util.clean_up(args))
        text = "function " + parse.func_and_args(params) + ' {\n'
        text + compile_blocks_with_return(suite) + '}\n'
    else
        'var ' + blocks[0] + ' = ' + compile(suite) + ';\n';



call = (src) ->
    ### Takes something like "(f x_1 ... x_n)". ###
    parse.func_and_args(parse.blocks(util.clean_up(src)))



arith = (op, args) ->
    ### Handles the case of (* x_1 ... x_n), etc. ###

    args = parse.blocks(args)
    lastarg = args[args.length - 1]
    text = '('

    for arg in args.splice(0, args.length - 1)
        text = text + compile(arg) + ' ' + op + ' '

    text + compile(lastarg) + ')'



compare = (op, args) ->
    ### Turns '(<= x_1 ... x_n)' into '(x_1 <= x_2) && ... && (x_{n-1} <= x_n)'. ###

    blocks = parse.blocks(args.trim())
    if blocks.length > 2
        text = '(and '
        text += '(' + op + ' ' + blocks[i] + ' ' + blocks[i + 1] + ') ' for i in [0 .. (blocks.length - 2)]
        compile(text + ')')
    else
        arith(op, args)



if_statement = (src) ->
    ### Takes '(if x y z)' and gives 'x? y : z'. ###

    blocks = parse.blocks(src.trim())
    "(" + compile(blocks[0]) + "? " + compile(blocks[1]) + " : " + compile(blocks[2]) + ")"



cond = (src) ->
    ### Takes '(cond (a b) ... (c d))' and gives an equivalent if/else,
        wrapped in an anonymous function. ###

    blocks = parse.blocks(src.trim())
    text = "(function() {\n";

    for x in blocks
        [pred, suite] = parse.blocks(util.clean_up(x))
        text = text + "    "
        if x != blocks[0]
            text = text + "} else "
        if pred != "else" and pred != "#t"
            text = text + "if (" + compile(pred) + ") "
        text = text + "{\n        return " + compile(suite) + ";\n"
    text + "    }\n})()"



lambda = (src) ->
    ### Takes '(x ... z) (suite)' and gives a lambda, i.e. anonymous js
        function 'function(x, ..., z) { compile(suite); }'. ###

    blocks = parse.blocks(src.trim())
    args = parse.blocks(util.strip_outer_parentheses(blocks[0].trim()))
    suite = blocks[1].trim()
    args.splice(0, 0, 'function')
    parse.func_and_args(args) + ' {\nreturn ' + compile(suite) + ';\n}\n'



let_statement = (src, star) ->
    ### Takes '(x a) (suite)' and gives the result of compile applied to
        '((lambda (x) (suite)) a)'. ###

    [blocks, text_1, text_2, text_3] = [parse.blocks(src.trim()), 'var ', '', '']
    blocks[0] = util.strip_outer_parentheses(blocks[0].trim()) if util.count_leading_parentheses(blocks[0]) == 2
    [bindings, suite, i, temp_var] = [parse.blocks(blocks[0]), blocks[1], 0, 'temp']

    for bind in bindings
        is_last = (bind == util.last(bindings))
        [x, a] = parse.blocks(util.strip_outer_parentheses(bind.trim()))
        text_1 += x + if is_last then ';\n' else ', '
        if star
            text_3 += x + ' = ' + compile(a) + ';\n'
        else
            text_2 += compile(a) + if is_last then '];\n' else ', '
            text_3 += x + ' = !@#$%[' + i + if is_last then '];\n' else '], '
        i += 1
        temp_var = '_' + temp_var while x.indexOf(temp_var) != -1

    suite = blocks[1]
    text_2 = 'var ' + temp_var + ' = [' + text_2 if not star
    text_3 = util.replace_all(text_3, '!@#$%', temp_var)
    parse.anon_wrap(text_1 + text_2 + text_3 + 'return ' + compile(suite))



set_statement = (src) ->
    ### Takes '(x a)' and gives 'x = a'. ###

    blocks = parse.blocks(src.trim())
    blocks[0] + ' = ' + compile(blocks[1].trim())



do_loop = (src) ->
    ### It's complicated... ###

    [bindings, clause, suite] = parse.blocks(src.trim())
    [bindings, init, update] = [parse.blocks(util.clean_up(bindings)), [], []]

    y = parse.separate(clause.trim())
    y.push('undefined')
    [test, return_expression] = [y[0], y[1]]

    for x in bindings
        [name, value, step] = parse.blocks(util.clean_up(x))
        init.push(name + ' = ' + compile(value))
        update.push(name + ' = ' + compile(step))

    init[0] = 'var ' + init[0]
    text = "for(" + util.strip_outer_parentheses(parse.arg_list_verb(init)) + "; "
    text += "!(" + compile(test) + "); "
    text += util.strip_outer_parentheses(parse.arg_list_verb(update)) + ") {\n"
    text += compile(suite) + "}\nreturn " + compile(return_expression) + ";\n"

    parse.anon_wrap(text)





compile = (src) ->
    ### The main compiling function. ###

    src = util.clean_up(src)                                                    # remove parentheses and whitespace
    n = parse.find_end(src)                                                     # find the end of the first block

    if n == src.length - 1                                                      # src is a literal
        switch src
            when "#t" then "true"
            when "#f" then "false"
            else src
    else                                                                        # src is a function
        [first, rest] = [src.substring(0,n+1), src.substring(n+1).trim()]
        switch first
            when "define" then define(rest)
            when "*", "+", "-" then arith(first, rest)
            when "and" then arith('&&', rest)
            when "or" then arith('||', rest)
            when "<", ">", ">=", "<=" then compare(first, rest)
            when "=", "==" then compare("==", rest)
            when "if" then if_statement(rest)
            when "cond" then cond(rest)
            when "lambda" then lambda(rest)
            when "let" then let_statement(rest, false)
            when "let*" then let_statement(rest, true)
            when "set!" then set_statement(rest)
            when "do" then do_loop(rest)
            else call(src)



compile_blocks_with_return = (blocks) ->
    ### Compiles a list of functions, with a return statement on the last. ###

    last_block = blocks.pop()
    compile_blocks(blocks) + 'return ' + compile(last_block) + ';\n'



compile_blocks = (blocks) ->
    ### Takes a list of blocks and compiles each one. ###

    code = ""
    code += util.add_semicolon(compile block) for block in blocks
    code



compile_suite = (src) ->
    ### Compiles multiple line programs. ###

    compile_blocks parse.blocks src



window.compile = compile
window.compile_suite = compile_suite