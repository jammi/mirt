'use strict'

mirtPOST = require './mirt-post'
mirtSession = require './mirt-session'
mirtValues = require './mirt-values'

module.exports =
  post: mirtPOST(
    mirtSession().auth,
    mirtValues({
      initValues: [
        # ['server.hello', 'Hi, says server!']
      ]
    }).syncServer
  ).post
