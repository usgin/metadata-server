module.exports =  
  map: (doc, debug = false) ->
    if doc.Collections?
      if debug
        return
      else
        emit col, doc for col in doc.Collections        
    return
