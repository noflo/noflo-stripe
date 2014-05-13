noflo = require 'noflo'
stripe = require 'stripe'

class CreateCardToken extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts = new noflo.InPorts
      card:
        datatype: 'object'
        required: true
        description: 'Credit card details'
      apikey:
        datatype: 'string'
        required: true
        description: 'Stripe API key'
    @outPorts = new noflo.OutPorts
      token:
        datatype: 'object'
        description: 'New token'
      error:
        datatype: 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super 'card', 'token'

  checkRequired: (card, callback) ->
    unless card.number
      return callback new Error "Missing card number"
    unless card.exp_month or card.exp_month < 1 or card.exp_month > 12
      return callback new Error "Missing or invalid expiration month"
    unless card.exp_year or card.exp_year < 0 or card.exp_year > 2100
      return callback new Error "Missing or invalid expiration year"
    callback()

  doAsync: (card, callback) ->
    unless @client
      return callback new Error "Missing Stripe API key"

    # Validate inputs
    @checkRequired card, (err) =>
      return callback err if err

      data =
        card: card

      # Create Stripe token
      @client.tokens.create data, (err, token) =>
        return callback err if err
        @outPorts.token.send token
        @outPorts.token.disconnect()
        callback()

exports.getComponent = -> new CreateCardToken
