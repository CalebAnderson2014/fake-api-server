# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'
pathLib = require 'path'

Server = (options={}) ->
  registered = []
  resources = {}

  server = express()
  options.config?(server)
  server.use bodyParser()

  fail = (message, code=404) ->
    throw { message, code }

  # Allow endpoints to access all server resources
  server.use (req, res, next) ->
    req.serverResources = resources
    next()

  server.on "error", (err) ->
    console.error err

  server.get "/", (req, res) ->
    res.send registered.map (register) ->
      name: register.resource.name
      url: register.path

  #
  # Fake-specific API
  #
  server.register = (resource, nestedResource) ->

    path = "/#{resource.pluralName}"
    if nestedResource
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
      registered.push({ path: npath, resource: nestedResource })
    else
      resourceServer = new ResourceServer(resource)
      server.use(path, resourceServer)
      registered.push({ path, resource })

    resources[resource.pluralName] = resource
    this

  return server

passParentParams = (req, res, next) ->
  req.parentParams = req.params
  for param, val of req.parentParams
    req.parentParams[param] = parseInt(val) if param.match /Id$/
  next()

module.exports = Server
