# fake api server

express = require 'express'
bodyParser = require 'body-parser'

Server = (options={}) ->
  resources = []

  server = express()
  options.config?(server)
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

  server.get "/", (req, res) ->
    res.send resources.map (resource) ->
      name: resource.name()
      url: "/#{resource.pluralName()}"

  server.get "/:resource", getResource (req, resource) ->
    resource.all()

  server.get "/:resource/:id", getResource (req, resource) ->
    resource.find(req.params.id) || fail ["No #{resource.name()} with id #{req.params.id}"]

  server.post "/:resource", getResource (req, resource) ->
    result = resource.create(req.body)
    fail(result._errors, 400) if result._errors
    result


  server.put "/:resource/:id", getResource (req, resource) ->
    resource.update(req.params.id, req.body) || fail "No #{resource.name()} with id #{req.params.id}"

  server.delete "/:resource/:id", getResource (req, resource) ->
    resource.remove(req.params.id) || fail "No #{resource.name()} with id #{req.params.id}"

  #
  # Fake-specific API
  #
  server.register = (resource) ->
    resources = resources.concat [resource]
    this

  return server

module.exports = Server
