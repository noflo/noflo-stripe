# CreateCardToken component creates a new credit card token.
#
# Input/output: https://stripe.com/docs/api/node#create_card_token
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = require '../lib/CustomError'
CheckApiKey = require '../lib/CheckApiKey'

exports.getComponent = ->
  component = new noflo.Component

  component.client = null

  component.inPorts.add 'card',
    datatype: 'object'
    required: true
    description: 'Credit card details'
  component.inPorts.add 'apikey',
    datatype: 'string'
    required: true
    description: 'Stripe API key'
  , (event, data) ->
    component.client = stripe data if event is 'data'

  component.outPorts.add 'token',
    datatype: 'object'
    description: 'New token'
  component.outPorts.add 'error',
    datatype: 'object'

  noflo.helpers.MultiError component, 'stripe/CreateCardToken'

  component.checkRequired = (card, callback) ->
    unless card.number
      component.error CustomError "Missing card number",
        kind: 'card_error'
        code: 'invalid_number'
        param: 'number'
    unless card.exp_month or card.exp_month < 1 or card.exp_month > 12
      component.error CustomError "Missing or invalid expiration month",
        kind: 'card_error'
        code: 'invalid_expiry_month'
        param: 'exp_month'
    unless card.exp_year or card.exp_year < 0 or card.exp_year > 2100
      component.error CustomError "Missing or invalid expiration year",
        kind: 'card_error'
        code: 'invalid_expiry_year'
        param: 'exp_year'
    return not component.hasErrors

  noflo.helpers.WirePattern component,
    in: 'card'
    out: 'token'
    async: true
    forwardGroups: true
  , (card, groups, out, callback) ->
    unless CheckApiKey component, callback
      return

    # Validate inputs
    unless component.checkRequired card
      return callback no

    # Create Stripe token
    data =
      card: card
    component.client.tokens.create data, (err, token) ->
      return callback err if err
      out.send token
      callback()

  return component
