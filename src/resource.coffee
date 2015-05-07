# fake api resource

Resource = (name, pluralName) ->
  records = []
  validators = []
  funnels = []
  idAttribute = "id"
  idFactory = ->
    1 + Math.max 0,
      Math.max.apply Math, (d[idAttribute] for d in records)

  updateInPlace = (record) ->
    for r, i in records
      records[i] = record if r.id == record.id

  resource =
  name: name
  pluralName: pluralName || "#{name}s"
  memberActions: {}

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

  addValidator: (v) -> validators.push(v); this
  addFunnel: (f) -> funnels.push(f); this
  addMemberAction: (name, f) -> resource.memberActions[name] = f; this

  all: ->
    records

  add: (records) ->
    records = [records] unless records.constructor == Array
    for rec in records
      result = resource.create(rec, rec.id)
      throw new Error("Invalid record: " + JSON.stringify(result)) if result._errors
    resource

  create: (record, id, resources) ->
    record = f(record, resources) for f in funnels

    for validate in validators
      result = validate(record, resources)
      return { _errors: result } if result?

    record[idAttribute] = id || idFactory()
    records = records.concat [record]
    record

  find: (id) ->
    id = parseInt(id)
    record = records.filter (d) ->
      "#{d[idAttribute]}" is "#{id}"
    if record.length then record[0] else no

  update: (id, updates, resources) ->
    id = parseInt(id)
    record = @find id
    return no unless record

    for name, value of updates when name isnt idAttribute
      record[name] = value

    if funnels.length
      record = f(record, resources) for f in funnels
      updateInPlace(record)

    record

  runAction: (name, id, params, resources) ->
    record = @find id
    return no unless record
    resource.memberActions[name](record, params, resources)
    record

  remove: (id) ->
    id = parseInt(id)
    record = @find id
    return no unless record
    records = records.filter (d) ->
      "#{d[idAttribute]}" isnt "#{id}"
    yes

module.exports = Resource
