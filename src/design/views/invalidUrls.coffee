module.exports =  
  map: (doc) ->
    if doc.InvalidUrls?
      emit doc._id, doc.InvalidUrls