noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'

describe 'Charges', ->

  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  newCreateCharge = require('../components/CreateCharge').getComponent
  newGetCharge = require('../components/GetCharge').getComponent
  newUpdateCharge = require('../components/UpdateCharge').getComponent
  newRefundCharge = require('../components/RefundCharge').getComponent
  newListCharges = require('../components/ListCharges').getComponent

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

    it 'should retrieve a charge', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data).to.deep.equal charge
        done()

      ins.send charge.id

  describe 'UpdateCharge component', ->
    c = newUpdateCharge()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    desc = noflo.internalSocket.createSocket()
    meta = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.id.attach ins
    c.inPorts.apikey.attach key
    c.inPorts.description.attach desc
    c.inPorts.metadata.attach meta
    c.outPorts.charge.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send "foo-123"

    it 'should fail if neither description nor metadata was sent', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'has to be provided'
        done()

      ins.send charge.id

    it 'should update description or metadata of a charge', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).to.equal charge.id
        chai.expect(data.description).to.equal 'A charge for a test'
        chai.expect(data.metadata).to.deep.equal {foo: 'bar'}
        done()

      desc.send 'A charge for a test'
      meta.send
        foo: 'bar'
      ins.send charge.id

  describe 'RefundCharge component', ->
    c = newRefundCharge()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    amount = noflo.internalSocket.createSocket()
    wAppFee = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.id.attach ins
    c.inPorts.apikey.attach key
    c.inPorts.amount.attach amount
    c.inPorts.withAppFee.attach wAppFee
    c.outPorts.charge.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send "foo-123"

    it 'should refund a part of the charge if amount is provided', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).to.equal charge.id
        chai.expect(data.refunds).to.have.length 1
        chai.expect(data.refunds[0].amount).to.equal 20
        done()

      amount.send 20 # refund 20c
      ins.send charge.id

    it 'should refund entire sum left by default', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).to.equal charge.id
        chai.expect(data.refunds).to.have.length 2
        chai.expect(data.refunds[1].amount).to.equal 30
        done()

      ins.send charge.id

  describe 'ListCharges component', ->
    c = newListCharges()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    created = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.exec.attach ins
    c.inPorts.apikey.attach key
    c.inPorts.created.attach created
    c.outPorts.charges.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send true

    it 'should output an array of all charges', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'array'
        chai.expect(data).to.have.length.above 0
        done()

      ins.send true

    # TODO test other ListCharges parameters
