# ListCharges component runs a custom query and retrieves a list of charges.
#
# Input/output: https://stripe.com/docs/api/node#list_charges
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.inPorts.add 'exec',
    datatype: 'bang'
    required: true
    description: 'Runs the query passed to other ports'
  component.inPorts.add 'apikey',
    datatype: 'string'
    required: true
    description: 'Stripe API key'
  , (event, data) ->
    component.client = stripe data if event is 'data'
  component.inPorts.add 'customer',
    datatype: 'string'
    required: false
    description: 'Customer ID'
  , (event, data) ->
    component.customer = data if event is 'data'
  component.inPorts.add 'created',
    datatype: 'object'
    required: false
    description: 'Date filter, see stripe.com/docs/api/node#list_charges'
  , (event, data) ->
    component.created = data if event is 'data'
  component.inPorts.add 'endingBefore',
    datatype: 'string'
    required: false
    description: 'Pagination cursor, last object ID'
  , (event, data) ->
    component.endingBefore = data if event is 'data'
  component.inPorts.add 'limit',
    datatype: 'int'
    required: false
    description: 'Pagination limit, defaults to 10'
  , (event, data) ->
    component.limit = data if event is 'data'
  component.inPorts.add 'startingAfter',
    datatype: 'string'
    required: false
  , (event, data) ->
    component.startingAfter = data if event is 'data'

  component.outPorts.add 'charges',
    datatype: 'array'
    required: true
    description: 'List of charges'
  component.outPorts.add 'hasMore',
    datatype: 'boolean'
    required: false
    description: 'Whether there are more results, optional'
  component.outPorts.add 'error',
    datatype: 'object'

  component.client = null
  component.customer = null
  component.created = null
  component.endingBefore = null
  component.limit = null
  component.startingAfter = null

  noflo.helpers.MultiError component, 'stripe/ListCharges'

  noflo.helpers.WirePattern component,
    in: 'exec'
    out: ['charges', 'hasMore']
    async: true
    forwardGroups: true
  , (options, groups, outs, callback) ->
    unless CheckApiKey component, callback
      return

    # Compile the query
    query = {}
    query.customer = component.customer if component.customer
    query.created = component.created if component.created
    query.endingBefore = component.endingBefore if component.endingBefore
    query.limit = component.limit if component.limit
    query.startingAfter = component.startingAfter if component.startingAfter

    component.client.charges.list query, (err, charges) ->
      return callback err if err

      # Reset state to avoid side effects
      component.customer = null
      component.created = null
      component.endingBefore = null
      component.limit = null
      component.startingAfter = null

      outs.charges.send charges.data
      if component.outPorts.hasMore.isAttached()
        outs.hasMore charges.has_more
      callback()

  return component
