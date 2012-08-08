module.exports =  
  map: (doc, debug = false) ->
    if doc.ParentCollections?
      if debug
        return
      else
        emit id, doc._id for id in doc.ParentCollections        
    return
  reduce: (key, values, rereduce) ->
    return values
