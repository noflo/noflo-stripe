# GetCharge component fetches a charge object by ID.
#
# Input/output: https://stripe.com/docs/api/node#retrieve_charge
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.inPorts.add 'id', datatype: 'string'
  component.inPorts.add 'apikey', datatype: 'string', (event, payload) ->
    component.client = stripe payload if event is 'data'
  component.outPorts.add 'charge', datatype: 'object'
  component.outPorts.add 'error', datatype: 'object'
  component.client = null

  noflo.helpers.MultiError component, 'stripe/GetCharge'

  noflo.helpers.WirePattern component,
    in: 'id'
    out: 'charge'
    async: true
    forwardGroups: true
  , (id, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    component.client.charges.retrieve id, (err, charge) ->
      return callback err if err

      out.send charge
      callback()

  return component
