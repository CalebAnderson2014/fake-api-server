# integration tests for server
chai = require 'chai'
chai.should()

Q = require 'kew'

fake = require '../lib'
http = require 'http'

{get, post, put, delete: del} = require './support/http-promise'

_port = 6000
nextPort = -> _port = _port + 1
expectOk = (res) -> res.statusCode.should.equal 200; res

describe "server", ->

  it "is configurable", (done) ->
    toggle = false
    server = new fake.Server
      config: (server) ->
        server.use (req, res, next) -> toggle = true; next()

    server
      .register(new fake.Resource "book")
      .listen port = nextPort()

    get('/', port).then ->
      toggle.should.equal(true)
      done()
    .end()

  it "handles index requests", (done) ->
    books = new fake.Resource "book"
    music = new fake.Resource "music", "music"
    tools = new fake.Resource "tool"

    server = new fake.Server()
      .register books
      .register music
      .register tools
      .listen port = nextPort()

    get("/", port).then (res) ->
      res.statusCode.should.equal 200
      all = JSON.parse(res.body)

      names = all.map (d) -> d.name
      names.should.contain "book"
      names.should.contain "music"
      names.should.contain "tool"

      paths = all.map (d) -> d.url
      paths.should.contain "/books"
      paths.should.contain "/music"
      paths.should.contain "/tools"

      done()
    .end()

  it "handles GET /books", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/books", port).then (res) ->
      res.statusCode.should.equal 200
      all = JSON.parse(res.body)

      names = all.map (d) -> d.name
      names.should.contain "foo"
      names.should.contain "bar"
      names.should.contain "baz"

      done()
    .end()

  it "handles 404 on /idontexist", (done) ->
    port = nextPort()
    server = new fake.Server()
      .listen port
    get("/idontexist", port).then (res) ->
      res.statusCode.should.equal 404
      done()
    .end()

  it "handles GET /books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add bar = name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/books/#{bar.id}", port).then (res) ->
      res.statusCode.should.equal 200

      record = JSON.parse(res.body)

      record.id.should.equal bar.id
      record.name.should.equal "bar"

      done()
    .end()

  it "handles 404 on GET /books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"
      .add name: "bar"
      .add name: "baz"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    get("/books/8383", port).then (res) ->
      res.statusCode.should.equal 404
      done()
    .end()

  it "handles POST /books", (done) ->
    books = new fake.Resource "book"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    post('/books', port, name: "foobar").then (res) ->
      res.statusCode.should.equal 200

      all = books.all()
      all.length.should.equal 1
      all[0].name.should.equal "foobar"
      done()
    .end()

  it "handles POST /books with a normal query string", (done) ->
    books = new fake.Resource "book"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    post('/books', port, { name: "foobar" }, { useJSON: false }).then (res) ->
      res.statusCode.should.equal 200
      record = JSON.parse(res.body)
      record.name.should.not.equal undefined
      record.name.should.equal "foobar"

      all = books.all()
      all.length.should.equal 1
      all[0].name.should.equal "foobar"
      done()
    .end()

  it "handles POST /books with an invalid resource", (done) ->
    books = new fake.Resource "book"
    # Create a validator that always throws an error
    books.addValidator -> { theAttr: "is bad" }

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    post('/books', port, { name: "foobar" }).then (res) ->
      res.statusCode.should.equal 400
      errors = JSON.parse(res.body)
      errors.theAttr.should.equal "is bad"
      done()
    .end()



  it "handles PUT /books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    put("/books/1", port, name: "foobar").then (res) ->
      res.statusCode.should.equal 200
      all = books.all()
      all.length.should.equal 1
      all[0].name.should.equal "foobar"
      done()
    .end()

  it "handles DELETE /books/:id", (done) ->
    books = new fake.Resource "book"
      .add name: "foo"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    del("/books/1", port).then (res) ->
      res.statusCode.should.equal 200
      all = books.all()
      all.length.should.equal 0
      done()
    .end()

describe "registered resources", ->

  it "can register custom actions", (done) ->
    pets = new fake.Resource "pet"
      .addMemberAction 'adopt', () -> null

    server = new fake.Server()
      .register pets
      .listen port = nextPort()

    get('/', port).then (res) ->
      expectOk(res)
      json = JSON.parse(res.body)
      json[0].extra.length.should.equal 1
      json[0].extra[0].should.equal "POST /pets/:petId/adopt"
      done()
    .end()

  it "handles custom actions", (done) ->
    chats = new fake.Resource "chat"
      .add { id: 20, text: 'hi', votes: 1 }
      .addMemberAction 'upvote', (chat, context) ->
        chat.votes += context.params.upvoteAmount

    server = new fake.Server()
      .register chats
      .listen port = nextPort()

    post("/chats/20/upvote", port, upvoteAmount: 99)
    .then(expectOk)
    .then(-> get "/chats/20", port)
    .then(expectOk)
    .then (res) ->
      chat = JSON.parse(res.body)
      chat.text.should.equal 'hi'
      chat.votes.should.equal 100
      done()
    .end()

  it "gives custom actions access to all resources", (done) ->
    users = new fake.Resource "user"
      .add { id: 33, name: 'alice' }
      .add { id: 44, name: 'bob' }

    chats = new fake.Resource "chat"
      .add { id: 10, text: 'hi', votes: 1 }
      .addMemberAction 'test', (chat, context) ->
        context.resources.users.all().length.should.equal 2

    server = new fake.Server()
      .register chats
      .register users
      .listen port = nextPort()

    post("/chats/10/test", port, upvoteAmount: 99)
    .then(expectOk)
    .then -> done()
    .end()

  it "can still be renamed", (done) ->
    books = new fake.Resource "cat"
      .add name: "goodbye"
      .add name: "foo"
      .add name: "ohai"

    server = new fake.Server()
      .register books
      .listen port = nextPort()

    manipulate = [
      get("/cats/1", port)
      post("/cats",  port, name: "kitty")
      put("/cats/2", port, name: "garfield")
      del("/cats/1", port)
    ].map (p) -> p.then(expectOk)

    get("/cats", port).then(expectOk).then (res) ->
      all = JSON.parse(res.body)
      all.length.should.equal 3
    .then(-> Q.all manipulate)
    .then(-> get "/cats", port)
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
