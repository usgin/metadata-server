module.exports =  
  map: (doc, debug = false) ->
    if debug
      return
    else
      emit 'Title', doc.Title