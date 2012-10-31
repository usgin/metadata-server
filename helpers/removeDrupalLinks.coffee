#############################################
# The purpose of this Node.js script is to 
#  remove links to repository.usgin.org
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
      update = false
      
      if doc.Links?
        for link, index in doc.Links
          if link?
            if link.URL.match /repository\.usgin\.org/
              doc.Links.splice index, 1
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
  error: ->
    console.log 'Error retrieving docs'
    return
access.listDocs db, allDocOpts