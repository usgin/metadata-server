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

    geojson =
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
              
    geojson.setProperty "id", doc._id
    geojson.setProperty "type", "Feature"
    geojson.setProperty "properties.Title", objGet doc, "Title", "No Title Given"
    geojson.setProperty "properties.Description", objGet doc, "Description", "No Description Given"    
    geojson.setProperty 'properties.Authors', objGet doc, 'Authors', []      
    geojson.setProperty 'properties.PublicationDate', objGet doc, 'PublicationDate', 'No Publication Date Given'    
    geojson.setProperty 'properties.Keywords', objGet doc, 'Keywords', []    
    geojson.setProperty 'properties.Distributors', objGet doc, 'Distributors', []    
    geojson.setProperty 'properties.Links', objGet doc, 'Links', []    
    geojson.setProperty 'properties.ModifiedDate', objGet doc, 'ModifiedDate', ''
    
    n = parseFloat objGet doc, "GeographicExtent.NorthBound", "89"
    s = parseFloat objGet doc, "GeographicExtent.SouthBound", "-89"
    e = parseFloat objGet doc, "GeographicExtent.EastBound", "179"
    w = parseFloat objGet doc, "GeographicExtent.WestBound", "-179"
    
    geojson.setProperty "bbox", [w, s, e, n]
    geojson.setProperty "geometry.type", "polygon"
    geojson.setProperty "geometry.coordinates", [[]]
    geojson.setProperty "geometry.coordinates.0.0", [w, n]
    geojson.setProperty "geometry.coordinates.0.1", [w, s]
    geojson.setProperty "geometry.coordinates.0.2", [e, s]
    geojson.setProperty "geometry.coordinates.0.3", [e, n]
    geojson.setProperty "geometry.coordinates.0.4", [w, n]
    geojson.setProperty "crs.type", "name"
    geojson.setProperty "crs.properties.name", "urn:ogc:def:crs:OGC:1.3:CRS84"
    
    if debug
      return
    else
      emit doc._id, geojson
    return