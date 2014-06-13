CustomError = require './CustomError'

module.exports = (component, callback) ->
  unless component.client
    callback CustomError 'Missing Stripe API key',
      kind: 'internal_error'
      code: 'missing_stripe_key'
      param: 'apiKey'
    return false
  return true
