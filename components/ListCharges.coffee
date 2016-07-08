# ListCharges component runs a custom query and retrieves a list of charges.
#
# Input/output: https://stripe.com/docs/api/node#list_charges
# Errors:
#  - https://stripe.com/docs/api/node#errors
#  - `internal_error / missing_stripe_key`

noflo = require 'noflo'
stripe = require 'stripe'

exports.getComponent = ->
  c = new noflo.Component
    inPorts:
      exec:
        datatype: 'bang'
        required: true
        description: 'Runs the query passed to other ports'
      apikey:
        datatype: 'string'
        required: true
        description: 'Stripe API key'
        control: true
        triggering: false
      customer:
        datatype: 'string'
        required: false
        description: 'Customer ID'
        control: true
        triggering: false
      created:
        datatype: 'object'
        required: false
        description: 'Date filter, see stripe.com/docs/api/node#list_charges'
        control: true
        triggering: false
      endingbefore:
        datatype: 'string'
        required: false
        description: 'Pagination cursor, last object ID'
        control: true
        triggering: false
      limit:
        datatype: 'int'
        required: false
        description: 'Pagination limit, defaults to 10'
        control: true
        triggering: false
      startingafter:
        datatype: 'string'
        required: false
        control: true
        triggering: false
    outPorts:
      charges:
        datatype: 'array'
        required: true
        description: 'List of charges'
      hasmore:
        datatype: 'boolean'
        required: false
        description: 'Whether there are more results, optional'
      error:
        datatype: 'object'

  c.forwardBrackets =
    exec: ['charges', 'hasmore', 'error']

  c.process (input, output) ->
    return unless input.has 'exec'

    input.buffer.set 'exec', []

    client = stripe input.getData('apikey')

    customer = input.getData 'customer'
    created = input.getData 'created'
    endingbefore = input.getData 'endingbefore'
    limit = input.getData 'limit'
    startingafter = input.getData 'startingafter'

    # Compile the query
    query = {}
    query.customer = customer if customer
    query.created = created if created
    query.endingbefore = endingbefore if endingbefore
    query.limit = limit if limit
    query.startingafter = startingafter if startingafter

    client.charges.list query, (err, charges) ->
      return output.done err if err

      output.send charges: charges.data

      if output.ports.hasmore.isAttached()
        output.send hasmore: charges.has_more

      output.done()

