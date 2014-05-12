readenv = require "../components/CreateCharge"
socket = require('noflo').internalSocket

setupComponent = ->
  c = readenv.getComponent()
  ins = socket.createSocket()
  apiKey = socket.createSocket()
  out = socket.createSocket()
  err = socket.createSocket()
  c.inPorts.data.attach ins
  c.inPorts.apikey.attach apiKey
  c.outPorts.charge.attach out
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
  unless process.env.STRIPE_TOKEN
    test.fail null, null, 'No STRIPE_TOKEN env variable set'
    test.done()
    return

  [c, ins, apiKey, out, err] = setupComponent()
  out.once 'data', (data) ->
    test.ok data
    test.ok data.id
    test.ok data.object
    test.equals data.object, 'charge'
    test.equals data.paid, true
    test.equals data.amount, 50
    test.equals data.currency, 'usd'

  out.once 'disconnect', ->
    test.done()

  err.once 'data', (data) ->
    test.fail null, null, new Error "Failed to create a charge"
    test.done()

  apiKey.send process.env.STRIPE_TOKEN

  # Charge 50c
  ins.send
    currency: "usd"
    amount: 50
    card:
      number: "4242424242424242"
      exp_month: 12
      exp_year:  2020
      name: "T. Ester"
