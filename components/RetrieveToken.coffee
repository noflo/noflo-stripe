# RetrieveToken component fetches a token object by ID.
#
# Input/output: https://stripe.com/docs/api/node#retrieve_token
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
  component.outPorts.add 'token', datatype: 'object'
  component.outPorts.add 'error', datatype: 'object'
  component.client = null

  noflo.helpers.MultiError component, 'stripe/RetrieveToken'

  noflo.helpers.WirePattern component,
    in: 'id'
    out: 'token'
    async: true
    forwardGroups: true
  , (id, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    # Retrieve Stripe Token
    component.client.tokens.retrieve id, (err, tokenData) ->
      return callback err if err
      out.send tokenData
      callback()

  return component
