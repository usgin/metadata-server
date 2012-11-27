module.exports = 
  map: (csv, debug=false) ->
    doc = {}
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
             
    # Set contacts for authors and distributors
    # 'prop' is array type
    # 'obj' is the contact model with related CSV fields
    setContacts = (prop, obj) ->
      pers = csv[obj.person]
      if pers? then pers = pers.split '|'
      else # If no contact person exists, contact position will be used
        pers = csv[obj.position]
        if pers? then pers = pers.split '|'
      if pers?
        for per in pers
          author = 
            Name: per
          prop.push author 
      else
        author = 
          Name: 'Missing'
        prop.push author            
      
      org = csv[obj.orgnization] || 'Missing'
      (a.OrganizationName = org) for a, i in prop
      
      for a, i in prop
        coninfo = a.ContactInformation = {}
        coninfo.Phone = csv[obj.phone] || 'Missing'
        coninfo.email = csv[obj.email] || 'Missing'
        addr = coninfo.Address = {}
        addr.Street = csv[obj.street] || 'Missing'
        addr.City = csv[obj.city] || 'Missing'
        addr.State = csv[obj.state] || 'Missing'
        addr.Zip = csv[obj.zip] || 'Missing'
 
    # Title
    doc.Title = csv['title'] || 'Missing'
    # Description
    doc.Description = csv['description'] || 'Missing'
    # Publication date
    doc.PublicationDate = csv['publication_date'] || 'Missing'
    # Resource id
    doc.ResourceId = csv['resource_id'] || 'Missing'
    
    # Authors
    doc.Authors = []
    obj = 
      person: 'originator_contact_person_name'
      position: 'originator_contact_position_name'
      orgnization: 'originator_contact_org_name'
      phone: 'originator_contact_phone'
      email: 'originator_contact_email'
      street: 'originator_contact_street_address'
      city: 'originator_contact_city'
      state: 'originator_contact_state'
      zip: 'originator_contact_zip'
    
    setContacts doc.Authors, obj
    
    # Keywords
    doc.Keywords = []
    kws = csv['keywords_thematic']
    if kws? then (doc.Keywords = doc.Keywords.concat kws.split '|')  
    kws = csv['keywords_spatial']
    if kws? then (doc.Keywords = doc.Keywords.concat kws.split '|') 
    kws =  csv['keywords_temporal']
    if kws? then (doc.Keywords = doc.Keywords.concat kws.split '|')
    
    # Geographic extent
    doc.GeographicExtent =      
      NorthBound: csv['north_bounding_latitude'] || 'Missing'
      SouthBound: csv['south_bounding_latitude'] || 'Missing'
      EastBound: csv['east_bounding_longitude'] || 'Missing'
      WestBound: csv['west_bounding_longitude'] || 'Missing'
    
    # Distributors
    doc.Distributors = []
    obj = 
      person: 'distributor_contact_person_name'
      position: 'distributor_contact_position_name'
      orgnization: 'distributor_contact_org_name'
      phone: 'distributor_contact_phone'
      email: 'distributor_contact_email'
      street: 'distributor_contact_street_address'
      city: 'distributor_contact_city'
      state: 'distributor_contact_state'
      zip: 'distributor_contact_zip'    
    
    setContacts doc.Distributors, obj
    
    # Links
    doc.Links = []
    links = csv['resource_url']
    if links? then links = links.split '|' else links = []
    for link in links
      objLink = 
        URL: 'Missing'
        Name: 'Resource URL'
        Description: 'Missing'
        Distributor: 'Missing' 
      urls = link.split ']'
      if urls.length is 2
        objLink.URL = urls[1]
        objLink.Description = urls[0].replace(' [', '')
      else
        objLink.URL = link
      
      serviceType = guessServiceType link
      if serviceType then objLink.ServiceType = serviceType
      
      doc.Links.push objLink
      
    # Metadata contact
    doc.MetadataContact = 
      Name: csv['metadata_contact_person_name'] || csv['metadata_contact_position_name'] || 'Missing'
      OrganizationName: csv['metadata_contact_org_name'] || 'Missing'
      ContactInformation:
        Phone: csv['metadata_contact_phone'] || 'Missing'
        email: csv['metadata_contact_email'] || 'Missing'
        Address:
          Street: csv['metadata_contact_street_address'] || 'Missing'
          City: csv['metadata_contact_city'] || 'Missing'
          State: csv['metadata_contact_state'] || 'Missing'    
          Zip: csv['metadata_contact_zip'] || 'Missing'
    
    # Harvest information
    doc.HarvestInformation = 
      OriginalFileIdentifier: csv['resource_id'] || 'csv-metadata'
    
    # Published
    doc.Published = false    
      
    if debug
      return
    else
      emit csv._id, doc
    return              