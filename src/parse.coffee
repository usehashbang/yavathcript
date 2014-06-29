# file: parse.coffee
# made: 6/2/2014
# note: functions for parsing scheme's maddening parenthetical glory.

define ['utility'], (utility) ->
    alert utility.find_end
    blocks = (src) ->
        # E.g., takes '(a) b ... (c)' and returns ['(a)', 'b', ..., '(c)']
        i = utility.find_end src
        L = [src.substring(0, i + 1).trim()]
        if i == -1 then [] else L.concat blocks src.substring(i + 1).trim()

    arg_list_verb = (args) ->
        # Takes something like ['x_1', ..., 'x_n'] and gives '(x_1, ..., x_n)'.
        lastarg = if args.length > 0 then args[args.length - 1] else ''
        innerargs = args.splice 0, args.length - 1
        text = '('
        for x in innerargs
            text = text + x + ', '
        text + lastarg + ')'

    separate = (src) ->
        # Determines whether the case is (a b c) or ((a) (b) (c)), returning ['a b
        # c'] in the former case, and ['(a)', '(b)', '(c)'] in the latter.
        src = src.trim()
        switch utility.count_leading_parentheses src
            when 0 then ['(' + src + ')']
            when 1 then [src]
            else blocks utility.strip_outer_parentheses src

    is_function = (str) ->
        # Simply returns true if the first character is a parenthesis.
        str.trim().substring(0, 1) == '('

    anon_wrap = (js_code) ->
        # Takes javascript 'js_code' and puts it in an anonymous wrapper, and calls
        # it.  E.g. '(function() { ' + js_code + ' })();'.
        '(function() {\n' + js_code + '})()'

    {
        arg_list_verb : arg_list_verb
        blocks : blocks
        separate : separate
        is_function : is_function
        anon_wrap : anon_wrap
    }