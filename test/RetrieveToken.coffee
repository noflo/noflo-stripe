retrieve = require "../components/RetrieveToken"
socket = require('noflo').internalSocket

setupComponent = ->
  c = retrieve.getComponent()
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
    
  ins.send 'foo bar'

exports['test invalid API key'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data

  err.once 'disconnect', ->
    test.done()

  apiKey.send "Foo"

  ins.send "usd"
    
exports['test retreiving token'] = (test) ->
  unless process.env.STRIPE_TOKEN
    test.fail null, null, 'No STRIPE_TOKEN env variable set'
    test.done()
    return
      
  [c, ins, apiKey, out, err] = setupComponent()
  out.once 'data', (data) ->
    test.ok data
    test.ok data.id
    test.equals data.id, 'tok_1034Th2eZvKYlo2C1aFXaoRA'

  out.once 'disconnect', ->
    test.done()
    
  err.once 'data', (data) ->
    test.fail null, null, new Error "Failed to retreive a token"
    test.done()

  apiKey.send process.env.STRIPE_TOKEN

  # retreive token with id "tok_1034Th2eZvKYlo2C1aFXaoRA"
  ins.send "tok_1034Th2eZvKYlo2C1aFXaoRA"


