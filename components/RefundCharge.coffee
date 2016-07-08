# RefundCharge sends a request to refund a charge in part or in full.
#
# Input/output: https://stripe.com/docs/api/node#refund_charge
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
        required: true
        description: 'Charge ID'
      amount:
        datatype: 'int'
        required: false
        description: 'Amount in the smallest currency units,
          default is entire charge'
        control: true
      withappfee:
        datatype: 'boolean'
        required: false
        description: 'Attempt to refund application fee'
        control: true
      apikey:
        datatype: 'string'
        control: true
    outPorts:
      refund:
        datatype: 'object'
        description: 'Created refund object'
      error:
        datatype: 'object'

  c.forwardBrackets =
    id: ['refund', 'error']

  c.process (input, output) ->
    return unless input.has 'id', (ip) -> ip.type is 'data'
    return unless input.has 'apikey'

    id = input.getData 'id'
    amount = input.getData 'amount'
    withappfee = input.getData 'withappfee'
    client = stripe input.getData('apikey')

    data = {}
    data.amount = amount if amount > 0
    data.refund_application_fee = true if withappfee

    client.charges.createRefund id, data, (err, refund) ->
      return output.done err if err
      output.sendDone refund
