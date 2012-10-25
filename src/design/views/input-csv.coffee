module.exports = 
  map: (csv, debug=false) ->
    objGet = (obj, prop, defVal) ->
      return defVal if not obj?
      props = prop.split '.'
      count = 0
      for p in props
        if obj[p]?
          obj = obj[p]
          count++
          return obj if count is props.length
        else
          return defVal              
              
    doc =
      setProperty: (prop, value) ->
        obj = @
        props = prop.split '.'
        count = 0
        for p in props
          if obj[p]?
            obj = obj[p]
            count++
          else
            if count + 1 is props.length
              obj[p] = value
            else
              obj[p] = {}
              obj = obj[p]
              count++
    
    
    
    
    if debug
      return
    else
      emit csv._id, doc
    return              