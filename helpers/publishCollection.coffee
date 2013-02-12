#####################################################
# The purpose of this Node.js script is to 
#  publish the records under the specified collection
#####################################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

dbRecord = couch.getDb 'record'

process.argv.forEach (val, index, array)-> 
  # Publish the records under that collection
  allRecordsOpts = 
    include_docs: true
    success: (results) ->
      for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
        if doc.Collections?
          for collection in doc.Collections
            if collection == val
              if not doc.Published
                doc.Published = true
                update = true      
              if update
                opts =
                  id: doc._id
                  data: doc
                  success: (result) ->
                    console.log "Published #{result.id}"
                    return
                  error: (err) ->
                    console.log "Error publishing #{result.id}"
                    return           
              access.createDoc dbRecord, opts
    error: ->
      console.log 'Error retrieving docs'
      return
  access.listDocs dbRecord, allRecordsOpts