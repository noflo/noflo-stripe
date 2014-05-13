noflo = require 'noflo'
stripe = require 'stripe'

class RefundCharge extends noflo.AsyncComponent
  constructor: ->
    @client = null
    @amount = null
    @withAppFee = null

    @inPorts =
      id: new noflo.Port 'string'
      apikey: new noflo.Port 'string'
      amount: new noflo.Port 'int'
      withAppFee: new noflo.Port 'boolean'
    @outPorts =
      charge: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data
    @inPorts.amount.on 'data', (@amount) =>
    @inPorts.withAppFee.on 'data', (@withAppFee) =>

    super 'id', 'charge'

  doAsync: (id, callback) ->
    unless @client
      return callback new Error 'Missing or invalid Stripe API key'

    data = {}
    data.amount = @amount if @amount > 0
    data.refund_application_fee = true if @withAppFee

    @client.charges.refund id, data, (err, charge) =>
      return callback err if err

      @amount = null
      @withAppFee = false
      @outPorts.charge.send charge
      @outPorts.charge.disconnect()
      callback()

exports.getComponent = -> new RefundCharge
