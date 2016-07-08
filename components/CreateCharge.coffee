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

exports.getComponent = ->
  c = new noflo.Component
    inPorts:
      data:
        datatype: 'object'
      apikey:
        datatype: 'string'
        control: true
    outPorts:
      charge:
        datatype: 'object'
      error:
        datatype: 'object'

  c.forwardBrackets =
    data: ['charge', 'error']

  c.checkRequired = (chargeData, callback) ->
    errors = []
    unless chargeData.amount
      errors.push noflo.helpers.CustomError "Missing amount",
        kind: 'internal_error'
        code: 'missing_charge_amount'
        param: 'amount'
    unless chargeData.currency
      errors.push noflo.helpers.CustomError "Missing currency",
        kind: 'internal_error'
        code: 'missing_charge_currency'
        param: 'currency'
    return errors

  c.process (input, output) ->
    return unless input.has 'data', 'apikey'
    client = stripe input.getData('apikey')
    chargeData = input.getData 'data'

    errors = c.checkRequired chargeData
    if errors.length > 0
      return output.done errors

    # Create Stripe charge
    client.charges.create chargeData, (err, charge) ->
      return output.done err if err
      output.sendDone charge
