#!/bin/bash

coffee -c -o test/ test/yth_test.coffee test/helpers.coffee
node_modules/mocha/bin/mocha test/yth_test.js
rm test/yth_test.js
rm test/helpers.js