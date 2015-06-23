'use strict'

# Simple RAM-based session manager
module.exports = (config) ->

  config = require './sessionconfig' unless config?

  _sessionId = 0
  newSessionId = ->
    _sessionId += 1
    _sessionId.toString(36)

  sessionKeys = {}
  sessions = {}

  digest = (->
    {createHash} = require 'crypto'
    (key, seed='') ->
      createHash('sha1')
        .update(seed)
        .update(key)
        .digest('hex')
  )()

  {generate: genRandomString} = require 'randomstring'

  newKey = (len=config.keyLength) ->
    genRandomString(len)

  now = -> new Date().getTime()

  expiration = (seconds=config.timeout) ->
    Math.floor(now() + seconds * 1000)

  createSession = (seed=genRandomString(24)) ->
    sessionId = newSessionId()
    clientKey = newKey()
    key = digest(clientKey, seed)
    session =
      id: sessionId
      key: key
      seq: 0
      expires: expiration(config.timeoutFirst)
    sessions[sessionId] = session
    sessionKeys[key] = sessionId
    ["#{session.seq.toString(36)}:2:#{clientKey}", session]

  validateSession = (oldKey) ->
    sessionId = sessionKeys[oldKey]
    if not sessionId?
      [false, {error: 'Invalid Session Key', code: -1}]
    else
      session = sessions[sessionId]
      session.seq += 1
      session.expires = expiration()
      delete sessionKeys[oldKey]
      clientKey = newKey()
      key = digest(clientKey, oldKey)
      session.key = key
      sessionKeys[key] = sessionId
      ["#{session.seq.toString(36)}:2:#{clientKey}", session]

  auth = (keyRaw) ->
    splitKey = keyRaw.split(':')
    if splitKey.length isnt 3
      [false, {error: 'Invalid Key Format', code: -3}]
    else
      [seq, ver, key] = splitKey
      if ver isnt '1' and ver isnt '2'
        [false, {error: 'Unsupported Version', code: -2}]
      else if seq is '0'
        createSession(key)
      else
        validateSession(key)

  sessionCleaner = ->
    t = now()
    for key, sessionId of sessionKeys
      session = sessions[sessionId]
      if session.timeout < t
        console.log('expired session:', session)
        delete sessionKeys[session.key]
        delete sessions[session.id]
    nextClean = 1000-(now()-t)
    nextClean = 100 if nextClean < 100
    setTimeout(sessionCleaner, nextClean)

  setTimeout(sessionCleaner, config.timeoutFirst * 1000)

  {auth}
