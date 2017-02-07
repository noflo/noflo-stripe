noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'
Tester = require 'noflo-tester'

describe 'Tokens', ->
  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  token = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCardToken component', ->
    c = require './../components/CreateCardToken.coffee'
    t = new Tester c.getComponent() #'stripe/CreateCardToken'
    before (done) ->
      t.start ->
        done()

    it.skip 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'card',
        number: "4242"

    it 'should fail if card number or expiry data is missing', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'array'
        chai.expect(data).to.have.lengthOf 3
        messages = [
          'Missing card number'
          'Missing or invalid expiration month'
          'Missing or invalid expiration year'
        ]
        for msg in data
          chai.expect(messages).to.include msg.message
        done()

      t.send 'card',
        name: 'T. Ester'

    it 'should create a new token', (done) ->
      t.receive 'token', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'token'
        chai.expect(data.used).to.be.false
        chai.expect(data.type).to.equal 'card'
        chai.expect(data.card).to.be.an 'object'
        # Save charge object for later reuse
        token = data
        done()

      t.receive 'error', (data) ->
        assert.fail data, null
        done data

      t.send 'card',
        number: "4242424242424242"
        exp_month: 12
        exp_year:  2020
        name: "T. Ester"

  describe 'RetrieveToken component', ->
    c = require './../components/RetrieveToken.coffee'
    t = new Tester c.getComponent() # 'stripe/RetrieveToken'
    before (done) ->
      t.start ->
        done()

    it.skip 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'id', "foo-123"

    it 'should fail if non-existend ID is provided', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.type).to.equal 'StripeInvalidRequestError'
        chai.expect(data.param).to.equal 'token'
        done()

      t.send 'id', "foo-random-invalid-" + uuid.v4()

    it 'should retrieve a token', (done) ->
      t.receive 'token', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data).to.deep.equal token
        done()

      t.send 'id', token.id
