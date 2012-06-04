module.exports =  
  map: (doc) ->
    if doc.ParentCollections?
      emit id, doc._id for id in doc.ParentCollections        
    return
  reduce: (key, values, rereduce) ->
    return values
