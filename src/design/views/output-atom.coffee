module.exports =  
  map: (doc, debug = false) ->
    objGet = (obj, prop, defVal) ->
      return defVal if not obj?
      props = prop.split '.'
      count = 0
      for p in props
        if obj[p]?
          obj = obj[p]
          count++
          return obj if count is props.length
        else
          return defVal
          
    toXmlValidText = (value) ->
      if value? and typeof value is 'string'
        value = value.replace /&(?!(amp;|lt;|gt;|quot;|apos;|nbsp;))/g, '&amp;'
        value = value.replace /</g, '&lt;'
        value = value.replace />/g, '&gt;'
        value = value.replace /"/g, '&quot;'
        value = value.replace /'/g, '&apos;'
        value = value.replace /&nbsp;/g, ' '
      return value              
              
    atom =
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
              obj[p] = toXmlValidText value
            else
              obj[p] = {}
              obj = obj[p]
              count++
    
    # Entry
    atom.setProperty "title.$t", objGet doc, "Title", "No title given"
    
    # Id
    atom.setProperty "id.$t", doc._id
    
    # Authors
    atom.setProperty "author", []
    theAuthors = objGet doc, 'Authors', []
    for author, a in theAuthors
      thisPath = "author.#{ a }"
      atom.setProperty "#{ thisPath }.name.$t", objGet author, "Name", objGet author, "OrganizationName", ""
      atom.setProperty "#{ thisPath }.contactInformation.phone.$t", objGet author, "ContactInformation.Phone", ""
      atom.setProperty "#{ thisPath }.contactInformation.email.$t", objGet author, "ContactInformation.Email", ""
      atom.setProperty "#{ thisPath }.contactInformation.address.street.$t", objGet author, "ContactInformation.Address.Street", ""
      atom.setProperty "#{ thisPath }.contactInformation.address.city.$t", objGet author, "ContactInformation.Address.City", ""
      atom.setProperty "#{ thisPath }.contactInformation.address.state.$t", objGet author, "ContactInformation.Address.State", ""
      atom.setProperty "#{ thisPath }.contactInformation.address.zip.$t", objGet author, "ContactInformation.Address.Zip", ""    

    # Links
    atomLinks = [ { "href": "/metadata/record/#{ doc._id }/", "rel": "alternate" } ]    
    for link, l in doc.Links or []
      atomLink =
        "href": toXmlValidText objGet link, "URL", ""
      atomLink.serviceType = link.ServiceType if link.ServiceType?
      atomLink.layerId = link.LayerId if link.LayerId?
      atomLinks.push atomLink
    atom.setProperty "link", atomLinks
    
    # Date
    atom.setProperty "updated.$t", doc.ModifiedDate or ""
    
    # Summary
    atom.setProperty "summary.$t", objGet doc, "Description", ""
    
    # Bounding Box
    n = objGet doc, "GeographicExtent.NorthBound", 89
    s = objGet doc, "GeographicExtent.SouthBound", -89
    e = objGet doc, "GeographicExtent.EastBound", 179
    w = objGet doc, "GeographicExtent.WestBound", -179
    atom.setProperty "georss:box.$t", [w, s, e, n].join " " 
    
    # Finished!
    if debug
      return
    else
      emit doc._id, atom        