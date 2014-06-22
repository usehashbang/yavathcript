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
    if (str.substring(0, 1) != "(" or parse.find_end(str) != (str.length - 1)) then str else str.substring(1, str.length - 1)

replace_all = (str, from, to) ->
    ### Replaces all instances of 'from' with 'to'. ###
    str = str.replace(from, to) while str.indexOf(from) != -1
    str

clean_up = (str) ->
    ### Removes outer parentheses, outer whitespace, and trims inner whitespace. ###
    (strip_outer_parentheses(str.trim())).trim()

count_leading_parentheses = (str) ->
    ### Counts the number of '(' that occur before a non-whitespace , non '('
        character. ###
    [x, str] = [0, replace_all(str.trim(), " ", "")]
    while str.substring(0, 1) == "("
        [x, str] = [x + 1, str.substring(1)]
    x

last = (L) ->
    ### Returns the last element of a list. ###
    L[L.length - 1]

add_semicolon = (str) ->
    ### Adds a semicolon to the end of str. If the last character is a ;, will
        not add. If the last character is a \n, will place before it. ###
    str = str.substring(0, str.length - 1) while str[str.length - 1] in [';', '\n']
    str + ';\n'

window.util =
    strip_between : strip_between
    strip_outer_parentheses : strip_outer_parentheses
    replace_all : replace_all
    clean_up : clean_up
    count_leading_parentheses : count_leading_parentheses
    last : last
    add_semicolon : add_semicolon