### file: parse.coffee
    made: 6/2/2014
    note: functions for parsing scheme's maddening parenthetical glory ###



parenthesis_iter = (str, level, index) ->
    ### Finds index of the first instance of "(" or ")", whichever comes first,
        and returns a list of the form [level \pm 1, new_index].  Here \pm 1 is
        1 if the the first parenthesis is an opener, and -1 if it is a closer. ###

    str = str.substring index
    [i, j] = [str.indexOf("("), str.indexOf(")")]
    if i < j and i != -1 then [level + 1, index + i] else [level - 1, index + j]



find_end = (str) ->
    ### The first character of str should not be whitespace, and str should have
        at least one character in it.  If str begins with a parenthesis, returns
        the location of the closing parenthesis.  If not, it returns the last
        index before the first whitespace character. ###

    #src = util.strip_between(util.strip_between(str, "\"", "\""), "'", "'")
    if str.substring(0, 1) != "("
        (str + ' ').indexOf(" ") - 1
    else
        [level, index] = [1, 0]
        while level != 0
            [level, index] = parenthesis_iter str, level, index + 1
        index



blocks = (src) ->
    ### E.g., takes "(a) b ... (c)" and returns ['(a)', 'b', ..., '(c)']. ###

    i = find_end src
    L = [src.substring(0, i + 1).trim()]
    if i == -1 then [] else L.concat blocks src.substring(i + 1).trim()



arg_list_verb = (args) ->
    ### Takes something like ['x_1', ..., 'x_n'] and gives "(x_1, ..., x_n)." ###

    lastarg = if args.length > 0 then args[args.length - 1] else ''
    innerargs = args.splice 0, args.length - 1
    text = "("
    for x in innerargs
        text = text + x + ", "
    text + lastarg + ")"

arg_list = (args) ->
    ### Takes something like ['x_1', ..., 'x_n'] and gives "(x_1, ..., x_n)". ###

    arg_list_verb(compile x for x in args)



func_and_args = (args) ->
    ### Takes something like ['f', 'x_1', ..., 'x_n'] and gives "f(x_1, ..., x_n)". ###
    args[0] = ('(' + compile(args[0]) + ')') if is_function args[0]
    args[0] + arg_list args.splice 1, args.length - 1




separate = (src) ->
    ### Determines whether the case is (a b c) or ((a) (b) (c)), returning ['a b c']
        in the former case, and ['(a)', '(b)', '(c)'] in the latter. ###
    src = src.trim()
    switch util.count_leading_parentheses src
        when 0 then ['(' + src + ')']
        when 1 then [src]
        else blocks util.strip_outer_parentheses src



is_function = (str) ->
    ### Simply returns true if the first character is a parenthesis. ###
    str.trim().substring(0, 1) == "("



anon_wrap = (js_code) ->
    ### Takes javascript 'js_code' and puts it in an anonymous wrapper, and calls
        it.  E.g. '(function() { ' + js_code + ' })();'. ###
    "(function() {\n" + js_code + "})()"



window.parse =
    find_end : find_end
    arg_list : arg_list
    arg_list_verb : arg_list_verb
    func_and_args : func_and_args
    blocks : blocks
    separate : separate
    is_function : is_function
    anon_wrap : anon_wrap