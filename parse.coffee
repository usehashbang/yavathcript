### file: parse.coffee
    made: 6/2/2014
    note: functions for parsing scheme's maddening parenthetical glory ###



parenthesis_iter = (str, level, index) ->
    ### Finds index of the first instance of "(" or ")", whichever comes first,
        and returns a list of the form [level \pm 1, new_index].  Here \pm 1 is
        1 if the the first parenthesis is an opener, and -1 if it is a closer. ###

    str = str.substring(index)
    [i, j] = [str.indexOf("("), str.indexOf(")")]
    if (i < j and i != -1) then [level + 1, index + i] else [level - 1, index + j]



find_end = (str) ->
    ### The first character of str should be a left parenthesis '('.  find_end
        will return the index of the correspoding closing parenthesis. ###
    
    # Strip away anything contained in quotation marks
    src = util.strip_between(util.strip_between(str, "\"", "\""), "'", "'")

    # Iterate through until the closing parenthesis is found
    [level, index] = [1, 0]
    while level != 0
        [level, index] = parenthesis_iter(str, level, index + 1)
    index



blocks = (src) ->
    ### E.g., takes "(a) b ... (c)" and returns ['(a)', 'b', ..., '(c)']. ###
    
    i = if src.substring(0, 1) == "(" then find_end(src) else src.indexOf(" ")      # find end of first block
    if i == -1                                                                      # if only one block
        src = util.strip_outer_whitespace(src)                                      #   clean it up and
        if src == "" then [] else [util.strip_outer_whitespace(src)]                #   return it
    else                                                                            # otherwise
        L = [util.strip_outer_whitespace(src.substring(0, i + 1))]                  #   make singleton list
        L.concat(blocks(util.strip_outer_whitespace(src.substring(i + 1))))         #   and continue recursively



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



window.parse =
    find_end : find_end
    arg_list : arg_list
    func_and_args : func_and_args
    blocks : blocks
    