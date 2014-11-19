# fake api server

express = require 'express'
bodyParser = require 'body-parser'

ResourceServer = (resource) ->
  server = express()
  server.use bodyParser()

  fail = (message, code=404) ->
    throw { message, code }

  respondTo = (method_url, cb) ->
    [method, url] = method_url.split(' ')
    server[method.toLowerCase()] url, (req, res) ->
      try
        res.send cb(req)
      catch error
        res.statusCode = error.code
        res.send error.message

  server.on "error", (err) ->
    console.error err

  respondTo 'GET /', (req) ->
    resource.all()

  respondTo 'GET /:id', (req) ->
    resource.find(req.params.id) || fail "No #{resource.name} with id #{req.params.id}"

  respondTo 'POST /', (req) ->
    result = resource.create(req.body)
    fail(result._errors, 400) if result._errors
    result

  respondTo 'PUT /:id', (req) ->
    resource.update(req.params.id, req.body) || fail "No #{resource.name} with id #{req.params.id}"

  respondTo 'DELETE /:id', (req) ->
    resource.remove(req.params.id) || fail "No #{resource.name} with id #{req.params.id}"

  return server

module.exports = ResourceServer
