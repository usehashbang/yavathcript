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
    describe 'arithmetic', ->
        ops =
            '+' : (x, y, z) -> x + y + z
            '*' : (x, y ,z) -> x * y * z
            '-' : (x, y, z) -> x - y - z
        numbers = [-115631, -100, 3, 14, 57, 256, 9999]
        _.each _.keys(ops), (op) ->

            it op, ->
                for tuple in helpers.cartesian_power numbers, 3
                    [m, n, k] = tuple
                    scheme = '(' + op + ' ' + n + ' ' + m + ' ' + k + ')'
                    js = compile scheme
                    unless ops[op](n, m, k) == run js
                        assert false, 'Error: \"' + scheme + '\" != \"' + js + '\" at ' + tuple

    describe 'boolean', ->
        perf =
            'a' : (x, y, z, u, v, w) -> (x and (y or (z and not u))) or (v and w)
            'b' : (x, y, z, u, v, w) -> (x or not y) and (u or not v) and (z or not w)
            'c' : (x, y, z, u, v, w) -> (x and y and z) or not (u and v and w)
        schemes =
            'a' : (x, y, z, u, v, w) -> '(or (and '+x+' (or '+y+' (and '+z+' (not '+u+')))) (and '+v+' '+w+'))'
            'b' : (x, y, z, u, v, w) -> '(and (or '+x+' (not '+y+')) (or '+u+' (not '+v+')) (or '+z+' (not '+w+')))'
            'c' : (x, y, z, u, v, w) -> '(or (and '+x+' '+y+' '+z+') (not (and '+u+' '+v+' '+w+')))'
        _.each _.keys(perf), (i) ->

            it 'test sentence ' + schemes[i]('x', 'y', 'z', 'u', 'v', 'w'), ->
                for tuple in helpers.cartesian_power ['#t', '#f'], 6
                    [x, y, z, u, v, w] = tuple
                    [X, Y, Z, U, V, W] = helpers.mapping tuple, (x) ->
                        if x == '#t' then true else false
                    scheme = schemes[i](x, y, z, u, v, w)
                    js = compile scheme
                    unless !perf[i](X, Y, Z, U, V, W) == !run(js)
                        assert false, 'Error: \"' + scheme + '\" != \"' + js + '\"'