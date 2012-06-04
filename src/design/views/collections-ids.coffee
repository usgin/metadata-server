module.exports =  
  map: (doc) ->
    if doc.Collections?
      emit id, doc._id for id in doc.Collections        
    return
  reduce: (key, values, rereduce) ->
    return values
