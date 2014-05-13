noflo = require 'noflo'
stripe = require 'stripe'

class ListCharges extends noflo.AsyncComponent
  constructor: ->
    @inPorts = new noflo.InPorts
      exec:
        datatype: 'bang'
        required: true
        description: 'Runs the query passed to other ports'
      apikey:
        datatype: 'string'
        required: true
        description: 'Stripe API key'
      customer:
        datatype: 'string'
        required: false
        description: 'Customer ID'
      created:
        datatype: 'object'
        required: false
        description: 'Date filter, see stripe.com/docs/api/node#list_charges'
      endingBefore:
        datatype: 'string'
        required: false
        description: 'Pagination cursor, last object ID'
      limit:
        datatype: 'int'
        required: false
        description: 'Pagination limit, defaults to 10'
      startingAfter:
        datatype: 'string'
        required: false

    @outPorts = new noflo.OutPorts
      charges:
        datatype: 'array'
        required: true
        description: 'List of charges'
      hasMore:
        datatype: 'boolean'
        required: false
        description: 'Whether there are more results, optional'
      error:
        datatype: 'object'

    @client = null
    @customer = null
    @created = null
    @endingBefore = null
    @limit = null
    @startingAfter = null

    @inPorts.apikey.on 'data', (data) =>
      @client = stripe data
    @inPorts.customer.on 'data', (@customer) =>
    @inPorts.created.on 'data', (@created) =>
    @inPorts.endingBefore.on 'data', (@endingBefore) =>
    @inPorts.limit.on 'data', (@limit) =>
    @inPorts.startingAfter.on 'data', (@startingAfter) =>

    super 'exec', 'charges'

  doAsync: (options, callback) ->
    unless @client
      return callback new Error 'Missing or invalid Stripe API key'

    # Compile the query
    query = {}
    query.customer = @customer if @customer
    query.created = @created if @created
    query.endingBefore = @endingBefore if @endingBefore
    query.limit = @limit if @limit
    query.startingAfter = @startingAfter if @startingAfter

    @client.charges.list query, (err, charges) =>
      return callback err if err

      # Reset state to avoid side effects
      @customer = null
      @created = null
      @endingBefore = null
      @limit = null
      @startingAfter = null

      @outPorts.charges.send charges.data
      @outPorts.charges.disconnect()
      if @outPorts.hasMore.isAttached()
        @outPorts.hasMore.send charges.has_more
        @outPorts.hasMore.disconnect()
      callback()

exports.getComponent = -> new ListCharges
