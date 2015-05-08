# fake api server

express = require 'express'
bodyParser = require 'body-parser'

extend = (target, source) ->
  target[k] = v for k,v of source

ResourceServer = (resource) ->
  filters = {}
  server = express()
  server.use bodyParser()

  server.addResponseFilter = (method_url, f) ->
    filters[method_url] ||= []
    filters[method_url].push f

  fail = (message, code=404) ->
    throw { message, code }

  respondTo = (method_url, cb) ->
    [method, url] = method_url.split(' ')
    server[method.toLowerCase()] url, (req, res) ->
      extend(req.params, req.parentParams)
      try
        result = cb(req)
        if filters[method_url]
          result = result.filter(f.bind(null, req)) for f in filters[method_url]
        res.send result
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
    extend(req.body, req.params)
    result = resource.create(req.body)
    fail(result._errors, 400) if result._errors
    result

  respondTo 'PUT /:id', (req) ->
    resource.update(req.params.id, req.body) || fail "No #{resource.name} with id #{req.params.id}"

  respondTo 'DELETE /:id', (req) ->
    resource.remove(req.params.id) || fail "No #{resource.name} with id #{req.params.id}"

  for actionName of resource.memberActions
    respondTo "POST /:id/#{actionName}", (req) ->
      id = req.params.id
      resource.runAction(actionName, {
        id: id,
        params: req.body,
        resources: req.serverResources,
        currentUser: req.user
      }) || fail "No #{resource.name} with id #{id}"

  return server

module.exports = ResourceServer
