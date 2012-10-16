module.exports = 
	map: (fgdc, debug=false) ->
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
              
    # List of service type identifiers
    serviceTypes = ["OGC:WMS", "OGC:WFS", "OGC:WCS", "esri", "opendap"]
    capServiceTypes = (type.toUpperCase() for type in serviceTypes)
    
    # Guess if a URL is one or another type of service
    guessServiceType = (url) ->
      conditions = [
        [/getcapabilities/i, /wms/i]
        [/getcapabilities/i, /wfs/i]
        [/getcapabilities/i, /wcs/i]
        [/\/services\//i, /\/mapserver\/?$/i]
        [/\.dds$/]
      ]
      
      for type, i in serviceTypes
        conditionSet = conditions[i]
        satisfied = true
        satisfied = false if not url.match(condition)? for condition in conditionSet
        return type if satisfied
      return null   
    
    # Build a contact
    buildContact = (name, organization, phone, email, street, city, state, zip) ->
      contact = 
        Name: name || "Missing"
        OrganizationName: organization || "Missing"
        ContactInformation: 
          Phone: phone || "Missing"
          email: email || "Missing"
          Address:
            Street: street || "Missing"
            City: city || "Missing"
            State: state || "Missing"
            Zip: zip || "Missing"
      return contact
      
    
    # Find the identification info
    ident = objGet fgdc, "metadata.idinfo", {}
    
    # Title
    doc.setProperty "Title", objGet ident, "citation.citeinfo.title.$t", "No Title Was Given"
    
    # Description
    desc = objGet ident, "descript.abstract.$t", null
    desc = desc + objGet ident, "descript.purpose.$t", null
    desc = desc + objGet ident, "descript.supplinf", null
    if desc?
      doc.setProperty "Description", desc
    else
      doc.setProperty "Description", "No Description Was Given"
           
    # Publication date
    pubdate = objGet ident, "citation.citeinfo.pubdate.$t", null
    pubdate = pubdate + objGet ident, "citation.citeinfo.pubtime.$t", null
    if pubdate?
      doc.setProperty "PublicationDate", pubdate 
    else
      doc.setProperty "PublicationDate", "No Publication Date Was Given"
    
    # Resource id
    doc.setProperty "ResourceId", objGet ident, "citation.citeinfo.onlink.$t", "No Resource Id Was Given"
    
    # Authors
    doc.Authors = []
    origins = objGet ident, "citation.citeinfo.origin", []
    if origins["$t"]
      origins = [origins]  
    doc.Authors.push buildContact origin["$t"] for origin in origins  
    
    # Keywords
    doc.Keywords = []
    themeKeywords = objGet ident, "keywords.theme.themekey", []
    doc.Keywords.push keyword["$t"] for keyword in themeKeywords
    placeKeywords = objGet ident, "keywords.place.placekey", []
    doc.Keywords.push keyword["$t"] for keyword in placeKeywords  
    stratKeywords = objGet ident, "keywords.stratum.stratkey", []
    doc.Keywords.push keyword["$t"] for keyword in stratKeywords
    tempKeywords = objGet ident, "keywords.temporal.tempkey", []
    doc.Keywords.push keyword["$t"] for keyword in tempKeywords  
    
    # Geographic extent
    doc.setProperty "GeographicExtent.WestBound", objGet ident, "spdom.bounding.westbc.$t", "Missing"
    doc.setProperty "GeographicExtent.EastBound", objGet ident, "spdom.bounding.eastbc.$t", "Missing"
    doc.setProperty "GeographicExtent.NorthBound", objGet ident, "spdom.bounding.northbc.$t", "Missing"
    doc.setProperty "GeographicExtent.SouthBound", objGet ident, "spdom.bounding.southbc.$t", "Missing"

    # Distributors
    doc.Distributors = []
    distributors = objGet fgdc, "metadata.distinfo", []
    if distributors.distrib?
      distributors = [distributors]
    for distributor in distributors
      distPer = objGet distributor, "distrib.cntinfo.cntorgp.cntper.$t", "Missing"
      distOrg = objGet distributor, "distrib.cntinfo.cntorgp.cntorg.$t", "Missing"
      distTel = objGet distributor, "distrib.cntinfo.cntvoice.$t", "Missing"
      distEma = objGet distributor, "distrib.cntinfo.cntemail.$t", "Missing"
      distStr = objGet distributor, "distrib.cntinfo.cntaddr.address.$t", "Missing"
      distCit = objGet distributor, "distrib.cntinfo.cntaddr.city.$t", "Missing"
      distSta = objGet distributor, "distrib.cntinfo.cntaddr.state.$t", "Missing"
      distZip = objGet distributor, "distrib.cntinfo.cntaddr.postal.$t", "Missing"
      doc.Distributors.push buildContact distPer, distOrg, distTel, distEma, distStr, distCit, distSta, distZip       

    # Finished!
    if debug
      return
    else
      emit fgdc._id, doc
    return