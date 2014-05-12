noflo = require 'noflo'
stripe = require 'stripe'

class CreateCharge extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts =
      data: new noflo.Port 'object'
      apikey: new noflo.Port 'string'
    @outPorts =
      charge: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super 'data', 'charge'

  checkRequired: (chargeData, callback) ->
    unless chargeData.amount
      return callback new Error "Missing amount"
    unless chargeData.currency
      return callback new Error "Missing currency"
    callback()

  doAsync: (chargeData, callback) ->
    unless @client
      return callback new Error "Missing Stripe API key"

    # Validate inputs
    @checkRequired chargeData, (err) =>
      return callback err if err

      # Create Stripe charge
      @client.charges.create chargeData, (err, charge) =>
        return callback err if err
        @outPorts.charge.send charge
        @outPorts.charge.disconnect()
        callback()

exports.getComponent = -> new CreateCharge
