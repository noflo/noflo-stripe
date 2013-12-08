noflo = require 'noflo'
stripe = require 'stripe'

class RetreiveToken extends noflo.AsyncComponent
  constructor: ->
    @client = null

    @inPorts =
      in: new noflo.Port 'string'
      apikey: new noflo.Port 'string'
    @outPorts =
      out: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data

    super()
    
  checkRequired: (token, callback) ->
    unless token
      return callback new Error "Missing token id"
    do callback

  doAsync: (token, callback) ->
    unless @client
      callback new Error "Missing Stripe API key"
      return
    
    # Validate inputs
    @checkRequired token, (err) =>
      return callback err if err

      # Retrieve Stripe Token
      @client.tokens.retrieve token, (err, tokenData) =>
        return callback err if err
        @outPorts.out.send tokenData
        @outPorts.out.disconnect()
        callback()

exports.getComponent = -> new RetreiveToken