noflo = require 'noflo'
stripe = require 'stripe'

class CreateCustomer extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts =
      data: new noflo.Port 'object'
      apikey: new noflo.Port 'string'
    @outPorts =
      customer: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super 'data', 'customer'

  checkRequired: (customerData, callback) ->
    unless customerData.email
      return callback new Error "Missing email"
    callback()

  doAsync: (customerData, callback) ->
    unless @client
      return callback new Error "Missing or invalid Stripe API key"

    # Validate inputs
    @checkRequired customerData, (err) =>
      return callback err if err

      # Create Stripe customer
      @client.customers.create customerData, (err, customer) =>
        return callback err if err
        @outPorts.customer.send customer
        @outPorts.customer.disconnect()
        callback()

exports.getComponent = -> new CreateCustomer
