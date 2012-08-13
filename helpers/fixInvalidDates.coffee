#############################################
# The purpose of this Node.js script is to 
#  change pub dates that are not properly
#  formatted into 1900-01-01T00:00:00
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'

db = couch.getDb 'record'

allDocOpts = 
  include_docs: true
  success: (results) ->
    for doc in (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
      pubDate = doc.PublicationDate or ''      
      fullDateRegex = /^(\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):([0-5]\d):([0-5]\d)/
      if not pubDate.match fullDateRegex
        # Everything in here doesn't match the full regex
        update = false
        
        # Space-padded for some reason
        hasSpacesRegex = /(^ +| *$)/
        hasSpaces = pubDate.match hasSpacesRegex
        if hasSpaces
          pubDate = pubDate.trim()
          if pubDate.match fullDateRegex
            doc.PublicationDate = pubDate
            update = true
            
        # Doesn't include seconds
        noSecondsRegex = /^(\d{4})-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])T([01]\d|2[0-3]):([0-5]\d)$/
        hasNoSeconds = pubDate.match noSecondsRegex        
        if hasNoSeconds
          doc.PublicationDate = "#{hasNoSeconds[1]}-#{hasNoSeconds[2]}-#{hasNoSeconds[3]}T#{hasNoSeconds[4]}:#{hasNoSeconds[5]}:00"           
          update = true
        
        # Doesn't include day or seconds
        veryScrewball = /^(\d{4})-(0[1-9]|1[0-2])-([01]\d|2[0-3]):([0-5]\d):([0-5]\d)$/
        hasNoDayNoSeconds = pubDate.match veryScrewball
        if hasNoDayNoSeconds
          doc.PublicationDate = "#{hasNoDayNoSeconds[1]}-#{hasNoDayNoSeconds[2]}-01T#{hasNoDayNoSeconds[3]}:#{hasNoDayNoSeconds[4]}:00"         
          update = true
          
        # Only has a year
        onlyYearRegex = /^(\d{4})$/
        hasOnlyYear = pubDate.match onlyYearRegex
        if hasOnlyYear
          doc.PublicationDate = "#{hasOnlyYear[1]}-01-01T00:00:00"
          update = true
        
        # I don't know what to make of this. These are garbage. Could add more ifs above if you find other mistakes.
        if not update          
          doc.PublicationDate = '1900-01-01T00:00:00'
        
        # Perform an actual update
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