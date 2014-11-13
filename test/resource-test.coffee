fake = require '../lib'

describe "resource", ->
  books = null

  before ->
    books = new fake.Resource "book"

  it "can set a validator", (done) ->
    validator = (obj) ->
      obj.x == 12 || { x: "Expected to be 12" }

    books.validateWith(validator)

    result = books.create({ x: 12 })
    console.log("Valid", result)
    result.id.should.not.equal undefined
    result.x.should.equal 12

    result = books.create({ x: 18 })
    result._errors.x.should.equal "Expected to be 12"
    done()
