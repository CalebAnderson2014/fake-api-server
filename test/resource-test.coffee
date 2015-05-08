expect = require('chai').expect
fake = require '../lib'

describe "resource", ->
  books = null

  beforeEach ->
    books = new fake.Resource "book"

  it "can add an array of resources", (done) ->
    books.add [{x:1}, {x:2}]
    expect(books.all().length).to.equal 2
    done()

  it "can set a validator", (done) ->
    validator = (obj, resources) ->
      expect(resources.users.all().length).to.equal 2
      { x: "Expected to be 12" } if obj.x != 12

    books.addValidator(validator)

    result = books.create({ x: 12 }, null, mockResources())
    expect(result.id).to.not.equal undefined
    expect(result.x).to.equal 12

    result = books.create({ x: 18 }, null, mockResources())
    expect(result._errors.x).to.equal "Expected to be 12"
    done()

  it "throws an error when adding an invalid record", (done) ->
    validator = (ob_) -> { _errors: 'bad stuff' }
    books.addValidator(validator)
    try
      books.add({})
    catch error
      expect(error.message).to.match(/invalid/i)
      done()

  it "handles uniqueness", ->
    books.uniqueAttribute('name')
    books.add({ name: 'x' })
    invalid = books.create({ name: 'x' })
    expect(invalid._errors.name).to.equal 'is taken'

  it "can add member actions", (done) ->
    books.add { id: 11 }
    books.addMemberAction 'finish', (book, params) ->
      expect(book.id).to.equal 11
      expect(params.x).to.equal 99
      done()
    books.runAction('finish', 11, { x: 99 })

  it "can add funnels", (done) ->

    books.addFunnel (obj, resources) ->
      expect(resources.users.all().length).to.equal 2
      obj.x = 8
      obj

    result = books.create({ some: 'thing' }, null, mockResources())
    expect(result.id).to.not.equal undefined
    expect(result.some).to.equal 'thing'
    expect(result.x).to.equal 8

    books.addFunnel () -> { objectGot: "overriden" }

    result = books.create({ one: 'more' }, null, mockResources())
    expect(result.id).to.not.equal undefined
    expect(result.some).to.equal undefined
    expect(result.objectGot).to.equal "overriden"

    done()

  it "runs funnels on updates", (done) ->
    book = books.create({ some: 'thing' })
    expect(book.touched).to.equal undefined

    books.addFunnel (obj, resources) ->
      expect(resources.users.all().length).to.equal 2
      obj.touched = true
      obj

    updated = books.update(book.id, { some: 'thing else' }, mockResources())
    expect(updated.touched).to.equal true

    book = books.find(book.id)
    expect(book.touched).to.equal true
    done()

  it "can add multiple funnels", (done) ->
    books.addFunnel (obj) -> obj.x = 11; obj
    books.addFunnel (obj) -> obj.y = 22; obj

    result = books.create({})
    expect(result.id).to.not.equal undefined
    expect(result.x).to.equal 11
    expect(result.y).to.equal 22
    done()

  it "funnels for updates", (done) ->
    books.addFunnel (obj) -> delete obj.x; obj

    book = books.create({ x: 11, y: 22 })
    expect(book.x).to.equal undefined
    expect(book.y).to.equal 22

    result = books.update(book.id, x: 55, y: 77)
    expect(result.x).to.equal undefined
    expect(result.y).to.equal 77
    done()

mockResources = ->
  {
    users: {
      all: -> [
        { id: 11, name: 'alice' },
        { id: 22, name: 'bob' }
      ]
    }
  }
