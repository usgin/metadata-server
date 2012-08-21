#############################################
# The purpose of this Node.js script is to 
#  list all Drupal Repository nodes
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'

db = couch.getDb 'record'

viewOpts = 
  design: 'manage'
  format: 'fromDrupalRepository'
  success: (results) ->
    nodes = new Array()
    for row in results.rows
      metadataLink = row.key
      for node in row.value.nodes
        nodes.push parseInt(node) if node not in nodes
    nodes.sort()
    for node in nodes
      console.log "http://repository.usgin.org/uri_gin/usgin/dlio/#{node}"
  error: (err) ->
    console.log "Error retreiving docs: #{err}"
    return
access.viewDocs db, viewOpts
