module.exports =  
  map: (atom) ->
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
      
    # Title / Description
    doc.setProperty 'Title', objGet atom, 'title.$t', 'No Title Was Given'
    doc.setProperty 'Description', objGet atom, 'summary.$t', 'No Description Was Given'
    
    # Authors
    atomAuthors = objGet atom, 'author', []
    atomAuthors = [ atomAuthors ] if atomAuthors.name?
    docAuthors = ({
      Name: objGet author, 'name.$t', 'No Name Was Given'
      ContactInformation:
        Phone: objGet author, 'contactInformation.phone.$t', 'No Phone Was Given'
        email: objGet author, 'contactInformation.email.$t', 'No email Was Given'
        Address:
          Street: objGet author, "contactInformation.address.street.$t", "No address found"
          City: objGet author, "contactInformation.address.city.$t", "No city found"
          State: objGet author, "contactInformation.address.state.$t", "No state found"
          Zip: objGet author, "contactInformation.address.zip.$t", "No zip found"
    } for author in atomAuthors)
    
    # There has to be one Author, even if it is blank
    docAuthors.push {
      Name: "No name found"
      ContactInformation:
        Phone: "No phone found"
        email: "No email found"
        Address:
          Street: "No address found"
          City: "No city found"
          State: "No state found"
          Zip: "No zip found"                
    } if docAuthors.length is 0

    doc.setProperty 'Authors', docAuthors

    # Publication date
    doc.setProperty 'PublicationDate', '1900-01-01T0:00:00'
    
    # Geographic Extent
    extent = objGet atom, 'georss:box.$t', null    
    extent = extent.split(' ') if extent?
    extent = [ -179, -89, 179, 89 ] if not extent?
    doc.setProperty 'GeographicExtent.WestBound', extent[0] || -179
    doc.setProperty 'GeographicExtent.SouthBound', extent[1] || -89
    doc.setProperty 'GeographicExtent.EastBound', extent[2] || 179
    doc.setProperty 'GeographicExtent.NorthBound', extent[3] || 89 
    
    # Use first author as distributor
    doc.setProperty 'Distributors', [ docAuthors[0] ]

    # Links    
    buildLink = (atomLink, serviceType) ->
      result = 
        URL: objGet atomLink, 'href', 'No URL Found'
      if serviceType
        rel = objGet atomLink, 'rel', 'alternate'
        if rel in [ 'scast:interfaceDescription', 'scast:serviceInterface' ]
          result.ServiceType = serviceType 
      if not result.ServiceType?
        guess = guessServiceType(result.URL)
        result.ServiceType = guess if guess?
      return result
    
    atomLinks = objGet atom, 'link', []
    atomLinks = [ atomLinks ] if atomLinks.href?
    scastSemantics = objGet atom 'scast:serviceSemantics.$t', null
        
    if scastSemantics?
      adjSemantics = scastSemantics.replace(/\./, ':').toUpperCase()
      serviceType = type for type in capServiceTypes when type.search(adjSemantics) isnt -1
    docLinks = (buildLink atomLink, serviceType for atomLink in atomLinks)
    doc.Links = docLinks
    
    # Finished!
    emit atom._id, doc
