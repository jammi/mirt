'use strict'

# Simple RAM-based value manager
module.exports = ({anyListeners, initValues}) ->

  InitListeners = (listeners) ->
    listeners = {} unless listeners?
    ['new', 'set', 'del'].forEach (verb) ->
      listeners[verb] = [] unless listeners[verb]?
    listeners

  anyListeners = InitListeners(anyListeners)

  Value = (@id, @data, @session, listeners) ->
    @session.values[@id] = @
    @valueSync = @session.valueSync
    @valueSync['new'].push(@)
    @listeners = InitListeners(listeners)
    anyListeners['new'].forEach (cb1) => cb1(@)
    @listeners['new'].forEach (cb2) => cb2(@)

    @listen = (cb, listenTypes) =>
      listenTypes = ['set'] unless listenTypes?
      listenTypes.forEach (listenType) =>
        index = @listeners[listenType].indexOf(cb)
        @listeners[listenType].push(cb) unless !!~index

    @ignore = (cb, listenTypes) =>
      listenTypes = ['new', 'set', 'del'] unless listenTypes?
      listenTypes.forEach (listenType) =>
        index = @listeners[listenType].indexOf(cb)
        @listeners.splice(index, 1) if !!~index

    @set = (@data) =>
      @valueSync['set'].push(@) unless ~@valueSync['set'].indexOf(@)
      anyListeners['set'].forEach (cb) => cb(@)
      @listeners['set'].forEach (cb) => cb(@)

    @del = =>
      @valueSync['del'].push(@) unless ~@valueSync['del'].indexOf(@)
      anyListeners['del'].forEach (cb) => cb(@)
      @listeners['del'].forEach (cb) => cb(@)
      delete @session.values[id]

  initDefaults = (session) ->
    if initValues?
      initValues.forEach ([id, data, listeners]) ->
        new Value(id, data, session, listeners)

  createValues = (session, valuesIn) ->
    valuesIn.forEach ([valueId, valueData, valueType]) ->
      if valueType isnt 0
        console.error("Unknown value type: #{valueType} for valueId: #{valueId}")
      else if session.values[valueId]?
        console.error("Duplicate value id: #{valueId}")
      else
        new Value(valueId, valueData, session)

  setValues = (session, valuesIn) ->
    valuesIn.forEach ([valueId, valueData]) ->
      session.values[valueId].set(valueData)

  delValues = (session, keysIn) ->
    keysIn.forEach (valueId) ->
      session.values[valueId].del()

  syncIn = (session, values) ->
    createValues(session, values['new']) if values['new']?
    setValues(session, values['set']) if values['set']?
    setValues(session, values['del']) if values['del']?

  valuesById = (valuesIn) ->
    valuesObjIn = {'new': {}, 'set': {}, 'del': {}}
    if valuesIn?
      ['new', 'set', 'del'].forEach (verb) ->
        if valuesIn[verb]?
          valuesIn[verb].forEach ([id, data]) ->
            valuesObjIn[verb][id] = data
    valuesObjIn


  syncOut = (session, valuesIn=null) ->
    valueSync = session.valueSync
    valuesInSync = valuesById(valuesIn)
    values = {}
    ['new', 'set', 'del'].forEach (verb) ->
      syncLen = valueSync[verb].length
      if syncLen
        values[verb] = []
        for [0..(syncLen-1)]
          value = session.valueSync[verb].shift()
          if verb is 'new' or verb is 'set'
            valueInSync = valuesInSync[verb][value.id]
            if not valueInSync? or valueInSync isnt value.data
              if verb is 'new'
                values['new'].push([value.id, value.data, 0])
              else if verb is 'set'
                values['set'].push([value.id, value.data])
          else if verb is 'del'
            unless valuesInSync['del'][value.id]?
              values['del'].push(value.id)
        delete values[verb] unless values[verb].length
    values

  syncServer = (session, values) ->
    if session.seq is 0
      initDefaults(session)
    syncIn(session, values)
    syncOut(session, values)

  {syncServer, syncIn, syncOut, Value, initDefaults}

