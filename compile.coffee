### file:   compile.coffee
    made:   5/31/2014
    note:   definition / support for the compile(string) function ###



define = (src) ->
    ### Takes "(define (f x_1 ... x_n) (stuffs))" and gives "function f(x_1, ..., x_n)
        { return stuffs; }", or takes "(define x 3)" and gives "var x = 3;". ###

    blocks = parse.blocks(src)
    params = parse.blocks(util.clean_up(blocks[0]))
    suite = blocks[1]

    if params.length == 1                                                           # case: variable
        "var " + params[0] + " = " + compile(suite) + ";\n";
    else                                                                            # case: function
        "function " + parse.func_and_args(params) + " {\n    return " + compile(suite) + ";\n}"



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



if_statement = (src) ->
    ### Takes '(if x y z)' and gives 'x? y : z'. ###
    
    blocks = parse.blocks(util.trim_whitespace(src))
    "(" + compile(blocks[0]) + "? " + compile(blocks[1]) + " : " + compile(blocks[2]) + ")"



cond = (src) ->
    ### Takes '(cond (a b) ... (c d))' and gives an equivalent if/else,
        wrapped in an anonymous function. ###

    blocks = parse.blocks(util.trim_whitespace(src))
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
        


compile = (src) ->
    ### The main compiling function. ###

    src = util.clean_up(src)
    n = src.indexOf(' ')

    if n == -1      # src is a literal
        src
    else
        switch src.substring(0, n)
            when "define" then define(src.substring(n + 1))
            when "*", "+", "-", "<", ">", ">=", "<=" then arith(src.substring(0, n), src.substring(n + 1, src.length))
            when "if" then if_statement(src.substring(n + 1))
            when "cond" then cond(src.substring(n + 1))
            else call(src)



window.compile = compile