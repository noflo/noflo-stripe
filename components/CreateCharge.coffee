# CreateCharge component creates a new charge.
#
# Input/output: https://stripe.com/docs/api/node#create_charge
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`
#  - `internal_error / missing_charge_amount`
#  - `internal_error / missing_charge_currency`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.inPorts.add 'data', datatype: 'object'
  component.inPorts.add 'apikey', datatype: 'string', (event, data) ->
    component.client = stripe data if event is 'data'
  component.outPorts.add 'charge', datatype: 'object'
  component.outPorts.add 'error', datatype: 'object'
  component.client = null

  noflo.helpers.MultiError component, 'stripe/CreateCharge'

  component.checkRequired = (chargeData, callback) ->
    unless chargeData.amount
      component.error CustomError "Missing amount",
        kind: 'internal_error'
        code: 'missing_charge_amount'
        param: 'amount'
    unless chargeData.currency
      component.error CustomError "Missing currency",
        kind: 'internal_error'
        code: 'missing_charge_currency'
        param: 'currency'
    return not component.hasErrors

  noflo.helpers.WirePattern component,
    in: 'data'
    out: 'charge'
    async: true
  , (chargeData, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    # Validate inputs
    unless component.checkRequired chargeData
      return callback no

    # Create Stripe charge
    component.client.charges.create chargeData, (err, charge) ->
      return callback err if err
      out.send charge
      callback()

  return component
