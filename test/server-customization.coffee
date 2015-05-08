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

describe "server customization", ->

  # LAST TIME: TEST idAttribute
  # it