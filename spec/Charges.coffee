noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'
Tester = require 'noflo-tester'

describe 'Charges', ->
  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  charge = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCharge component', ->
    t = new Tester 'stripe/CreateCharge'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'data',
        currency: 'usd'
        amount: 10000

    it 'should fail if currency is missing', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing currency'
        done()

      t.send 'data',
        amount: 1000000

    it 'should fail if amount is missing', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing amount'
        done()

      t.send 'data',
        currency: 'EUR'

    it 'should create a new charge', (done) ->
      t.receive 'charge', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'charge'
        chai.expect(data.paid).to.be.true
        chai.expect(data.amount).to.equal 50
        chai.expect(data.currency).to.equal 'usd'
        # Save charge object for later reuse
        charge = data
        done()

      t.receive 'error', (data) ->
        assert.fail data, null
        done data

      # Charge 50c
      t.send 'data',
        currency: "usd"
        amount: 50
        card:
          number: "4242424242424242"
          exp_month: 12
          exp_year:  2020
          name: "T. Ester"

  describe 'GetCharge component', ->
    t = new Tester 'stripe/GetCharge'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'id', "foo-123"

    it 'should fail if non-existend ID is provided', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.type).to.equal 'StripeInvalidRequest'
        chai.expect(data.param).to.equal 'id'
        done()

      t.send 'id', "foo-random-invalid-" + uuid.v4()

    it 'should retrieve a charge', (done) ->
      t.receive 'charge', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data).to.deep.equal charge
        done()

      t.send 'id', charge.id

  describe 'UpdateCharge component', ->
    t = new Tester 'stripe/UpdateCharge'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'id', "foo-123"

    it 'should fail if neither description nor metadata was sent', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'has to be provided'
        done()

      t.send 'id', charge.id

    it 'should update description or metadata of a charge', (done) ->
      t.receive 'charge', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).to.equal charge.id
        chai.expect(data.description).to.equal 'A charge for a test'
        chai.expect(data.metadata).to.deep.equal {foo: 'bar'}
        done()

      t.send
        description: 'A charge for a test'
        metadata:
          foo: 'bar'
        id: charge.id

  describe 'RefundCharge component', ->
    t = new Tester 'stripe/RefundCharge'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'id', "foo-123"

    it 'should refund a part of the charge if amount is provided', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'refund', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.charge).to.equal charge.id
        chai.expect(data.amount).to.equal 20
        done()

      t.send
        amount: 20 # refund 20c
        id: charge.id

    it 'should refund entire sum left by default', (done) ->
      t.receive 'refund', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.charge).to.equal charge.id
        # App fee is not refunded by default
        chai.expect(data.amount).to.be.at.least 20
        done()

      t.send 'id', charge.id

  describe 'ListCharges component', ->
    t = new Tester 'stripe/ListCharges'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'exec', true

    it 'should output an array of all charges', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'charges', (data) ->
        chai.expect(data).to.be.an 'array'
        chai.expect(data).to.have.length.above 0
        done()

      t.send 'exec', true

    # TODO test other ListCharges parameters
