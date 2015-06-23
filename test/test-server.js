(function() {
  'use strict';
  var init;

  init = function(host, port) {
    var app, bodyParser, client, express, mirt, server, testClient;
    express = require('express');
    app = express();
    bodyParser = require('body-parser');
    app.use(bodyParser.json());
    mirt = require('../lib/mirt/mirt');
    app.post('/x', mirt.post);
    app.post('/hello', mirt.post);
    server = app.listen(port, host, function() {
      return console.log("MIRT test server listening at http://" + host + ":" + port);
    });
    client = require('../lib/mirt/mirt-client');
    testClient = client({
      host: host,
      port: port,
      path: '/'
    });
    return testClient.sync();
  };

  init('127.0.0.1', 8001);

}).call(this);
