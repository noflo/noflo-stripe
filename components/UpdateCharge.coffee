# UpdateCharge component updates a description or metadata
# for an existing charge.
#
# Input/output: https://stripe.com/docs/api/node#update_charge
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
  component.inPorts.add 'apikey',
    datatype: 'string'
    required: true
  , (event, payload) ->
    component.client = stripe payload if event is 'data'
  component.inPorts.add 'description',
    datatype: 'string'
    required: false
    description: 'Charge description (optional if metadata is provided)'
  , (event, payload) ->
    component.description = payload if event is 'data'
  component.inPorts.add 'metadata',
    datatype: 'object'
    required: false
    description: 'Charge metadata (optional if description is provided)'
  , (event, payload) ->
    component.metadata = payload if event is 'data'
  component.outPorts.add 'charge', datatype: 'object'
  component.outPorts.add 'error', datatype: 'object'

  component.client = null
  component.description = null
  component.metadata = null

  noflo.helpers.MultiError component, 'stripe/UpdateCharge'

  noflo.helpers.WirePattern component,
    in: 'id'
    out: 'charge'
    async: true
    forwardGroups: true
  , (id, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    unless component.description or component.metadata
      return callback CustomError 'Description or metadata has to be provided',
        kind: 'internal_error'
        code: 'missing_charge_update_data'
        param: if component.description then 'metadata' else 'description'

    data = {}
    data.description = component.description if component.description
    data.metadata = component.metadata if component.metadata

    component.client.charges.update id, data, (err, charge) ->
      return callback err if err

      component.description = null
      component.metadata = null
      out.send charge
      callback()

  return component
