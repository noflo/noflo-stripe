noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'
Tester = require 'noflo-tester'

describe 'Customers', ->

  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  customer = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCustomer component', ->
    t = new Tester 'stripe/CreateCustomer'
    before (done) ->
      t.start ->
        done()

    it 'should fail without an API key', (done) ->
      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.message).to.contain 'API key'
        done()

      t.send 'data',
        email: 'test@example.com'

    it 'should fail if email is missing', (done) ->
      # Set API key here as we didn't do it before
      t.send 'apikey', apiKey

      t.receive 'error', (data) ->
        chai.expect(data).to.be.an 'error'
        chai.expect(data.message).to.equal 'Missing email'
        done()

      t.send 'data', {}

    it 'should create a new customer', (done) ->
      t.receive 'customer', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'customer'
        chai.expect(data.email).to.equal 'customer@noflo-stripe.org'
        chai.expect(data.sources.total_count).to.equal 1
        # Save customer object for later reuse
        customer = data
        done()

      t.receive 'error', (data) ->
        done data

      t.send 'data',
        email: 'customer@noflo-stripe.org'
        description: 'Test User'
        card:
          number: "4242424242424242"
          exp_month: 12
          exp_year:  2020
          name: "T. Ester"
