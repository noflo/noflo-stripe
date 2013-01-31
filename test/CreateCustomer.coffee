readenv = require "../components/CreateCustomer"
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

exports['test invalid API key'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data

  err.once 'disconnect', ->
    test.done()

  apiKey.send "Foo"

  ins.send
    currency: "usd"


exports['test email check'] = (test) ->
  [c, ins, apiKey, out, err] = setupComponent()
  err.once 'data', (data) ->
    test.ok data
    test.ok data.message
    test.equals data.message, 'Missing email'

  err.once 'disconnect', ->
    test.done()

  apiKey.send "Foo"

  ins.send
    amount: 1000000    

        
exports['test creating a customer'] = (test) ->
  unless process.env.STRIPE_TOKEN
    test.fail null, null, 'No STRIPE_TOKEN env variable set'
    test.done()
    return
      
  [c, ins, apiKey, out, err] = setupComponent()
  out.once 'data', (data) ->
    console.log data
    test.ok data
    test.ok data.id
    test.ok data.object
    test.equals data.object, 'customer'
    test.equals data.email, 'foo@example.com'


  out.once 'disconnect', ->
    test.done()
    
  err.once 'data', (data) ->
    test.fail null, null, new Error "Failed to create a customer"
    test.done()

  apiKey.send process.env.STRIPE_TOKEN

  # Charge 50c
  ins.send
    email: "foo@example.com"