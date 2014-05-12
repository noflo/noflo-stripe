noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'

describe 'Charges', ->

  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  newCreateCharge = require('../components/CreateCharge').getComponent
  newGetCharge = require('../components/GetCharge').getComponent

  charge = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCharge component', ->
    c = newCreateCharge()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.data.attach ins
    c.inPorts.apikey.attach key
    c.outPorts.charge.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send
        currency: 'usd'
        amount: 10000

    it 'should fail if currency is missing', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing currency'
        done()

      ins.send
        amount: 1000000

    it 'should fail if amount is missing', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing amount'
        done()

      ins.send
        currency: 'EUR'

    it 'should create a new charge', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'charge'
        chai.expect(data.paid).to.be.true
        chai.expect(data.amount).to.equal 50
        chai.expect(data.currency).to.equal 'usd'
        # Save charge object for later reuse
        charge = data
        done()

      err.once 'data', (data) ->
        assert.fail data, null
        done data

      # Charge 50c
      ins.send
        currency: "usd"
        amount: 50
        card:
          number: "4242424242424242"
          exp_month: 12
          exp_year:  2020
          name: "T. Ester"

  describe 'GetCharge component', ->
    c = newGetCharge()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.id.attach ins
    c.inPorts.apikey.attach key
    c.outPorts.charge.attach out
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
        chai.expect(data.param).to.equal 'id'
        done()

      ins.send "foo-random-invalid-" + uuid.v4()


