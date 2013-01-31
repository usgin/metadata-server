#############################################
# The purpose of this Node.js script is to 
#  delete the collection and its records
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

db = couch.getDb 'record'

allDocOpts = 
  include_docs: true
  success: (results) ->
    for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
      if doc.Collections?
        for collection in doc.Collections
          if collection == "7742d85f1b4fe21bc34a753eb80027d3"
            deleteOpts = 
              id: doc._id
              rev: doc._rev
              success: (result) ->
                console.log "Deleted #{result.id}"
                return
              error: (err) ->
                console.log "Error deleting #{result.id}"
                return             
            access.deleteDoc db, deleteOpts
  error: ->
    console.log 'Error retrieving docs'
    return
access.listDocs db, allDocOpts