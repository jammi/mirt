'use strict'

module.exports = (auth, sync, reporter) ->

  sessionError = (req, res, error) ->
    res.status(401)
    res.json(["#{error.code}:2:",{},[error]])

  post: (req, res, next) ->
    [keyIn, valuesIn, messagesIn] = req.body
    [key, session] = auth(keyIn)
    if not key
      sessionError(req, res, session)
    else
      values = sync(session, valuesIn)
      res.json([key, values, []])
