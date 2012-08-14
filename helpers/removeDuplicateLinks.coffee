#############################################
# The purpose of this Node.js script is to 
#  find duplicated URLs in links
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
      update = false
    
      urlKeyed = {}
      for link, index in doc.Links when link?        
        if urlKeyed[link.URL]?
          matches = true
          for key, value in link           
            if urlKeyed[link.URL][key] isnt value
              matches = false
          if matches
            doc.Links.splice index, 1
            #console.log "Duplicated Link: #{link.URL}  --  #{urlKeyed[link.URL].URL}"
            update = true
          else
            console.log "Duplicated URL: #{link.URL} in doc #{doc._id}, different links"                        
        else
          urlKeyed[link.URL] = link      
      
        
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