#############################################
# The purpose of this Node.js script is to 
#  add additional Collections to records
#  already in some Collection
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

db = couch.getDb 'record'

# Specify the collection that already contains resources that you want to update
existingCollection = "9e15e1a59b768b330d029e86dc032d06"

# Specify the collections that you also want these resources added to
allCollections = [
  "fd62bbde5b68ce93e4ba348bc70328eb",
  "ba2f0b9d21f71acfe10609f76e0cfd6c",
  "fd62bbde5b68ce93e4ba348bc703d49e",
]
allCollections.push existingCollection

# Do you want to publish the records?
publish = true

addToMoreCollections = (input_collection, new_collections, publish=true) ->
  new_collections.push input_collection
  
  allDocOpts = 
    include_docs: true
    success: (results) ->
      for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
        update = false
        
        if not doc.Collections?
          doc.Collections = []
        if input_collection in doc.Collections
          doc.Collections = new_collections
          if publish is true 
            doc.Published = true
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
  
exports.addToMoreCollections = addToMoreCollections