# `CustomError` is an error class carrying additional information provided
# as its constructor argument.
module.exports = (message, options) ->
  err = new Error message
  for own key, val of options
    err[key] = val
  return err
