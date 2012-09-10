module.exports =  
  map: (iso, debug=false) ->         
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
    
    # Build a Contact
    buildContact = (responsibleParty) ->
      role = objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:role.gmd:CI_RoleCode.codeListValue", ""
      contact = 
        Name: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:individualName.gco:CharacterString.$t", "No Name Was Given"
        ContactInformation:
          Phone: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:phone.gmd:CI_Telephone.gmd:voice.gco:CharacterString.$t", "No Phone Number Was Given"
          email: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:address.gmd:CI_Address.gmd:electronicMailAddress.gco:CharacterString.$t", "No email Was Given"
          Address:
            Street: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:address.gmd:CI_Address.gmd:deliveryPoint.gco:CharacterString.$t", "No Street Address Was Given"
            City: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:address.gmd:CI_Address.gmd:city.gco:CharacterString.$t", "No City Was Given"
            State: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:address.gmd:CI_Address.gmd:administrativeArea.gco:CharacterString.$t", "No State Was Given"
            Zip: objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:contactInfo.gmd:CI_Contact.gmd:address.gmd:CI_Address.gmd:postalCode.gco:CharacterString.$t", "No Zip Was Given"
      if contact.Name in [ 'Missing', 'missing', 'No Name Was Given' ]
        contact["OrganizationName"] = objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:organisationName.gco:CharacterString.$t", "No Organization Name Was Given"
      return contact
    
    # Build a Link
    buildLink = (onlineResource, responsibleParty) ->
      url = objGet onlineResource, "gmd:linkage.gmd:URL.$t", "No URL Was Given"
      protocol = objGet onlineResource, "gmd:protocol.gco:CharacterString.$t", "No Protocol Was Given"
      protocol = protocol.toUpperCase()     
      if capServiceTypes.indexOf(protocol) >= 0
        serviceType = protocol
      else
        guess = guessServiceType(url)
        serviceType = guess if guess?
      
      name = null
      if responsibleParty?
        name = objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:individualName.gco:CharacterString.$t", "No Name Was Given"
        if name in [ 'Missing', 'missing', 'No Name Was Given' ]
          name = objGet responsibleParty, "gmd:CI_ResponsibleParty.gmd:organisationName.gco:CharacterString.$t", "No Organization Name Was Given"
                
      link =
        URL: url
        Description: objGet onlineResource, "gmd:description.gco:CharacterString.$t", "No Description Was Given"
      link.ServiceType = serviceType if serviceType?
      link.Distributor = name if name?
      return link
      
    # Find the appropriate identification info -- if there are multiple, the first is used.
    ident = objGet iso, "gmd:MD_Metadata.gmd:identificationInfo", {}
    ident = objGet ident, "0", ident
    ident = objGet ident, "gmd:MD_DataIdentification", objGet ident, "srv:SV_ServiceIdentification", {}
    
    # Find title/description
    doc.setProperty "Title", objGet ident, "gmd:citation.gmd:CI_Citation.gmd:title.gco:CharacterString.$t", "No Title Was Given"
    doc.setProperty "Description", objGet ident, "gmd:abstract.gco:CharacterString.$t", "No Description Was Given"
    
    # Publication Date
    pubDate = objGet(ident, "gmd:citation.gmd:CI_Citation.gmd:date.gmd:CI_Date.gmd:date.gco:DateTime.$t", "Publication Date Not Given").trim();
    pubDate = pubDate + ":00Z" if pubDate.match(/T\d\d:\d\d(?!:)/)?
    doc.setProperty "PublicationDate", pubDate
    
    # Metadata Contact
    metaContact = objGet iso, "gmd:MD_Metadata:gmd:contact"
    doc.setProperty 'MetadataContact', buildContact metaContact
    
    # Authors
    respParties = objGet ident, "gmd:citation.gmd:CI_Citation.gmd:citedResponsibleParty", []    
    respParties = [ respParties ] if respParties['gmd:CI_ResponsibleParty']?
    authors = (buildContact respParty for respParty in respParties)
    doc.setProperty 'Authors', authors
    
    # Keywords
    doc.Keywords = []
    descKeywords = objGet ident, 'gmd:descriptiveKeywords', []
    descKeywords = [ descKeywords ] if descKeywords['gmd:MD_Keywords']?
    for descKeyword in descKeywords
      keywords = objGet descKeyword, "gmd:MD_Keywords.gmd:keyword", []
      keywords = [ keywords ] if keywords['gco:CharacterString']?
      for keyword in keywords
        words = objGet keyword, 'gco:CharacterString.$t', null        
        doc.Keywords.push word.trim() for word in words.split(',') if words?
        
    # Geographic Extent
    extent = objGet ident, 'gmd:extent', objGet ident, 'srv:extent', {}
    if extent['0']?
      validExtents = (ext for ext in extent when (objGet ext, 'gmd:EX_Extent.gmd:geographicElement', null)?)
      extent = validExtents[0]
          
    doc.setProperty "GeographicExtent.NorthBound", parseFloat objGet extent, "gmd:EX_Extent.gmd:geographicElement.gmd:EX_GeographicBoundingBox.gmd:northBoundLatitude.gco:Decimal.$t", 89
    doc.setProperty "GeographicExtent.SouthBound", parseFloat objGet extent, "gmd:EX_Extent.gmd:geographicElement.gmd:EX_GeographicBoundingBox.gmd:southBoundLatitude.gco:Decimal.$t", -89
    doc.setProperty "GeographicExtent.EastBound", parseFloat objGet extent, "gmd:EX_Extent.gmd:geographicElement.gmd:EX_GeographicBoundingBox.gmd:eastBoundLongitude.gco:Decimal.$t", 179
    doc.setProperty "GeographicExtent.WestBound", parseFloat objGet extent, "gmd:EX_Extent.gmd:geographicElement.gmd:EX_GeographicBoundingBox.gmd:westBoundLongitude.gco:Decimal.$t", -179

    # Distributors
    isoDistributors = objGet iso, "gmd:MD_Metadata.gmd:distributionInfo.gmd:MD_Distribution.gmd:distributor", []
    isoDistributors = [ isoDistributors ] if isoDistributors['gmd:MD_Distributor']?
    doc.Distributors = (buildContact objGet isoDist, "gmd:MD_Distributor.gmd:distributorContact", {} for isoDist in isoDistributors)

    # Distribution information
    linksList = {}
    
    onlineResource = (distOption) ->
        return objGet distOption, "gmd:MD_DigitalTransferOptions.gmd:onLine.gmd:CI_OnlineResource", {}
    
    # Links that are not attached to a distributor    
    distributions = objGet iso, "gmd:MD_Metadata.gmd:distributionInfo.gmd:MD_Distribution.gmd:transferOptions", []
    distributions = [ distributions ] if distributions["gmd:MD_DigitalTransferOptions"]?
    moreLinks = (buildLink onlineResource distOpt for distOpt in distributions)
    
    # Distributor Links    
    linkLookup = {}
    for distribution in distributions
      id = objGet(distribution, "gmd:MD_DigitalTransferOptions.id", "")
      linkLookup[id] = distribution
      
    getDistributorLink = (dist) ->
      id = dist['xlink:href'].replace '#', ''      
      result = linkLookup[id]            
      return result    
              
    for isoDist in isoDistributors
      distOptions = objGet isoDist, "gmd:MD_Distributor.gmd:distributorTransferOptions", []
      distOptions = [ distOptions ] if distOptions['gmd:MD_DigitalTransferOptions']? or distOptions['xlink:href']?       
      distOutput = []
      
      # xlinked ones should be in the regular transfer options, need to find the one with the right ID
      for dist, idx in distOptions
        if dist['xlink:href']?
          distOutput.push getDistributorLink dist          
        else
          distOutput.push dist    
      
      # Build all the links for this distributor            
      responsibleParty = objGet isoDist, "gmd:MD_Distributor.gmd:distributorContact", {}             
      distributorLinks = (buildLink onlineResource(distOpt), responsibleParty for distOpt in distOutput)
      
      # Add them to the linksList
      for link in distributorLinks
        linksList[link.URL] = link
        
    # Add leftover links    
    for link in moreLinks
      linksList[link.URL] = link if not linksList[link.URL]?
    
    # Add links to the doc
    doc.Links = (link for url, link of linksList)
    
    # ResourceID
    doc.setProperty 'ResourceId', objGet iso, "gmd:MD_Metadata.gmd:dataSetURI.gco:CharacterString.$t", null
    
    # Harvest Information
    doc.setProperty "HarvestInformation.OriginalFileIdentifier", objGet iso, "gmd:MD_Metadata.gmd:fileIdentifier.gco:CharacterString.$t"
    
    # Published
    doc.setProperty "Published", false
    
    # Finished!
    if debug
      return
    else
      emit iso._id, doc
    return
    



















