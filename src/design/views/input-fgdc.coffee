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
    
    # Finished!
    if debug
      return
    else
      emit fgdc._id, doc
    return