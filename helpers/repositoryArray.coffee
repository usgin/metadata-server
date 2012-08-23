#############################################
# The purpose of this Node.js script is to 
#  list all Drupal Repository nodes
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'
root = exports ? this

db = couch.getDb 'record'

root.getNodes = getRepositoryNodes = (callback) ->
  viewOpts = 
    design: 'manage'
    format: 'fromDrupalRepository'
    success: (results) ->
      nodes = new Array()
      nodeLookup = new Object()
      for row in results.rows
        metadataUrl = row.key
        metadataId = row.id
        for node in row.value.nodes
          nodes.push parseInt(node) if node not in nodes
          nodeLookup[node] = 
            metadataId: metadataId
            metadataUrl: metadataUrl
      nodes.sort()
      callback nodes, nodeLookup        
    error: (err) ->
      console.log "Error retreiving docs: #{err}"
      return
  access.viewDocs db, viewOpts
  
#getRepositoryNodes (nodes) ->
#  for node in nodes
#    console.log "http://repository.usgin.org/uri_gin/usgin/dlio/#{node}"