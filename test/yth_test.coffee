assert = require 'assert'
_ = require 'underscore'
requirejs = require 'requirejs'
vm = require 'vm'

requirejs.config
    nodeRequire : require,
    baseUrl : __dirname + '/../build/'

compile = requirejs 'compile'
helpers = requirejs '../test/helpers'
run = vm.runInThisContext


describe 'infix operation', ->
    transl_bool = (val) -> if val == '#t' then true else false
    data =
        'arithmetic':
            ops :
                '+' : (x, y, z) -> x + y + z
                '*' : (x, y ,z) -> x * y * z
                '-' : (x, y, z) -> x - y - z
            vals : [-115631, -100, 3, 14, 57, 256, 9999]
        'boolean':
            ops :
                'or' : (x, y, z) -> transl_bool(x) or transl_bool(y) or transl_bool(z)
                'and' : (x, y, z) -> transl_bool(x) and transl_bool(y) and transl_bool(z)
            vals: ['#t', '#f']
    _.each _.keys(data), (op_type) ->
        tuples = helpers.cartesian_power data[op_type].vals, 3
        describe op_type, ->
            _.each _.keys(data[op_type].ops), (op) ->
                it op, ->
                    for tuple in tuples
                        [m, n, k] = tuple
                        scheme = '(' + op + ' ' + n + ' ' + m + ' ' + k + ')'
                        js = compile scheme
                        assert data[op_type].ops[op](n, m, k) == run js, 'Error: \"' + scheme + '\" != \"' + js + '\" at ' + tuple