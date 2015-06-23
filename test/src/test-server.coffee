'use strict'

init = (host, port) ->
  express = require 'express'
  app = express()

  bodyParser = require 'body-parser'
  app.use(bodyParser.json())

  mirt = require '../lib/mirt/mirt'

  app.post '/x', mirt.post
  app.post '/hello', mirt.post

  server = app.listen port, host, ->
    console.log "MIRT test server listening at http://#{host}:#{port}"

  client = require '../lib/mirt/mirt-client'
  testClient = client({host, port, path: '/'})
  testClient.sync()

init('127.0.0.1', 8001)
