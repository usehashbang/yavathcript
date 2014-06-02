### file: utility.coffee
    made: 5/31/2014
    note: various utility functions; they are placed in window.util ###

strip_between = (str, L, R) ->
    ### Removes anything in str contained between an L and an R. ###
    i = str.indexOf(L)
    j = (str.substring(i + 1)).indexOf(R)
    if (i == -1 or j == -1)
        str
    else
        strip_between(str.substring(0, i) + str.substring(i + j + 2), L, R)

strip_outer_parentheses = (str) ->
    ### Your classes "(asdf)" to "asdf" function. Works like a charm. ###
    if str.substring(0, 1) == "(" then str.substring(1, str.length - 1) else str

strip_trailing_whitespace = (str) ->
    ### Takes away trailing instances of space, \t, \n. ###
    switch str.substr(str.length - 1, 1)
        when "\n", "\t", " " then strip_trailing_whitespace(str.substring(0, str.length - 1))
        else str

strip_leading_whitespace = (str) ->
    ### Takes away leading instances of space, \t and \n. ###
    switch str.substring(0, 1)
        when "\n", "\t", " " then strip_leading_whitespace(str.substring(1))
        else str

strip_outer_whitespace = (str) ->
    ### Removes whitespace from before and after string 'str'. ###
    strip_trailing_whitespace(strip_leading_whitespace(str))

replace_all = (str, from, to) ->
    ### Replaces all instances of 'from' with 'to'. ###
    str = str.replace(from, to) while str.indexOf(from) != -1
    str

trim_whitespace = (str) ->
    ### E.g. "\t\t \t\nasdf  asdf     " \mapsto "asdf asdf". ###
    strip_outer_whitespace(replace_all(replace_all(replace_all(str, "\n", " "), "\t", " "), "  ", " "))

clean_up = (str) ->
    ### Removes outer parentheses, outer whitespace, and trims inner whitespace. ###
    util.strip_outer_whitespace(util.trim_whitespace(util.strip_outer_parentheses(str)))

window.util =
    strip_between : strip_between
    strip_outer_parentheses : strip_outer_parentheses
    strip_outer_parentheses : strip_outer_parentheses
    strip_trailing_whitespace : strip_trailing_whitespace
    strip_leading_whitespace : strip_leading_whitespace
    strip_outer_whitespace : strip_outer_whitespace
    replace_all : replace_all
    trim_whitespace : trim_whitespace
    clean_up : clean_up