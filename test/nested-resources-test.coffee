# integration tests for server
expect = require('chai').expect

fake = require '../lib'
http = require 'http'

{get, post, put, delete: del} = require './support/http-promise'

_port = 6200
nextPort = -> _port = _port + 1

expectOk = (res) ->
  res.statusCode.should.equal 200
  res


describe "server", ->

  it "handles a plain url", (done) ->
    books = new fake.Resource "book"
      .add({ title: 'go' })

    server = new fake.Server()
      .register('/library', books)
      .listen port = nextPort()

    get('/library/books', port).then (res) ->
      all = JSON.parse(res.body)
      expect(all[0].id).to.not.equal undefined
      expect(all[0].title).to.equal 'go'
      done()
    .end()

  # it "handles named parameters", (done) ->
  #   books = new fake.Resource "book"

  #   server = new fake.Server()
  #     .register('/library/:id', books)
  #     .listen port = nextPort()

  #   get('/library/4/books', port).then(expectOk)

  #   post('/library/4/books', port).then (res) ->
  #     all = JSON.parse(res.body)
  #     expect(all[0].id).to.not.equal undefined
  #     expect(all[0].title).to.equal 'go'
  #     done()
  #   .end()
