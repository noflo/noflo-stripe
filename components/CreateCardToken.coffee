# CreateCardToken component creates a new credit card token.
#
# Input/output: https://stripe.com/docs/api/node#create_card_token
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'
CustomError = noflo.helpers.CustomError

exports.getComponent = ->
  c = new noflo.Component
    inPorts:
      card:
        datatype: 'object'
        description: 'Credit card details'
      apikey:
        datatype: 'string'
        description: 'Stripe API key'
        control: true
    outPorts:
      token:
        datatype: 'object'
        description: 'New token'
      error:
        datatype: 'object'

  c.forwardBrackets =
    card: ['token', 'error']

  c.checkRequired = (card) ->
    errors = []
    unless card.number
      errors.push CustomError "Missing card number",
        kind: 'card_error'
        code: 'invalid_number'
        param: 'number'
    unless card.exp_month or card.exp_month < 1 or card.exp_month > 12
      errors.push CustomError "Missing or invalid expiration month",
        kind: 'card_error'
        code: 'invalid_expiry_month'
        param: 'exp_month'
    unless card.exp_year or card.exp_year < 0 or card.exp_year > 2100
      errors.push CustomError "Missing or invalid expiration year",
        kind: 'card_error'
        code: 'invalid_expiry_year'
        param: 'exp_year'
    return errors

  c.process (input, output) ->
    return unless input.has 'card', 'apikey'

    card = input.getData 'card'
    client = stripe input.getData('apikey')

    # Validate inputs
    errors = c.checkRequired card
    if errors.length > 0
      return output.done errors

    # Create Stripe token
    data =
      card: card

    client.tokens.create data, (err, token) ->
      return output.done err if err
      output.sendDone token
