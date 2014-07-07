assert = require 'assert'
_ = require 'underscore'
requirejs = require 'requirejs'
vm = require 'vm'

requirejs.config
    nodeRequire : require,
    baseUrl : __dirname + '/../build/'

compile = requirejs 'compile'
utility = requirejs 'utility'
helpers = requirejs '../test/helpers'
run = vm.runInThisContext

trans_lit = (val) ->
    switch val
        when '#t' then true
        when '#f' then false
        else
            if _.isString(val) then utility.replace_all(val, "'", "") else val

describe 'infix operation', ->
    data =
        'arithmetic':
            ops :
                '+' : (x, y, z) -> x + y + z
                '*' : (x, y ,z) -> x * y * z
                '-' : (x, y, z) -> x - y - z
            vals : [-115631, -100, 3, 14, 57, 256, 9999]
        'boolean':
            ops :
                'or' : (x, y, z) -> trans_lit(x) or trans_lit(y) or trans_lit(z)
                'and' : (x, y, z) -> trans_lit(x) and trans_lit(y) and trans_lit(z)
            vals: ['#t', '#f']
        'comparative':
            ops :
                '<=' : (x, y, z) -> x <= y and y <= z
                '>=' : (x, y, z) -> x >= y and y >= z
                '<' : (x, y, z) -> x < y and y < z
                '>' : (x, y, z) -> x > y and y > z
            vals: [-10, 0, 2.4]
    _.each _.keys(data), (op_type) ->
        tuples = helpers.cartesian_power data[op_type].vals, 3
        describe op_type, ->
            _.each _.keys(data[op_type].ops), (op) ->
                it op, ->
                    for tuple in tuples
                        [m, n, k] = tuple
                        scheme = '(' + op + ' ' + n + ' ' + m + ' ' + k + ')'
                        js = compile scheme
                        assert data[op_type].ops[op](n, m, k) == run(js), 'Error: \"' + scheme + '\" != \"' + js + '\" at ' + tuple

describe 'define/call', ->
    it 'constant function with no arguments', ->
        scheme = '(define (f) 1234) (f)'
        js = compile scheme
        assert run(js) == 1234, 'Error: \"' + scheme + '\" != \"' + js + '\"'
    it 'identity function', ->
        for x in ["'a'", 3.14159, '#t']
            scheme = '(define (f x) x) (f ' + x + ')'
            js = compile scheme
            assert run(js) == trans_lit(x), 'Error: \"' + scheme + '\" != \"' + js + '\" at ' + x