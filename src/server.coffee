# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'
path = require 'path'

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
    if resource == undefined
      resource = url
      url = '/'

    resources = resources.concat [resource]
    server.use(path.join(url, resource.pluralName), new ResourceServer(resource))
    this

  return server

module.exports = Server
