noflo = require 'noflo'
stripe = require 'stripe'

class GetCharge extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts =
      id: new noflo.Port 'string'
      apikey: new noflo.Port 'string'
    @outPorts =
      charge: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super 'id', 'charge'

  doAsync: (id, callback) ->
    unless @client
      return callback new Error 'Missing or invalid Stripe API key'

    @client.charges.retrieve id, (err, charge) =>
      return callback err if err

      @outPorts.charge.send charge
      @outPorts.charge.disconnect()
      callback()

exports.getComponent = -> new GetCharge
