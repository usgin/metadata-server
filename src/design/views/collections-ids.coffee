module.exports =  
  map: (doc) ->
    if doc.Collections?
      emit col, doc for col in doc.Collections        
    return
