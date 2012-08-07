#############################################
# The purpose of this Node.js script is to 
#  change any coordinates listed as strings
#  into float
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

db = couch.getDb 'record'

allDocOpts = 
  include_docs: true
  success: (results) ->
    for doc in (result.doc for result in results.rows)
      ex = doc.GeographicExtent
      update = false
      for bound, coord of ex
        ex[bound] = parseFloat coord if _.isString coord
        update = true
      if update
        updateOpts =
          id: doc._id
          data: doc
          success: (result) ->
            console.log "Updated #{result.id}"
            return
          error: (err) ->
            console.log "Error updating #{result.id}"
            return
        access.createDoc db, updateOpts
    return
  error: ->
    console.log 'Error retrieving docs'
    return
access.listDocs db, allDocOpts
