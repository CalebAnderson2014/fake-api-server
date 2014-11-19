# fake api resource

Resource = (name, pluralName) ->
  records = []
  validator = null
  funnels = []
  idAttribute = "id"
  idFactory = ->
    1 + Math.max 0,
      Math.max.apply Math, (d[idAttribute] for d in records)

  resource =
  name: name
  pluralName: pluralName || "#{name}s"

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

  validateWith: (v) -> validator = v; this
  addFunnel: (f) -> funnels.push(f); this

  all: ->
    records

  add: (records) ->
    if records.constructor == Array
      resource.create(rec) for rec in records
    else
      resource.create(records)
    resource

  create: (record) ->
    record = f(record) for f in funnels

    if validator
      result = validator(record)
      return { _errors: result } if result?

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

    record = f(record) for f in funnels
    record

  remove: (id) ->
    record = @find id
    return no unless record
    records = records.filter (d) ->
      "#{d[idAttribute]}" isnt "#{id}"
    yes

module.exports = Resource
