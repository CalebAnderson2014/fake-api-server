# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'
pathLib = require 'path'

Server = (options={}) ->
  registeredResources = []

  server = express()
  options.config?(server)
  server.use bodyParser()

  fail = (message, code=404) ->
    throw { message, code }

  server.on "error", (err) ->
    console.error err

  server.get "/", (req, res) ->
    res.send registeredResources.map (register) ->
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
      registeredResources.push({ path: npath, resource: nestedResource })
    else
      resourceServer = new ResourceServer(resource)
      server.use(path, resourceServer)
      registeredResources.push({ path, resource })
    this

  return server

passParentParams = (req, res, next) ->
  req.parentParams = req.params
  for param, val of req.parentParams
    req.parentParams[param] = parseInt(val) if param.match /Id$/
  next()

module.exports = Server
