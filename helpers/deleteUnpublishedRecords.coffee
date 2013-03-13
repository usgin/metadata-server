#############################################
# The purpose of this Node.js script is to 
#  delete all unpublished records
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'


dbRecord = couch.getDb 'record'       

# Delete alll unpublished records
allRecordsOpts = 
  include_docs: true
  success: (results) ->
    for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
      if not doc.Published
        deleteOpts = 
          id: doc._id
          rev: doc._rev
          success: (result) ->
            console.log "Deleted record #{result.id}"
            return
          error: (err) ->
            console.log "Error deleting record #{result.id}"
            return             
        access.deleteDoc dbRecord, deleteOpts
  error: ->
    console.log 'Error retrieving docs'
    return
access.listDocs dbRecord, allRecordsOpts


  
