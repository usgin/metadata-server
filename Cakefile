fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

std_build = (input, output, callback) ->
  coffee = spawn 'coffee', ['-c', '-o', output, input]
  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

task 'watch', 'Watch source for changes', ->
    coffee = spawn 'coffee', ['-w', '-c', '-o', 'build', 'src']
    coffee.stderr.on 'data', (data) ->
      process.stderr.write data.toString()
    coffee.stdout.on 'data', (data) ->
      print data.toString()
  
task 'build', 'Build app from source', ->
  # Copy .js files from lib
  # Turns out this is hard.
  
  # Covert coffee-scripts
  std_build 'src', 'build'
