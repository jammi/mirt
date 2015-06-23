'use strict'

mirtPOST = require './mirt-post'
mirtSession = require './mirt-session'

valueManager = ->
  sync: (session, values) ->
    # console.log('session:', session)
    # console.log('values:', values)
    {}

module.exports =
  post: mirtPOST(
    mirtSession().auth,
    valueManager().sync
  ).post
