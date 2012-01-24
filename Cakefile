fs     = require 'fs'
{exec} = require 'child_process'
uglify = require './node_modules/uglify-js'


task 'build', 'Build JS files from Coffee sources', ->

  exec 'coffee -c -o js/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

  exec 'coffee -c test/backbone-query-test.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'uglify', 'Minify and obfuscate', ->
  jsp = uglify.parser
  pro = uglify.uglify

  contents  = fs.readFileSync "js/backbone-query.js", 'utf8'

  ast = jsp.parse contents # parse code and get the initial AST
  ast = pro.ast_mangle ast # get a new AST with mangled names
  ast = pro.ast_squeeze ast # get an AST with compression optimizations
  final_code = pro.gen_code ast # compressed code here

  fs.writeFile 'js/backbone-query.min.js', final_code