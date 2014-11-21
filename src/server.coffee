# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'
pathLib = require 'path'

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
  server.register = (resource, nestedResource) ->

    path = "/#{resource.pluralName}"
    if nestedResource
      resources = resources.concat [nestedResource]
      resourceServer = new ResourceServer(nestedResource)

      parentId = "#{resource.name}Id"
      resourceServer.addFilter 'GET /', (req, record) ->
        record[parentId] == req.params[parentId]
      nestedResource.addValidator (record) ->
        if not resource.find(record[parentId])
          errors = {}
          errors[parentId] = ["#{resource.name} with id=#{record[parentId]} does not exist"]
          return errors
        else
          return undefined

      npath = "#{path}/:#{parentId}/#{nestedResource.pluralName}"
      server.use(npath, passParentParams)
      server.use(npath, resourceServer)
    else
      resources = resources.concat [resource]
      resourceServer = new ResourceServer(resource)
      server.use(path, resourceServer)
    this

  return server

passParentParams = (req, res, next) ->
  req.parentParams = req.params
  next()

module.exports = Server
