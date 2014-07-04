# file:   compile.coffee
# made:   5/31/2014
# note:   definition / support for the compile(string) function.

define ['parse', 'utility'], (parse, utility) ->

    def = (src) ->
        # Takes `(define (f x_1 ... x_n) (stuffs))` and gives `function f(x_1, ...,
        # x_n) { return stuffs; }`, or takes `(define x 3)` and gives `var x = 3;`.
        suite = parse.blocks src
        args = suite.splice(0, 1).pop()
        if parse.is_function args
            params = parse.blocks utility.clean_up args
            "function " + func_and_args(params) + ' {\n' + compile_blocks_with_return(suite) + '}\n'
        else
            'var ' + args + ' = ' + compile(suite[0]) + ';\n';

    call = (src) ->
        # Takes something like `(f x_1 ... x_n)`.
        func_and_args parse.blocks utility.clean_up src

    arith = (op, args) ->
        # Handles the case of `(* x_1 ... x_n)`, etc.
        args = parse.blocks args
        lastarg = args[args.length - 1]
        text = '('
        for arg in args.splice(0, args.length - 1)
            text += compile(arg) + ' ' + op + ' '
        text + compile(lastarg) + ')'

    compare = (op, args) ->
        # Turns `(<= x_1 ... x_n)` into `(x_1 <= x_2) && ... && (x_{n-1} <= x_n)`.
        blocks = parse.blocks args.trim()
        if blocks.length > 2
            text = '(and '
            for i in [0 .. (blocks.length - 2)]
                text += '(' + op + ' ' + blocks[i] + ' ' + blocks[i + 1] + ') '
            compile text + ')'
        else
            arith op, args

    if_statement = (src) ->
        # Takes `(if x y z)` and gives `x? y : z`.
        blocks = parse.blocks src.trim()
        "(" + compile(blocks[0]) + "? " + compile(blocks[1]) + " : " + compile(blocks[2]) + ")"

    arg_list = (args) ->
        # Takes something like ['x_1', ..., 'x_n'] and gives '(x_1, ..., x_n)'.
        parse.arg_list_verb(compile x for x in args)

    func_and_args = (args) ->
        # Takes, e.g., ['f', 'x_1', ..., 'x_n'] and gives 'f(x_1, ..., x_n)'.
        args[0] = ('(' + compile(args[0]) + ')') if parse.is_function args[0]
        args[0] + arg_list args.splice 1, args.length - 1

    cond = (src) ->
        # Takes `(cond (a b) ... (c d))` and gives an equivalent if/else, wrapped in
        # an anonymous function.
        blocks = parse.blocks src.trim()
        text = "(function() {\n";
        for block in blocks
            suite = parse.blocks utility.clean_up block
            pred = suite.splice(0, 1).pop()
            unless block == blocks[0]
                text = text + "} else "
            unless pred in ["else", "#t"]
                text = text + "if (" + compile(pred) + ") "
            text += "{\n" + compile_blocks_with_return(suite)
        text + "}\n})()"

    lambda = (src) ->
        # Takes `(x ... z) (suite)` and gives a lambda, i.e. anonymous js function
        # `function(x, ..., z) { compile(suite); }`.
        blocks = parse.blocks src.trim()
        args = parse.blocks utility.clean_up blocks[0]
        suite = blocks[1].trim()
        args.splice 0, 0, 'function'
        func_and_args(args) + ' {\nreturn ' + compile(suite) + ';\n}\n'

    let_statement = (src, star) ->
        # Takes `((x a)) (suite)` and gives the result of compile applied to
        # `((lambda (x) (suite)) a)`.
        suite = utility.clean_up parse.blocks src
        bindings = parse.blocks blocks.splice 0, 1
        [code_1, code_2, code_3, i, temp_var] = ['var ', '', '', 0, 'temp']
        for bind in bindings
            is_last = bind == utility.last bindings
            [x, a] = parse.blocks utility.strip_outer_parentheses bind.trim()
            code_1 += x + if is_last then ';\n' else ', '
            if star
                code_3 += x + ' = ' + compile(a) + ';\n'
            else
                code_2 += compile(a) + if is_last then '];\n' else ', '
                code_3 += x + ' = !@#$%[' + i + if is_last then '];\n' else '], '
            i += 1
            temp_var = '_' + temp_var while x.indexOf(temp_var) != -1
        code_2 = 'var ' + temp_var + ' = [' + code_2 if not star
        code_3 = utility.replace_all(code_3, '!@#$%', temp_var)
        parse.anon_wrap(code_1 + code_2 + code_3 + 'return ' + compile(suite))

    set_statement = (src) ->
        # Takes `(x a)` and gives `x = a`.
        blocks = parse.blocks src.trim()
        blocks[0] + ' = ' + compile blocks[1].trim()

    do_loop = (src) ->
        # It's complicated...
        [bindings, clause, suite] = parse.blocks src.trim()
        [bindings, init, update] = [parse.blocks(utility.clean_up(bindings)), [], []]
        y = parse.separate clause.trim()
        y.push 'undefined'
        [test, return_expression] = [y[0], y[1]]
        for x in bindings
            [name, value, step] = parse.blocks utility.clean_up x
            init.push name + ' = ' + compile value
            update.push name + ' = ' + compile step
        init[0] = 'var ' + init[0]
        text = "for(" + utility.strip_outer_parentheses(parse.arg_list_verb(init)) + "; "
        text += "!(" + compile(test) + "); "
        text += utility.strip_outer_parentheses(parse.arg_list_verb(update)) + ") {\n"
        text += compile(suite) + "}\nreturn " + compile(return_expression) + ";\n"
        parse.anon_wrap text

    compile = (src) ->
        # The main compiling function.
        src = utility.clean_up src
        n = utility.find_end src
        if n == src.length - 1
            switch src
                when "#t" then "true"
                when "#f" then "false"
                else src
        else
            [first, rest] = [src.substring(0,n+1), src.substring(n+1).trim()]
            switch first
                when "define" then def rest
                when "*", "+", "-" then arith first, rest
                when "and" then arith '&&', rest
                when "or" then arith '||', rest
                when "not" then '!' + compile rest
                when "<", ">", ">=", "<=" then compare first, rest
                when "=", "==" then compare "==", rest
                when "if" then if_statement rest
                when "cond" then cond rest
                when "lambda" then lambda rest
                when "let" then let_statement rest, false
                when "let*" then let_statement rest, true
                when "set!" then set_statement rest
                when "do" then do_loop rest
                else call src

    compile_blocks_with_return = (blocks) ->
        # Compiles a list of functions, with a return statement on the last.
        last_block = blocks.pop()
        compile_blocks(blocks) + 'return ' + compile(last_block) + ';\n'

    compile_blocks = (blocks) ->
        # Takes a list of blocks and compiles each one.
        code = ""
        code += utility.add_semicolon(compile block) for block in blocks
        code

    compile_suite = (src) ->
        # Compiles multiple line programs.
        compile_blocks parse.blocks src