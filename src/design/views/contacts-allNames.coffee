module.exports =  
  map: (doc) ->
    emit 'ContactNames', author.Name || author.OrganizationName for author in doc.Authors || []    
  reduce: (key, values, rereduce) ->
    unique = values.filter (itm, i, a) ->
      return i is a.indexOf itm
