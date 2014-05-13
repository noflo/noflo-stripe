noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'

describe 'Tokens', ->

  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  newCreateCardToken = require('../components/CreateCardToken').getComponent
  newRetrieveToken = require('../components/RetrieveToken').getComponent

  token = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCardToken component', ->
    c = newCreateCardToken()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.card.attach ins
    c.inPorts.apikey.attach key
    c.outPorts.token.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send
        number: "4242"

    it 'should fail if card number is missing', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing card number'
        done()

      ins.send
        name: 'T. Ester'

    it 'should fail if expiry month is missing', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'month'
        done()

      ins.send
        number: "4242424242424242"
        name: "T. Ester"

    it 'should fail if expiry year is missing', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'year'
        done()

      ins.send
        number: "4242424242424242"
        name: "T. Ester"
        exp_month: 12

    it 'should create a new token', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'token'
        chai.expect(data.used).to.be.false
        chai.expect(data.type).to.equal 'card'
        chai.expect(data.card).to.be.an 'object'
        # Save charge object for later reuse
        token = data
        done()

      err.once 'data', (data) ->
        assert.fail data, null
        done data

      ins.send
        number: "4242424242424242"
        exp_month: 12
        exp_year:  2020
        name: "T. Ester"

  describe 'RetrieveToken component', ->
    c = newRetrieveToken()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.id.attach ins
    c.inPorts.apikey.attach key
    c.outPorts.token.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send "foo-123"

    it 'should fail if non-existend ID is provided', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.type).to.equal 'StripeInvalidRequest'
        chai.expect(data.param).to.equal 'token'
        done()

      ins.send "foo-random-invalid-" + uuid.v4()

    it 'should retrieve a token', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data).to.deep.equal token
        done()

      ins.send token.id
