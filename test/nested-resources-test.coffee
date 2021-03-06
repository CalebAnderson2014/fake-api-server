# integration tests for server
expect = require('chai').expect

fake = require '../lib'
http = require 'http'

{get, post, put, delete: del} = require './support/http-promise'

_port = 6200
nextPort = -> _port = _port + 1

expectOk = (res) ->
  expect(res.statusCode).to.equal 200
  res


describe "server", ->
  book = null
  author = null
  server = null
  port = null

  beforeEach ->
    book = new fake.Resource "book"
    author = new fake.Resource "author"

    server = new fake.Server()
      .register(book)
      .register(book, author)
      .listen port = nextPort()

  it "registers nested resources", (done) ->
    bookId = null
    authorId = null
    post('/books', port, { title: 'hello' })
    .then(expectOk)
    .then -> get('/books', port)
    .then(expectOk)
    .then (res) ->
      records = JSON.parse(res.body)
      expect(records.length).to.equal 1
      return records[0].id
    .then (id) ->
      bookId = id
      post("/books/#{bookId}/authors", port, { name: 'Alice' })
    .then(expectOk)
    .then (res) ->
      author = JSON.parse(res.body)
      expect(author.id).to.not.equal undefined
      expect(author.bookId).to.equal bookId
      expect(author.name).to.equal 'Alice'
      return author.id
    .then (id) ->
      authorId = id
      get("/books/#{bookId}/authors/#{authorId}", port)
    .then(expectOk)
    .then (res) ->
      author = JSON.parse(res.body)
      expect(author.id).to.equal authorId
      expect(author.bookId).to.equal bookId
      expect(author.name).to.equal 'Alice'
      done()
    .end()

  it "validates the parent resource's existance", (done) ->
    post('/books/99/authors', port, { name: 'alice' }).then (res) ->
      expect(res.statusCode).to.equal 400
      done()
    .end()

  it "filters based on parent id", (done) ->
    bookId_1 = null
    bookId_2 = null
    post('/books', port, { title: 'one' })
    .then(expectOk)
    .then (res) -> bookId_1 = JSON.parse(res.body).id

    .then -> post('/books', port, { title: 'two' })
    .then(expectOk)
    .then (res) -> bookId_2 = JSON.parse(res.body).id

    .then -> post("/books/#{bookId_1}/authors", port, { title: 'Author One' })
    .then(expectOk)

    .then -> get("/books/#{bookId_1}/authors", port)
    .then(expectOk)
    .then (res) ->
      records = JSON.parse(res.body)
      expect(records.length).to.equal 1

    .then -> get("/books/#{bookId_2}/authors", port)
    .then(expectOk)
    .then (res) ->
      records = JSON.parse(res.body)
      expect(records.length).to.equal 0
      done()
    .end()
