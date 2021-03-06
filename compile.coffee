parse_blocks = (src) ->
    ### Takes (a) b ... (c) and returns [(a), b, ..., (c)]. ###
    
    i = if src.substring(0, 1) == "(" then find_end(src) else src.indexOf(" ")      # find end of first block
    if i == -1                                                                      # if only one block
        src = util.strip_outer_whitespace(src)
        if src == "" then [] else [util.strip_outer_whitespace(src)]                #   return it
    else                                                                            # otherwise
        L = [util.strip_outer_whitespace(src.substring(0, i + 1))]                  #   make singleton list
        L.concat(parse_blocks(util.strip_outer_whitespace(src.substring(i + 1))))   #   and continue recursively



arg_list = (args) ->
    ### Takes something like ['x_1', ..., 'x_n'] and gives "(x_1, ..., x_n)". ###
    lastarg = args[args.length - 1]
    innerargs = args.splice(0, args.length - 1)
    text = "("
    for x in innerargs
        text = text + x + ", "    
    text + lastarg + ")"



func_and_args = (args) ->
    ### Takes something like ['f', 'x_1', ..., 'x_n'] and gives "f(x_1, ..., x_n)". ###
    args[0] + arg_list(args.splice(1, args.length - 1))
        



define = (src) ->
    ### Handles the case of a (define (f x_1 ... x_n) (stuffs)) ###
    
    blocks = parse_blocks(src)
    params = parse_blocks(util.clean_up(blocks[0]))
    suite = blocks[1]
    
    if params.length == 1                                                           # case: variable
        "var " + params[0] + " = " + compile(suite) + ";\n";
    else                                                                            # case: function
        func_and_args(params) + " {\n    return " + compile(suite) + ";\n}"



call = (src) ->
    ### Handles the case of (f x_1 ... x_n). ###
    func_and_args(parse_blocks(util.clean_up(src)))


arith = (op, args) ->
    ### Handles the case of (* x_1 ... x_n), etc. ###
    
    args = parse_blocks(args)
    lastarg = args[args.length - 1]
    text = '('
    
    for arg in args.splice(0, args.length - 1)
        text = text + compile(arg) + ' ' + op + ' '
    
    text + compile(lastarg) + ')'
    


compile = (src) ->
    ### The main compiling function. ###

    src = util.clean_up(src)
    n = src.indexOf(' ')

    if n == -1      # src is a literal
        src
    else
        switch src.substring(0, n)
            when "define" then define(src.substring(n + 1))
            when "*", "+", "-" then arith(src.substring(0, 1), src.substring(2, src.length))
            else call(src)



window.compile = compile