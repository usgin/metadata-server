#############################################
# The purpose of this Node.js script is to 
#  add remove non-ASCII characters
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
      
      inspectObj = (obj) ->
        for key, value of obj
          if _.isString(value) and not /^[\000-\177]*$/.test(value)                       
            obj[key] = value.replace /[^\000-\177]/, ""
          else if _.isArray value
            obj[key] = (inspectObj arrayItem for arrayItem in value)
          else if _.isObject value
            obj[key] = inspectObj value
        return obj
  
      doc = inspectObj doc
              
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