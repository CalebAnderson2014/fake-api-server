# fake api resource

Resource = (name) ->
  records = []
  idAttribute = "id"
  idFactory = ->
    1 + Math.max 0,
      Math.max.apply Math, (d[idAttribute] for d in records)

  resource =
  _name: name
  _pluralName: null

  idAttribute: ->
    if arguments.length is 0
      idAttribute
    else
      idAttribute = arguments[0]
      resource

  idFactory: ->
    if arguments.length is 0
      idFactory
    else
      idFactory = arguments[0]
      resource

  name: ->
    if arguments.length is 0
      resource._name
    else
      resource._name = arguments[0]
      resource

  pluralName: ->
    if arguments.length is 0
      if resource._pluralName
        resource._pluralName
      else
        "#{resource._name}s"
    else
      resource._pluralName = arguments[0]
      resource

  all: ->
    records

  add: (record) ->
    resource.create(record)
    resource

  create: (record) ->
    record[idAttribute] = idFactory()
    records = records.concat [record]
    record

  find: (id) ->
    record = records.filter (d) ->
      "#{d[idAttribute]}" is "#{id}"
    if record.length then record[0] else no

  update: (id, updates) ->
    record = @find id
    return no unless record
    for name, value of updates when name isnt idAttribute
      record[name] = value
    record

  remove: (id) ->
    record = @find id
    return no unless record
    records = records.filter (d) ->
      "#{d[idAttribute]}" isnt "#{id}"
    yes

module.exports = Resource
