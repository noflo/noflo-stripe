# RefundCharge sends a request to refund a charge in part or in full.
#
# Input/output: https://stripe.com/docs/api/node#refund_charge
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.inPorts.add 'id',
    datatype: 'string'
    required: true
    description: 'Charge ID'
  component.inPorts.add 'amount',
    datatype: 'int'
    required: false
    description: 'Amount in the smallest currency units,
      default is entire charge'
  , (event, payload) ->
    component.amount = payload if event is 'data'
  component.inPorts.add 'withappfee',
    datatype: 'boolean'
    required: false
    description: 'Attempt to refund application fee'
  , (event, payload) ->
    component.withappfee = payload if event is 'data'
  component.inPorts.add 'apikey', datatype: 'string', (event, payload) ->
    component.client = stripe payload if event is 'data'
  component.outPorts.add 'refund',
    datatype: 'object'
    description: 'Created refund object'
  component.outPorts.add 'error', datatype: 'object'

  component.client = null
  component.withappfee = null

  noflo.helpers.MultiError component, 'stripe/RefundCharge'

  noflo.helpers.WirePattern component,
    in: 'id'
    out: 'refund'
    async: true
    forwardGroups: true
  , (id, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    data = {}
    data.amount = component.amount if component.amount > 0
    data.refund_application_fee = true if component.withappfee

    component.client.charges.createRefund id, data, (err, refund) ->
      return callback err if err

      component.amount = null
      component.withappfee = false
      out.send refund
      callback()

  return component
