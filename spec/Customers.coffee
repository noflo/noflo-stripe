noflo = require 'noflo'
chai = require 'chai'
uuid = require 'uuid'

describe 'Customers', ->

  apiKey = process.env.STRIPE_TOKEN or 'sk_test_BQokikJOvBiI2HlWgH4olfQ2'
  newCreateCustomer = require('../components/CreateCustomer').getComponent
  customer = null

  chai.expect(apiKey).not.to.be.empty

  describe 'CreateCustomer component', ->
    c = newCreateCustomer()
    ins = noflo.internalSocket.createSocket()
    key = noflo.internalSocket.createSocket()
    out = noflo.internalSocket.createSocket()
    err = noflo.internalSocket.createSocket()
    c.inPorts.data.attach ins
    c.inPorts.apikey.attach key
    c.outPorts.customer.attach out
    c.outPorts.error.attach err

    it 'should fail without an API key', (done) ->
      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.contain 'API key'
        done()

      ins.send
        email: 'test@example.com'

    it 'should fail if email is missing', (done) ->
      # Set API key here as we didn't do it before
      key.send apiKey

      err.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.message).to.equal 'Missing email'
        done()

      ins.send {}

    it 'should create a new customer', (done) ->
      out.once 'data', (data) ->
        chai.expect(data).to.be.an 'object'
        chai.expect(data.id).not.to.be.empty
        chai.expect(data.object).to.equal 'customer'
        chai.expect(data.email).to.equal 'customer@noflo-stripe.org'
        chai.expect(data.cards.total_count).to.equal 1
        # Save customer object for later reuse
        customer = data
        done()

      err.once 'data', (data) ->
        assert.fail data, null
        done data

      ins.send
        email: 'customer@noflo-stripe.org'
        description: 'Test User'
        card:
          number: "4242424242424242"
          exp_month: 12
          exp_year:  2020
          name: "T. Ester"
