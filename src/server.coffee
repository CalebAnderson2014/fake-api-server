# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'

Server = (options={}) ->
  resources = []

  server = express()
  options.config?(server)
  server.use bodyParser()

  fail = (message, code=404) ->
    throw { message, code }

  server.on "error", (err) ->
    console.error err

  server.get "/", (req, res) ->
    res.send resources.map (resource) ->
      name: resource.name
      url: "/#{resource.pluralName}"

  #
  # Fake-specific API
  #
  server.register = (url, resource) ->
    # url is optional
    resource = url if resource == undefined

    resources = resources.concat [resource]
    server.use("/#{resource.pluralName}", new ResourceServer(resource))
    this

  return server

module.exports = Server
