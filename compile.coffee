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
    params = parse.blocks(util.clean_up(blocks[0]))
    suite = blocks[1].trim()

    if params.length == 1                                                           # case: variable
        "var " + params[0] + " = " + compile(suite) + ";\n";
    else                                                                            # case: function
        text = "function " + parse.func_and_args(params) + " {\n"
        text + multiple_lines_return(parse.separate(suite)) + "}\n"



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
    
    ###compile('((lambda (' + x + ') ' + suite + ') ' + a + ')') - doesn't work yet ###
    
    text = '(function() {\nvar ' + x + ' = ' + compile(a) + ';\n' + multiple_lines_return(parse.separate(suite)) + '})()\n'
        


compile = (src) ->
    ### The main compiling function. ###

    src = util.clean_up(src)
    n = src.indexOf(' ')

    if n == -1      # src is a literal
        src
    else
        switch src.substring(0, n)
            when "define" then define(src.substring(n + 1))
            when "*", "+", "-" then arith(src.substring(0, n), src.substring(n + 1, src.length))
            when "and" then arith('&&', src.substring(n + 1, src.length))
            when "or" then arith('||', src.substring(n + 1, src.length))
            when "<", ">", ">=", "<=" then compare(src.substring(0, n), src.substring(n + 1, src.length))
            when "if" then if_statement(src.substring(n + 1))
            when "cond" then cond(src.substring(n + 1))
            when "lambda" then lambda(src.substring(n + 1))
            when "let" then let_statement(src.substring(n + 1))
            else call(src)



window.compile = compile