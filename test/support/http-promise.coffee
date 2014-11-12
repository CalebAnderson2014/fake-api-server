http = require 'http'
Q = require 'kew'
querystring = require 'querystring'

request = (method, path, port, data="", options={}) ->
  options.useJSON ||= true

  deferred = Q.defer()
  req = http.request
      host: "localhost"
      port: port
      path: path
      method: method
      (res) ->
        res.body = ''
        res.on 'data', (chunk) ->
          res.body += chunk
        res.on 'end', ->
          deferred.resolve(res)

  req.on 'error', (e) -> deferred.reject(new Error(e.message))

  if options.useJSON
    data ||= {}
    req.setHeader "Content-Type", "application/json"
    data = JSON.stringify(data)
  else
    data ||= {}
    req.setHeader "Content-Type", "multipart/form-data"
    data = querystring.strigify(data)

  req.write(data)
  req.end()
  return deferred.promise

exports.get     = request.bind(null, 'GET')
exports.post    = request.bind(null, 'POST')
exports.put     = request.bind(null, 'PUT')
exports.delete  = request.bind(null, 'DELETE')
