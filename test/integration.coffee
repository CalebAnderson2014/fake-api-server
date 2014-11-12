# integration tests for server
chai = require 'chai'
chai.should()

Q = require 'kew'

fake = require '../lib'
http = require 'http'

{get, post, put, delete: del} = require './support/http-promise'

_port = 6000
nextPort = -> _port = _port + 1

describe "server", ->
  it "handles index requests", (done) ->
    books = new fake.Resource "book"
    music = new fake.Resource "music"
      .pluralName "music"
    tools = new fake.Resource "tool"

    server = new fake.Server()
      .register books
      .register music
      .register tools
      .listen port = nextPort()

    get("/api", port).then (res) ->
      res.statusCode.should.equal 200
      all = JSON.parse(res.body)

      names = all.map (d) -> d.name
      names.should.contain "book"
      names.should.contain "music"
      names.should.contain "tool"

      paths = all.map (d) -> d.url
      paths.should.contain "/api/books"
      paths.should.contain "/api/music"
      paths.should.contain "/api/tools"

      done()
    .end()

  it "handles GET /api/books", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/api/books", port).then (res) ->
      res.statusCode.should.equal 200
      all = JSON.parse(res.body)

      names = all.map (d) -> d.name
      names.should.contain "foo"
      names.should.contain "bar"
      names.should.contain "baz"

      done()
    .end()

  it "handles 404 on /api/idontexist", (done) ->
    port = nextPort()
    server = new fake.Server()
      .listen port
    get("/api/idontexist", port).then (res) ->
      res.statusCode.should.equal 404
      done()
    .end()

  it "handles GET /api/books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add bar = name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/api/books/#{bar.id}", port).then (res) ->
      res.statusCode.should.equal 200

      record = JSON.parse(res.body)

      record.id.should.equal bar.id
      record.name.should.equal "bar"

      done()
    .end()

  it "handles 404 on GET /api/books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/api/books/8383", port).then (res) ->
      res.statusCode.should.equal 404
      done()
    .end()

  it "handles POST /api/books", (done) ->
    books = new fake.Resource "book"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    post('/api/books', port, name: "foobar").then (res) ->
      res.statusCode.should.equal 200

      all = books.all()
      all.length.should.equal 1
      all[0].name.should.equal "foobar"
      done()
    .end()

  it "handles PUT /api/books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    put("/api/books/1", port, name: "foobar").then (res) ->
      res.statusCode.should.equal 200
      all = books.all()
      all.length.should.equal 1
      all[0].name.should.equal "foobar"
      done()
    .end()

  it "handles DELETE /api/books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    del("/api/books/1", port).then (res) ->
      res.statusCode.should.equal 200
      all = books.all()
      all.length.should.equal 0
      done()
    .end()

describe "registered resources", ->
  it "can still be renamed", (done) ->
    books = new fake.Resource "books"
      .add name: "goodbye"
      .add name: "foo"
      .add name: "ohai"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    books.name "cat"

    expectOk = (res) ->
      res.statusCode.should.equal 200
      res

    manipulate = [
      get("/api/cats/1", port)
      post("/api/cats",  port, name: "kitty")
      put("/api/cats/2", port, name: "garfield")
      del("/api/cats/1", port)
    ].map (p) -> p.then(expectOk)

    get("/api/cats", port).then(expectOk).then (res) ->
      all = JSON.parse(res.body)
      all.length.should.equal 3
    .then(-> Q.all manipulate)
    .then(-> get "/api/cats", port)
    .then(expectOk)
    .then (res) ->
      all = JSON.parse(res.body)
      all.length.should.equal 3

      names = all.map (cat) -> cat.name
      names.should.contain "kitty"
      names.should.contain "ohai"
      names.should.contain "garfield"

      done()
    .end()
