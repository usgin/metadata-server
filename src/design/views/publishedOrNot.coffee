module.exports =
  map: (doc) ->

    repoUrl = "http://repository.stategeothermaldata.org/repository/resource/" + doc._id + "/"
    couchUrl = "http://couchdb.stategeothermaldata.org:8001/_utils/database.html?records/" + doc._id
    collectionIds = doc.Collection || []
    title = doc.Title || "Has no title"
    out = { title: title, repository: repoUrl, couch: couchUrl, collection: collectionIds }

    if doc.Published
      emit "published", out
    else
      emit "unpublished", out