module.exports = 
  map: (csv, debug=false) ->          
    doc =
      setProperty: (prop, value) ->
        obj = @
        props = prop.split '.'
        count = 0
        for p in props
          if obj[p]?
            obj = obj[p]
            count++
          else
            if count + 1 is props.length
              obj[p] = value
            else
              obj[p] = {}
              obj = obj[p]
              count++
    
    # Title
    doc.setProperty 'Title', csv['title'] || 'Missing'
    # Description
    doc.setProperty 'Description', csv['description'] || 'Missing'
    # Publication date
    doc.setProperty 'PublicationDate', csv['publication_date'] || 'Missing'
    # Resource id
    doc.setProperty 'ResourceId', csv['resource_id'] || 'Missing'
    
    # Authors
    doc.Authors = []
    
    pers = csv['originator_contact_person_name']
    if pers? then pers = pers.split '|'
    else # If no contact person exists, contact position will be used
      pers = csv['originator_contact_position_name']
      if pers? then pers = pers.split '|'
    if pers?
      for per in pers
        author = 
          Name: per
        doc.Authors.push author 
    else
      author = 
        Name: 'Missing'
      doc.Authors.push author            
    
    org = csv['originator_contact_org_name'] || 'Missing'
    (p.OrganizationName = org) for p, i in doc.Authors
      
    
    if debug
      return
    else
      emit csv._id, doc
    return              