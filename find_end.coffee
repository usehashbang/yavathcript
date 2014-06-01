### find_end.coffee ###

parenthesis_iter = (str, level, index) ->
    ### Finds the first instance of "(" or ")", whichever comes first, and returns
        a list of the form [L[0] \pm 1, index], where we take + 1 for a left paren-
        thesis and -1 for a right parenthesis. ###
    str = str.substring(index)
    [i, j] = [str.indexOf("("), str.indexOf(")")]
    if (i < j and i != -1) then [level + 1, index + i] else [level - 1, index + j]

find_end = (str) ->
    ### The first character of str should be a left parenthesis '('.  This
        function will return the index of the closing parenthesis. ###
    
    # Strip away anything in between quotation marks (doubles first, then singles)
    src = util.strip_between(util.strip_between(str, "\"", "\""), "'", "'")
    
    # Iterate through until the closing parenthesis is found
    [level, index] = [1, 0]
    while level != 0
        [level, index] = parenthesis_iter(str, level, index + 1)
    index

window.find_end = find_end