da = require './data-access'
_ = require 'underscore'

# CouchDB configuration options
config =
  dbHost: 'localhost'
  dbPort: 5984
  dbVersion: 1.1

# Setup Nano connection to CouchDB    
couchUrl = 'http://' + config.dbHost + ':' + config.dbPort
nano = require('nano')(couchUrl)
recordsDb = nano.db.use 'records'
collectionsDb = nano.db.use 'collections'
harvestsDb = nano.db.use 'harvests'

# Collect Design Documents
designDocs = 
  records: [ 
    require('./design/collections')
    require('./design/output')
    require('./design/search')
    require('./design/manage')
    require('./design/returnPublished')
    require('./design/helpers')
  ]
  collections: [ require('./design/collectionInfo') ]
  harvests: [ require('./design/input') ]

# Search URLs
searchUrl = "http://#{ config.dbHost }:#{ config.dbPort }/records/_fti/_design/search/"
# It turns out even versions >= 1.1 can work the old way. It depends on configuration in couchdb's local.ini
#searchUrl = "http://#{ config.dbHost }:#{ config.dbPort }/_fti/local/records/_design/search/" if config.dbVersion >= 1.1  

# Setup routines
createDb = (dbName) ->
  nano.db.list (err, list) ->
    if err?
      console.log err
    else
      if dbName not in list
        nano.db.create dbName, (err, response) ->
          if err?
            console.log err
          else
            console.log "Created #{ dbName } database"
            saveDesignDoc dbName, designDoc for designDoc in designDocs[dbName] if designDocs[dbName]?
      else
        saveDesignDoc dbName, designDoc for designDoc in designDocs[dbName] if designDocs[dbName]?
            
saveDesignDoc = (dbName, designDoc) ->
  opts = # The first getDoc request gets the existing design doc
    id: designDoc._id
    error: (err) ->
      if err['status-code']? and err['status-code'] = 404
        @success {} # There was no existing design doc. Create a new one.
      else
        console.log err
    success: (doc) ->
      opts = # The second request updates the design doc
        id: designDoc._id
        data: _.extend doc, designDoc
        error: (err) ->
          console.log err
        success: (result) ->
          console.log "Updated views in #{ dbName }"
      da.createDoc couch.dbs[dbName], opts
  da.getDoc couch.dbs[dbName], opts
    
# Expose connections to the necessary databases, helper functions
module.exports = couch =
  recordsDb: recordsDb
  collectionsDb: collectionsDb
  harvestsDb: harvestsDb 
  dbs:
    records: recordsDb
    collections: collectionsDb  
    harvests: harvestsDb
  
  searchUrl: searchUrl
  
  fileUrl: (id, filename) ->
    return [ couchUrl, 'records', id, filename ].join('/')
      
  getDb: (resourceType) ->  
    switch resourceType
      when 'record' then return recordsDb
      when 'collection' then return collectionsDb
      when 'harvest' then return harvestsDb
              
  setupDbs: ->
    createDb dbName for dbName in [ 'records', 'collections', 'harvests' ]
    
    
