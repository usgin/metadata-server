module.exports =  
  map: (doc) ->
    emit author.Name || author.OrganizationName, { author: author, doc: doc } for author in doc.Authors || []    
  reduce: (key, values, rereduce) ->
    return values[0].author