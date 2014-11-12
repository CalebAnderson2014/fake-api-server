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
        catch errorMsg
          res.statusCode = 404
          res.send errorMsg

      for resource in resources
        sendResponse(resource) if resource.pluralName() is path
      res.send 404

  server.on "error", (err) ->
    console.error err

  server.get "/api", (req, res) ->
    res.send resources.map (resource) ->
      name: resource.name()
      url: "/api/#{resource.pluralName()}"

  server.get "/api/:resource", getResource (req, resource) ->
    resource.all()

  server.get "/api/:resource/:id", getResource (req, resource) ->
    resource.find(req.params.id) || throw "No #{resource.name()} with id #{req.params.id}"

  server.post "/api/:resource", getResource (req, resource) ->
    resource.create(req.body)

  server.put "/api/:resource/:id", getResource (req, resource) ->
    resource.update(req.params.id, req.body) || throw "No #{resource.name()} with id #{req.params.id}"

  server.delete "/api/:resource/:id", getResource (req, resource) ->
    resource.remove(req.params.id) || throw "No #{resource.name()} with id #{req.params.id}"

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
