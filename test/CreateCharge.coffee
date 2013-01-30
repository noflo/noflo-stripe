readenv = require "../components/CreateCharge"
socket = require('noflo').internalSocket

setupComponent = ->
  c = readenv.getComponent()
  ins = socket.createSocket()
  apiKey = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.in.attach ins
  c.inPorts.apikey.attach apiKey
  c.outPorts.out.attach out
  c.outPorts.error.attach err
  [c, ins, apiKey, out, err]

exports['test API key check'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data
    test.ok data.message
    test.equals data.message, 'Missing Stripe API key'

  err.once 'disconnect', ->
    test.done()

  ins.send
    currency: "EUR"
    amount: 1000000

exports['test currency check'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data
    test.ok data.message
    test.equals data.message, 'Missing currency'

  err.once 'disconnect', ->
    test.done()

  apiKey.send "Foo"

  ins.send
    amount: 1000000
    
exports['test amount check'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data
    test.ok data.message
    test.equals data.message, 'Missing amount'

  err.once 'disconnect', ->
    test.done()

  apiKey.send "Foo"

  ins.send
    currency: "EUR"
    
exports['test creating a charge'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  out.once 'data', (data) ->
    test.ok data

  out.once 'disconnect', ->
    test.done()
    
  err.once 'data', (data) ->
    test.fail null, null, new Error "Failed to create a charge"
    test.done()

  apiKey.send "Foo"

  ins.send
    currency: "EUR"
    amount: 5