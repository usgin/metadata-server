module.exports =  
  map: (doc) ->
    if doc.Links?
      fromDrupal = false
      links = new Array()
      nodes = new Array()
      for link in doc.Links
        if link.URL.match /mw\.usgin\.org/
          fromDrupal = true
          links.push link.URL
          m = link.URL.match /\/dlio\/(\d{1,3})/
          nodes.push m[1]
      emit("/metadata/record/#{doc._id}/", {links: links, nodes: nodes}) if fromDrupal
    return