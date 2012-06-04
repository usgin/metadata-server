module.exports =
  index: (doc) ->
    # Ignore design documents
    return null if doc._id.match(/^_design\//)?
    
    # Setup the result object
    result = new Document()
    
    # Index all the text in the default field
    idx = (obj) ->
      for key, value of obj
        switch typeof value
          when 'object' then idx value
          when 'function' then break
          else result.add value
    idx doc
    
    # Add a published field
    fldOptions =
      field: 'published'
      store: 'yes'
    if doc.Published?
      result.add doc.Published, fldOptions
    else
      result.add false, fldOptions
      
    # Add a services field
    fldOptions =
      field: 'services'
      store: 'yes'
    if doc.Links?
      result.add link.ServiceType, fldOptions for link in doc.Links when link.ServiceType?
    
    # Add a title field
    fldOptions = 
      field: 'title'
      store: 'yes'
      index: 'not_analyzed' # This allows to sort by title effectively
    if doc.Title?
      result.add doc.Title, fldOptions
