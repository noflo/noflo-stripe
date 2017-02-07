# GetCharge component fetches a charge object by ID.
#
# Input/output: https://stripe.com/docs/api/node#retrieve_charge
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
      charge:
        datatype: 'object'
      error:
        datatype: 'object'

  c.forwardBrackets =
    id: ['charge', 'error']

  c.process (input, output) ->
    return unless input.has 'id', 'apikey'

    id = input.getData 'id'
    client = stripe input.getData('apikey')

    client.charges.retrieve id, (err, charge) ->
      return output.done err if err
      output.sendDone charge
