# RetrieveToken component fetches a token object by ID.
#
# Input/output: https://stripe.com/docs/api/node#retrieve_token
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'

exports.getComponent = ->
  c = new noflo.Component
    inPorts:
      id:
        datatype: 'string'
      apikey:
        datatype: 'string'
        control: true
    outPorts:
      token:
        datatype: 'object'
      error:
        datatype: 'object'

  c.forwardBrackets =
    id: ['token']

  c.process (input, output) ->
    return unless input.has 'id', 'apikey'

    id = input.getData 'id'
    client = stripe input.getData('apikey')

    # Retrieve Stripe Token
    client.tokens.retrieve id, (err, tokenData) ->
      return output.done err if err
      output.sendDone tokenData
