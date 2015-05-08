expect = require('chai').expect

Q = require 'kew'

fake = require '../lib'
http = require 'http'

{get, post, put, delete: del} = require './support/http-promise'

_port = 7100
nextPort = -> _port = _port + 1

expectCode = (code) ->
  (res) -> expect(res.statusCode).to.equal(code); res
expectOk = expectCode(200)
expectUnauthorized = expectCode(401)


describe "user accounts", ->
  server = null

  beforeEach ->
    server = new fake.Server().enableUserAccounts()

  it "creates pseudo-resources", ->
    expect(Object.keys(server.resources._users).length).to.equal 0
    expect(Object.keys(server.resources._sessions).length).to.equal 0

  it "allows sign up and sign in", (done) ->
    server.listen port = nextPort()
    createAccount(port, { username: 'bob', password: '123' })
      .then -> done()
    .end()

  describe "resource blocking", ->
    port = null
    apiTokenPromise = null

    beforeEach ->
      server
        .register(new fake.Resource 'book')
        .listen port = nextPort()
      apiTokenPromise = createAccount(port, { username: 'bob', password: '123' })

    it "allows access to root", (done) ->
      get('/', port).then (res) ->
        expectOk(res)
        done()
      .end()

    it "allows access to custom endpoints", (done) ->
      server.skipAuthPaths.push('GET /books')
      get('/books', port).then (res) ->
        expectOk(res)
        done()
      .end()

    it "blocks access to creating resources", (done) ->
      post('/books', port, name: 'nope').then (res) ->
        expectUnauthorized(res)
        done()
      .end()

    it "requires a token to create a resource", (done) ->
      apiTokenPromise.then (token) ->
        post('/books', port, name: 'Alice in Wonderland', apiToken: token)
      .then (res) ->
        expectOk(res)
        done()
      .end()

    # TODO: TEST MEMBER ACTIONS, VALIDATION, AND FUNNELS

createAccount = (port, credentials) ->
  post('/signup', port, credentials)
    .then(expectOk)
    .then -> post('/signin', port, credentials)
    .then (res) ->
      expectOk(res)
      json = JSON.parse(res.body)
      expect(json.apiToken).to.exist
      json.apiToken
