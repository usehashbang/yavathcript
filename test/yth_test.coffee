assert = require 'assert'
_ = require 'underscore'
requirejs = require 'requirejs'
vm = require 'vm'

requirejs.config
    nodeRequire : require,
    baseUrl : __dirname + '/../build/'

compile = requirejs 'compile'
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
                for n in numbers
                    for m in numbers
                        for k in numbers
                            scheme = '(' + op + ' ' + n + ' ' + m + ' ' + k + ')'
                            js = compile scheme
                            unless ops[op](n, m, k) == run js
                                assert false, 'Error: ' + scheme + ' != ' + js