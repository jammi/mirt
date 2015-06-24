#!/usr/bin/env coffee
'use strict'

coffee = require 'coffee-script'
coffeeLint = require 'coffeelint'
fs = require 'fs'

printLint = (fileName, lintResults) ->
  for lintLine in lintResults
    console.log("""LINT: #{fileName} #{lintLine.lineNumber}: #{lintResult.message}""")

for [fileName, destFile] in [
    ['src/mirt.coffee', 'lib/mirt/mirt.js']
    ['src/mirt-values.coffee', 'lib/mirt/mirt-values.js']
    ['src/mirt-client.coffee', 'lib/mirt/mirt-client.js']
    ['src/mirt-post.coffee', 'lib/mirt/mirt-post.js']
    ['src/mirt-session.coffee', 'lib/mirt/mirt-session.js']
    ['src/sessionconfig.coffee', 'lib/mirt/sessionconfig.js']
    ['test/src/test-server.coffee', 'test/test-server.js']
  ]
  console.log("#{fileName}\n..linting")
  printLint(fileName, coffeeLint.lint(fileName))
  console.log("..compiling #{destFile}")
  fileData = fs.readFileSync(fileName).toString('utf-8')
  {js, v3SourceMap} = coffee.compile(fileData, {
    sourceMap: true
    filename: fileName
    header: false
  })
  fs.writeFileSync(destFile, js)
  fs.writeFileSync(destFile.replace('.js','.map'), v3SourceMap)
