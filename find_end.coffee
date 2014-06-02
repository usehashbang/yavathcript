### file: find_end.coffee
    made: 5/31/2014
    note: find_end finds the parenthesis in a string that closes a given
          parenthesis ###

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

window.find_end = find_end