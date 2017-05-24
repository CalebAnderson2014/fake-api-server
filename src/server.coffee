# fake api server

express = require 'express'
bodyParser = require 'body-parser'
ResourceServer = require './resource-server'
pathLib = require 'path'

Server = (options={}) ->
  registered = []

  server = enableCORS(express())
  options.config?(server)
  server.use bodyParser()

  fail = (message, code=404) ->
    throw { message, code }

  server.resources = {}

  # Allow endpoints to access all server resources
  server.use (req, res, next) ->
    req.serverResources = server.resources
    next()

  server.on "error", (err) ->
    console.error err

  server.get "/", (req, res) ->
    endpoints = registered.map (register) ->
      name: register.resource.name
      url: register.path
      extra: Object.keys(register.resource.memberActions).map (actionName) ->
        "POST #{register.path}/:#{register.resource.name}Id/#{actionName}"

    if server.resources._users
      endpoints.push({
        name: 'user accounts',
        extra: ['POST /signup', 'POST /signin']
      })

    res.send({ endpoints })

  #
  # Fake-specific API
  #
  server.enableUserAccounts = enableUserAccounts.bind(null, server)

  server.register = (resource, nestedResource) ->

    path = "/#{resource.pluralName}"
    if nestedResource
      resourceServer = new ResourceServer(nestedResource)

      parentId = "#{resource.name}Id"
      resourceServer.addResponseFilter 'GET /', (req, record) ->
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

    server.resources[resource.pluralName] = resource
    this

  return server

passParentParams = (req, res, next) ->
  req.parentParams = req.params
  for param, val of req.parentParams
    req.parentParams[param] = parseInt(val) if param.match /Id$/
  next()

module.exports = Server


enableCORS = (server) ->
  server.use (req, res, next) ->
    res.header("Access-Control-Allow-Origin", "*")
    res.header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization")
    next()
  return server

enableUserAccounts = (server) ->
  server.skipAuthPaths = ['GET /', 'POST /signup', 'POST /signin']

  users = server.resources._users = []
  sessions = server.resources._sessions = {}
  findUserByUsername = (username) -> find(users, (user) -> user.username == username)

  server.post '/signup', (req, res) ->
    error = validateUsername(req.body.username, findUserByUsername)
    return res.status(400).send(error) if error

    error = validatePassword(req.body.password)
    return res.status(400).send(error) if error

    id = 1 + Object.keys(users).length
    users.push({
      id: id,
      username: req.body.username,
      password: req.body.password
    })
    tokenId = uuid()
    sessions[tokenId] = user.id
    res.status(200).send({ status: 'success', apiToken: tokenId })


  server.post '/signin', (req, res) ->
    user = findUserByUsername(req.body.username)
    return res.status(400).send(error: 'username_does_not_exist') if !user
    return res.status(400).send(error: 'incorrect_password') if user.password != req.body.password

    tokenId = uuid()
    sessions[tokenId] = user.id
    res.send({ user: { id: user.id, username: user.username }, apiToken: tokenId })


  server.get '/users/:id', (req, res) ->
    user = find users, (u) -> u.id == parseInt(req.params.id)
    return res.status(404).send(error: 'user_not_found') if !user
    res.send(user)


  server.use (req, res, next) ->
    return next() if req.method == 'OPTIONS'
    return next() if matchPath(server.skipAuthPaths, req.method.toUpperCase(), req.path)

    sessionId = tokenFromHeader(req) || req.param('apiToken') || tokenFromBody(req)
    return res.status(401).send(error: 'not_authorized') unless sessionId

    userId = sessions[sessionId]
    return res.status(401).send(error: 'not_authorized') unless userId?

    req.user = find users, (u) -> u.id == userId
    return res.status(401).send(error: 'not_authorized') unless req.user?
    next()

  return server

tokenFromHeader = (req) ->
  header = req.get('Authorization')
  return unless header
  match = header.match(/^API token="([^"]+)"$/)
  match && match[1]

tokenFromBody = (req) ->
  return null unless req.body?
  token = req.body.apiToken
  delete req.body.apiToken
  token

find = (array, pred) ->
  for elem in array
    return elem if pred(elem)
  return null

matchPath = (patterns, method, path) ->
  for p in patterns
    [meth, regex] = p.split(' ')
    return p if meth == method && path.match('^' + regex + '$')
  return null

validateUsername = (username='', findUserByUsername) ->
  reason = 'Username must be at least 3 characters long' if username.length < 3
  reason = 'Username must be alphanumerical (a-z 0-9)' unless username.match /^[a-z0-9]+$/i
  reason = 'Username is taken' if findUserByUsername(username)
  return { error: 'invalid_username', reason: reason } if reason?

validatePassword = (password='') ->
  reason = 'Password must be at least 1 characters long' if password.length < 1
  reason = 'Password must be alphanumerical (a-z 0-9)' unless password.match /^[a-z0-9]+$/i
  return { error: 'invalid_password', reason: reason } if reason?

uuid = ->
  'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace /[xy]/g, (c) ->
    r = Math.random() * 16|0
    v = if c == 'x' then r else (r&0x3|0x8)
    return v.toString(16)
