### file:   compile.coffee
    made:   5/31/2014
    note:   definition / support for the compile(string) function ###



multiple_lines = (src) ->
    ### Takes ['a', ..., 'b'] to 'compile(a);\n...compile(b);\n'. ###
    if src.length == 0 then '' else compile(src[0]) + ';\n' + multiple_lines(src.splice(1))



multiple_lines_return = (src) ->
    ### Same as multiple_lines, but last line is a return statement. ###
    last_src = src.pop()
    multiple_lines(src) + 'return ' + compile(last_src) + ';\n'



define = (src) ->
    ### Takes "(define (f x_1 ... x_n) (stuffs))" and gives "function f(x_1, ..., x_n)
        { return stuffs; }", or takes "(define x 3)" and gives "var x = 3;". ###

    blocks = parse.blocks(src)
    suite = blocks[1].trim()

    if parse.is_function(src)
        params = parse.blocks(util.clean_up(blocks[0]))
        text = "function " + parse.func_and_args(params) + " {\n"
        text + multiple_lines_return(parse.separate(suite)) + "}\n"
    else
        "var " + blocks[0] + " = " + compile(suite) + ";\n";



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
    suite = parse.separate(blocks[1].trim())
    args.splice(0, 0, 'function')
    parse.func_and_args(args) + ' {\n' + multiple_lines_return(suite) + '}\n'



let_statement = (src) ->
    ### Takes '(x a) (suite)' and gives the result of compile applied to
        '((lambda (x) (suite)) a)'. ###

    blocks = parse.blocks(src.trim())
    [x, a] = parse.blocks(util.strip_outer_parentheses(blocks[0].trim()))
    suite = blocks[1]
    parse.anon_wrap('var ' + x + ' = ' + compile(a) + ';\n' + multiple_lines_return(parse.separate(suite)))



set_statement = (src) ->
    ### Takes '(x a)' and gives 'x = a'. ###

    blocks = parse.blocks(src.trim())
    blocks[0] + ' = ' + compile(blocks[1].trim())



do_loop = (src) ->
    ### It's complicated... ###

    [bindings, clause, body] = parse.blocks(src.trim())
    [bindings, body] = [parse.blocks(util.strip_outer_parentheses(bindings.trim())), parse.separate(body.trim())]
    [init, update] = [[], []]
    
    y = parse.separate(clause.trim())
    y.push('undefined')
    [test, return_expression] = [y[0], y[1]]
    
    for x in bindings
        [name, value, step] = parse.blocks(util.clean_up(x))
        init.push(name + ' = ' + compile(value))
        update.push(name + ' = ' + compile(step))
        
    init[0] = 'var ' + init[0]
    text = "for(" + util.strip_outer_parentheses(parse.arg_list(init)) + "; "
    text += "!(" + compile(test) + "); "
    text += util.strip_outer_parentheses(parse.arg_list(update)) + ") {\n"
    text += multiple_lines(body) + "}\nreturn " + compile(return_expression) + ";\n"
    
    parse.anon_wrap(text)
    
    



compile = (src) ->
    ### The main compiling function. ###

    src = util.clean_up(src)
    n = src.indexOf(' ')

    if n == -1      # src is a literal
        switch src
            when "#t" then "true"
            when "#f" then "false"
            else src
    else
        [first, rest] = [src.substring(0, n), src.substring(n + 1)]
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
            when "let" then let_statement(rest)
            when "set!" then set_statement(rest)
            when "do" then do_loop(rest)
            else call(src)



window.compile = compile