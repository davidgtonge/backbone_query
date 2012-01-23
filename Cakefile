fs     = require 'fs'
{exec} = require 'child_process'


task 'build', 'Build JS files from Coffee sources', ->

  exec 'coffee -c -o js/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

  exec 'coffee -c test/backbone-query-test.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr