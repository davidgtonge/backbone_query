fs     = require 'fs'
{exec} = require 'child_process'
{spawn}= require 'child_process'

task 'build', 'Build JS files from Coffee sources', ->

  exec 'coffee -c -o js/ src/', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

  exec 'coffee -cb test/backbone-query-test.coffee', (err, stdout, stderr) ->
    throw err if err
    console.log stdout + stderr

task 'watch', 'Watch (auto-compile) backbone-query.coffee', ->
  ps = spawn 'coffee', ['--watch', '--compile', '-o', 'js/', 'src/']
  ps.stdout.on 'data', (data) -> process.stdout.write data
  ps.stderr.on 'data', (data) -> process.stderr.write data

task 'uglify', 'Minify and obfuscate', ->
  uglify = require 'uglify-js'
  jsp = uglify.parser
  pro = uglify.uglify

  contents  = fs.readFileSync "js/backbone-query.js", 'utf8'

  ast = jsp.parse contents # parse code and get the initial AST
  ast = pro.ast_mangle ast # get a new AST with mangled names
  ast = pro.ast_squeeze ast # get an AST with compression optimizations
  final_code = pro.gen_code ast # compressed code here

  fs.writeFile 'js/backbone-query.min.js', final_code

task "test", "Test the code", ->
  path = require 'path'
  reporter = require('nodeunit').reporters.default

  reporter.run ["test/backbone-query-test.js"]
