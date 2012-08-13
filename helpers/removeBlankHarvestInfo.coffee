#############################################
# The purpose of this Node.js script is to 
#  remove blank HarvestInformation elements
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
      
      # Get HarvestInformation
      hi = doc.HarvestInformation
      if hi?
        # If the required fields are not populated, remove the entry
        if (not hi.HarvestRecordId? or hi.HarvestRecordId is "") and (not hi.HarvestURL? or hi.HarvestURL is "") and (not hi.HarvestDate? or hi.HarvestDate is "")
          delete doc.HarvestInformation
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