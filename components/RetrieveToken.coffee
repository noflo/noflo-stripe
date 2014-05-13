noflo = require 'noflo'
stripe = require 'stripe'

class RetreiveToken extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts =
      id: new noflo.Port 'string'
      apikey: new noflo.Port 'string'
    @outPorts =
      token: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super 'id', 'token'

  doAsync: (id, callback) ->
    unless @client
      return callback new Error "Missing or invalid Stripe API key"

    # Retrieve Stripe Token
    @client.tokens.retrieve id, (err, tokenData) =>
      return callback err if err
      @outPorts.token.send tokenData
      @outPorts.token.disconnect()
      callback()

exports.getComponent = -> new RetreiveToken