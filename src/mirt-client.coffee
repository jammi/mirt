'use strict'

http = require 'http'

digest = (->
  {createHash} = require 'crypto'
  (key, seed='') ->
    createHash('sha1')
      .update(seed)
      .update(key)
      .digest('hex')
)()

{generate: genRandomString} = require 'randomstring'

module.exports = (config) ->

  unless config?
    config =
      host: 'localhost'
      port: 8001
      path: '/'

  session =
    seq: 0
    key: genRandomString(40)

  getPath = ->
    if session.seq is 0
      "#{config.path}hello"
    else
      "#{config.path}x"

  syncReq = ->
    new Promise (resolve, reject) ->
      sesKey = "#{session.seq.toString(36)}:2:#{session.key}"
      data = [sesKey, {}, []]
      strData = JSON.stringify(data)
      opts =
        hostname: config.host
        port: config.port
        path: getPath()
        method: 'POST'
        headers:
          'Content-Type': 'application/json'
          'Content-Length': strData.length
      console.log "POST #{opts.path}"
      console.log "req: #{strData}"
      req = http.request opts, (res) ->
        res.setEncoding('utf8')
        res.on('data', resolve)
        res.on('error', reject)
      req.write(strData)
      req.end()
      req.on('error', reject)

  errorLog = (err) ->
    console.error 'error:', err

  incrementKey = (key) ->
    session.key = digest(key, session.key)
    session.seq += 1

  sync = ->
    syncReq()
      .then (res) ->
        console.log "res: #{res}\n"
        [keyRaw, valuesIn, dataIn] = JSON.parse(res)
        splitKey = keyRaw.split(':')
        if splitKey.length isnt 3
          errorLog('Invalid session Key')
        else
          [seq, ver, key] = splitKey
          if ver isnt '1' and ver isnt '2'
            errorLog('Unsupported Version')
          else
            incrementKey(key)
            setTimeout(sync, 1000)
      .catch (err) ->
        errorLog(err)

  {sync}
