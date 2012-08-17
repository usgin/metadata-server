module.exports =  
  map: (doc) ->
    if doc.InvalidUrls?
      editLink = "/repository/resource/#{doc._id}/edit/"
      emit editLink, doc.InvalidUrls
    return