# CreateCardToken component creates a new credit card token.
#
# Input/output: https://stripe.com/docs/api/node#create_customer
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`
#  - `customer_error / missing_customer_email`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.inPorts.add 'data', datatype: 'object'
  component.inPorts.add 'apikey', datatype: 'string', (event, payload) ->
    component.client = stripe payload if event is 'data'
  component.outPorts.add 'customer', datatype: 'object'
  component.outPorts.add 'error', datatype: 'object'
  component.client = null

  noflo.helpers.MultiError component, 'stripe/CreateCustomer'

  component.checkRequired = (customerData, callback) ->
    unless customerData.email
      component.error CustomError "Missing email",
        kind: 'customer_error'
        code: 'missing_customer_email'
        param: 'email'
    return not component.hasErrors

  noflo.helpers.WirePattern component,
    in: 'data'
    out: 'customer'
    async: true
    forwardGroups: true
  , (customerData, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    # Validate inputs
    unless component.checkRequired customerData
      return callback no

    # Create Stripe customer
    component.client.customers.create customerData, (err, customer) ->
      return callback err if err
      out.send customer
      callback()

  return component
