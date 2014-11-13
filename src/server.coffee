# fake api server

express = require 'express'
bodyParser = require 'body-parser'

Server = ->
  resources = []

  server = express()
  server.use bodyParser()

  getResource = (cb) ->
    return (req, res) ->
      path = req.params.resource

      sendResponse = (resource) ->
        try
          res.send cb(req, resource)
        catch error
          res.statusCode = error.code
          res.send error.message

      for resource in resources
        sendResponse(resource) if resource.pluralName() is path
      res.send 404

  fail = (message, code=404) ->
    throw { message, code }

  server.on "error", (err) ->
    console.error err

  server.get "/api", (req, res) ->
    res.send resources.map (resource) ->
      name: resource.name()
      url: "/api/#{resource.pluralName()}"

  server.get "/api/:resource", getResource (req, resource) ->
    resource.all()

  server.get "/api/:resource/:id", getResource (req, resource) ->
    resource.find(req.params.id) || fail ["No #{resource.name()} with id #{req.params.id}"]

  server.post "/api/:resource", getResource (req, resource) ->
    result = resource.create(req.body)
    fail(result._errors, 400) if result._errors
    result


  server.put "/api/:resource/:id", getResource (req, resource) ->
    resource.update(req.params.id, req.body) || fail "No #{resource.name()} with id #{req.params.id}"

  server.delete "/api/:resource/:id", getResource (req, resource) ->
    resource.remove(req.params.id) || fail "No #{resource.name()} with id #{req.params.id}"

  #
  # Public Interface
  #
  listen = (port=3000) ->
    server.listen port
    console.log "server listening on localhost:#{port}"
    this

  register = (resource) ->
    resources = resources.concat [resource]
    this

  return { listen, register }

module.exports = Server
