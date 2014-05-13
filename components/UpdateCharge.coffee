noflo = require 'noflo'
stripe = require 'stripe'

class UpdateCharge extends noflo.AsyncComponent
  constructor: ->
    @client = null
    @description = null
    @metadata = null

    @inPorts =
      id: new noflo.Port 'string'
      apikey: new noflo.Port 'string'
      description: new noflo.Port 'string'
      metadata: new noflo.Port 'object'
    @outPorts =
      charge: new noflo.Port 'object'
      error: new noflo.Port 'object'

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data
    @inPorts.description.on 'data', (@description) =>
    @inPorts.metadata.on 'data', (@metadata) =>

    super 'id', 'charge'

  doAsync: (id, callback) ->
    unless @client
      return callback new Error 'Missing or invalid Stripe API key'

    unless @description or @metadata
      return callback new Error 'Description or metadata has to be provided'

    data = {}
    data.description = @description if @description
    data.metadata = @metadata if @metadata

    @client.charges.update id, data, (err, charge) =>
      return callback err if err

      @description = null
      @metadata = null
      @outPorts.charge.send charge
      @outPorts.charge.disconnect()
      callback()

exports.getComponent = -> new UpdateCharge
