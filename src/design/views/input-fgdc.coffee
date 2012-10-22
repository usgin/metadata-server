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
        for condition in conditionSet
          if not url.match(condition)? 
            satisfied = false 
        return type if satisfied
      return null   
    
    # Build a contact based on the contact schema
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
    
    # Build a link based on the link schema
    buildLink = (url) ->
      link = 
        URL: url
        Name: "Missing"
        Description: "Missing"
        Distributor: "Missing"
        
      guess = guessServiceType url
      link.ServiceType = guess if guess?
      
      return link  
    
    # Find the identification info
    ident = objGet fgdc, "metadata.idinfo", {}
    
    # Title
    doc.setProperty "Title", objGet ident, "citation.citeinfo.title.$t", "Missing"
    
    # Description #
    # Obtained from 3 elements:
    # /metadata/idinfo/descript/abstract
    # /metadata/idinfo/descript/purpose
    # /metadata/idinfo/descript/supplinf
    desc = objGet ident, "descript.abstract.$t", null
    desc = desc + objGet ident, "descript.purpose.$t", null
    desc = desc + objGet ident, "descript.supplinf", null
    if desc?
      doc.setProperty "Description", desc
    else
      doc.setProperty "Description", "Missing"
           
    # Publication date #
    # Obtained from 2 elements:
    # /metadata/idinfo/citation/citeinfo/pubdate
    # /metadata/idinfo/citation/citeinfo/pubtime
    pubdate = objGet ident, "citation.citeinfo.pubdate.$t", null
    pubdate = pubdate + objGet ident, "citation.citeinfo.pubtime.$t", null
    if pubdate?
      doc.setProperty "PublicationDate", pubdate 
    else
      doc.setProperty "PublicationDate", "Missing"
    
    # Resource id
    doc.setProperty "ResourceId", (objGet fgdc, "metadata.distinfo.resdesc.$t", "metadata") + "-" + (objGet ident, "citation.citeinfo.onlink.$t", "Missing")
    
    # Authors #
    # Obtained from:
    # /metadata/idinfo/citation/citeinfo/origin (only for author name) 
    doc.Authors = []
    origins = objGet ident, "citation.citeinfo.origin", []
    if origins["$t"]
      origins = [origins]  
    doc.Authors.push buildContact origin["$t"] for origin in origins  
    
    # Keywords #
    # Obtained from 4 elements:
    # /metadata/idinfo/keywords/theme/themekey
    # /metadata/idinfo/keywords/place/placekey
    # /metadata/idinfo/keywords/stratum/stratkey
    # /metadata/idinfo/keywords/temporal/tempkey 
    doc.Keywords = []
    themeKeywords = objGet ident, "keywords.theme.themekey", []
    doc.Keywords.push keyword["$t"] for keyword in themeKeywords
    placeKeywords = objGet ident, "keywords.place.placekey", []
    doc.Keywords.push keyword["$t"] for keyword in placeKeywords  
    stratKeywords = objGet ident, "keywords.stratum.stratkey", []
    doc.Keywords.push keyword["$t"] for keyword in stratKeywords
    tempKeywords = objGet ident, "keywords.temporal.tempkey", []
    doc.Keywords.push keyword["$t"] for keyword in tempKeywords  
    
    # Geographic extent #
    # Obtained from:
    # /metadata/idinfo/spdom/bounding
    doc.setProperty "GeographicExtent.WestBound", objGet ident, "spdom.bounding.westbc.$t", "Missing"
    doc.setProperty "GeographicExtent.EastBound", objGet ident, "spdom.bounding.eastbc.$t", "Missing"
    doc.setProperty "GeographicExtent.NorthBound", objGet ident, "spdom.bounding.northbc.$t", "Missing"
    doc.setProperty "GeographicExtent.SouthBound", objGet ident, "spdom.bounding.southbc.$t", "Missing"

    # Distributors #
    # Obtained from :
    # /metadata/metadata/distinfo/distrib/cntinfo
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
    
    # Links #
    # Obtained from 3 elements:
    # /metadata/idinfo/citation/citeinfo/onlink 
    # /metadata/idinfo/crossref/citeinfo/onlink
    # /metadata/dataqual/lineage/srcinfo/srccite/citeinfo/onlink
    doc.Links = []
    linksCite = objGet ident, "citation.citeinfo.onlink", null
    linksCite = [linksCite] if linksCite["$t"]?
    for linkCite in linksCite
      doc.Links.push buildLink linkCite["$t"] if linkCite["$t"]? 
    
    crossRefs = objGet ident, "crossref", []
    if crossRefs["citeinfo"]
      crossRefs = [crossRefs]
    for crossRef in crossRefs
      linksRef = objGet crossRef, "citeinfo.onlink", []
      if linksRef["$t"]
        linksRef = [linksRef]
      for linkRef in linksRef
        onlink = objGet linkRef, "$t", null
        doc.Links.push buildLink onlink if onlink?
        
    srcInfos = objGet fgdc, "metadata.dataqual.lineage.srcinfo", []
    if srcInfos["srccite"]
      srcInfos = [srcInfos]
    for srcInfo in srcInfos    
      linksSrc = objGet srcInfo, "srccite.citeinfo.onlink", []
      if linksSrc["$t"]
        linksSrc = [linksSrc]
      for linkSrc in linksSrc
        onlink = objGet linkSrc, "$t", null
        doc.Links.push buildLink onlink if onlink?
        
    # Metadata contact #
    # Obtained from:
    # /metadata/idinfo/ptcontac/cntinfo
    metaContact = objGet ident, "ptcontac.cntinfo", {}
    
    entity = (objGet metaContact, "cntperp", null) || (objGet metaContact, "cntorgp", "Missing")
    contPer = objGet entity, "cntper.$t", "Missing"
    contOrg = objGet entity, "cntorg.$t", "Missing"

    contTel = objGet metaContact, "cntvoice", "Missing"
    if (not contTel["$t"]?) and (contTel != "Missing")
      contTel = objGet contTel[0], "$t", "Missing"
    else
      if (contTel != "Missing")
        contTel = objGet contTel, "$t", "Missing"
    
    contEma = objGet metaContact, "cntemail", "Missing"
    if (not contEma["$t"]?) and (contEma != "Missing")
      contEma = objGet contEma[0], "$t", "Missing"
    else
      if (contEma != "Missing")
        contEma = objGet contEma, "$t", "Missing"
    
    address = objGet metaContact, "cntaddr", "Missing"
    if (not address["address"]?) and (address != "Missing")
      address = address[0]
    
    contStr = objGet address, "address", "Missing"
    if (not contStr["$t"]?) and (contStr != "Missing")
      contStr = contStr[0]
    else
      if (contStr != "Missing")
        contStr = objGet contStr, "$t", "Missing"
    
    contCit = objGet address, "city.$t", "Missing"  
    contSta = objGet address, "state.$t", "Missing"
    contZip = objGet address, "postal.$t", "Missing"
    
    doc.setProperty "MetadataContact", buildContact contPer, contOrg, contTel, contEma, contStr, contCit, contSta, contZip
    
    # Harvest information
    doc.setProperty "HarvestInformation.OriginalFileIdentifier", (objGet fgdc, "metadata.distinfo.resdesc.$t", "metadata") + "-" + (objGet ident, "citation.citeinfo.onlink.$t", "Missing")
    
    # Published
    doc.setProperty "Published", false
    # Finished!
    if debug
      return
    else
      emit fgdc._id, doc
    return