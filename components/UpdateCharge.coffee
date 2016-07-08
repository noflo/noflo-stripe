# UpdateCharge component updates a description or metadata
# for an existing charge.
#
# Input/output: https://stripe.com/docs/api/node#update_charge
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
      apikey:
        datatype: 'string'
        required: true
        control: true
      description:
        datatype: 'string'
        required: false
        description: 'Charge description (optional if metadata is provided)'
        control: true
      metadata:
        datatype: 'object'
        required: false
        description: 'Charge metadata (optional if description is provided)'
        control: true
    outPorts:
      charge:
        datatype: 'object'
      error:
        datatype: 'object'

  c.forwardBrackets =
    id: ['refund', 'error']

  c.process (input, output) ->
    return unless input.has 'id', (ip) -> ip.type is 'data'
    return unless input.has 'apikey'

    id = input.getData 'id'

    metadata = input.getData 'metadata'
    description = input.getData 'description'
    client = stripe input.getData('apikey')

    unless description or metadata
      return output.done noflo.helpers.CustomError 'Description
      or metadata has to be provided',
        kind: 'internal_error'
        code: 'missing_charge_update_data'
        param: if description then 'metadata' else 'description'

    data = {}
    data.description = description if description
    data.metadata = metadata if metadata

    client.charges.update id, data, (err, charge) ->
      return output.done err if err
      output.sendDone charge
