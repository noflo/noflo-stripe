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
  component.inPorts.add 'endingbefore',
    datatype: 'string'
    required: false
    description: 'Pagination cursor, last object ID'
  , (event, data) ->
    component.endingbefore = data if event is 'data'
  component.inPorts.add 'limit',
    datatype: 'int'
    required: false
    description: 'Pagination limit, defaults to 10'
  , (event, data) ->
    component.limit = data if event is 'data'
  component.inPorts.add 'startingafter',
    datatype: 'string'
    required: false
  , (event, data) ->
    component.startingafter = data if event is 'data'

  component.outPorts.add 'charges',
    datatype: 'array'
    required: true
    description: 'List of charges'
  component.outPorts.add 'hasmore',
    datatype: 'boolean'
    required: false
    description: 'Whether there are more results, optional'
  component.outPorts.add 'error',
    datatype: 'object'

  component.client = null
  component.customer = null
  component.created = null
  component.endingbefore = null
  component.limit = null
  component.startingafter = null

  noflo.helpers.MultiError component, 'stripe/ListCharges'

  noflo.helpers.WirePattern component,
    in: 'exec'
    out: ['charges', 'hasmore']
    async: true
    forwardGroups: true
  , (options, groups, outs, callback) ->
    unless CheckApiKey component, callback
      return

    # Compile the query
    query = {}
    query.customer = component.customer if component.customer
    query.created = component.created if component.created
    query.endingbefore = component.endingbefore if component.endingbefore
    query.limit = component.limit if component.limit
    query.startingafter = component.startingafter if component.startingafter

    component.client.charges.list query, (err, charges) ->
      return callback err if err

      # Reset state to avoid side effects
      component.customer = null
      component.created = null
      component.endingbefore = null
      component.limit = null
      component.startingafter = null

      outs.charges.send charges.data
      if component.outPorts.hasmore.isAttached()
        outs.hasmore.send charges.has_more
      callback()

  return component
