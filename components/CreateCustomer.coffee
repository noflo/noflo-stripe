# CreateCardToken component creates a new credit card token.
#
# Input/output: https://stripe.com/docs/api/node#create_customer
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`
#  - `customer_error / missing_customer_email`

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
      customer:
        datatype: 'object'
      error:
        datatype: 'object'

  # forwarding to error would make it fail
  # since noflo-tester receives on disconnect
  c.forwardBrackets =
    data: ['customer']

  c.checkRequired = (customerData, callback) ->
    errors = []
    unless customerData.email
      errors.push noflo.helpers.CustomError "Missing email",
        kind: 'customer_error'
        code: 'missing_customer_email'
        param: 'email'
    return errors

  c.process (input, output) ->
    # copied from createCardTokem
    return unless input.has 'data', 'apikey'

    customerData = input.getData 'data'
    client = stripe input.getData('apikey')

    # Validate inputs
    errors = c.checkRequired customerData
    if errors.length > 0
      return output.done errors

    # Create Stripe customer
    client.customers.create customerData, (err, customer) ->
      return output.done err if err
      output.sendDone customer
