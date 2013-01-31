#############################################
# The purpose of this Node.js script is to 
#  delete the collection and its records
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

dbCollection = couch.getDb 'collection'
dbRecord = couch.getDb 'record'

process.argv.forEach (val, index, array)-> 
  # Delete the collection
  allCollectionsOpts = 
    include_docs: true
    success: (results) ->
      for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
        if doc._id == val
          deleteOpts = 
            id: doc._id
            rev: doc._rev
            success: (result) ->
              console.log "Deleted collection #{result.id}"
              return
            error: (err) ->
              console.log "Error deleting collection #{result.id}"
              return             
          access.deleteDoc dbCollection, deleteOpts
  access.listDocs dbCollection, allCollectionsOpts         

  # Delete the records under that collection
  allRecordsOpts = 
    include_docs: true
    success: (results) ->
      for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
        if doc.Collections?
          for collection in doc.Collections
            if collection == val
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


  
