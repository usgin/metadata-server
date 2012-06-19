couch = require './couch-config'
utils = require './utils'
_ = require 'underscore'
errors = require './errors'
fs = require 'fs'
request = require 'request'
da = require './data-access'
xml2json = require 'xml2json'
  
### THESE ARE ALL THE ROUTE MIDDLEWARE FUNCTIONS ###
module.exports = routes = 


  # Text-based search for records
  search: (req, res, next) ->
    opts =
      search_terms: req.searchTerms
      limit: req.limit
      skip: req.skip
      published_only: req.publishedOnly or false
      error: (err) ->
        next new errors.DatabaseReadError 'Error searching for documents'
      success: (result) ->
        console.log 'SEARCH FOR ' + req.searchTerms
        res.header('Content-Type', 'application/json')
        res.send result
    da.search couch.searchUrl, opts
      
            
  # List records or collections (as JSON)
  listResources: (req, res, next) ->
    db = couch.getDb req.resourceType
    opts = 
      include_docs: true
      clean_docs: true
      error: (err) ->
        next new errors.DatabaseReadError 'Error listing documents'
      success: (result) ->
        console.log 'GET ALL ' + req.resourceType + 's'
        res.send result    
    da.listDocs db, opts
  
        
  # List records in a specific format
  viewRecords: (req, res, next) ->
    db = couch.getDb 'record'
    if req.format.match(/iso\.xml/)? # Handle the special case for iso.xml > web-accessible folder
      opts =
        error: (err) ->
          next new errors.DatabaseReadError 'Error listing documents'
        success: (result) ->
          console.log 'VIEW ALL records AS ' + req.format
          res.render 'waf.jade', { title: 'Placeholder Title', records: (row.id for row in result.rows when not row.id.match(/^_/)?) }
      da.listDocs db, opts      
    else
      opts =
        design: 'output'
        format: req.format
        clean_docs: true
        error: (err) ->
          next new errors.DatabaseReadError 'Error running database view'
        success: (result) ->
          if req.format.match(/atom\.xml/)? # Handle the special case for atom.xml's feed wrapper
            result = utils.atomWrapper result
            result = xml2json.toXml result
            res.header('Content-Type', 'text/xml')
          if req.format.match(/geojson/)? # Handle the special case for geojson's FeatureCollection wrapper
            result = utils.featureCollection result
          console.log 'VIEW ALL records AS ' + req.format
          res.send result    
      da.viewDocs db, opts
  
    
  # Create a new record or collection  
  newResource: (req, res, next) ->
    db = couch.getDb req.resourceType
    
    if not da.validateRecord req.body, req.resourceType
      next new errors.ValidationError 'Uploaded data did not pass validation'
    else
      opts =
        data: _.extend(req.body, { ModifiedDate: utils.getCurrentDate() })
        error: (err) ->
          next new errors.DatabaseWriteError 'Error writing to the database'
        success: (newRecord) ->
          console.log 'NEW ' + req.resourceType + ' CREATED'
          res.send '', { Location: "/metadata/#{ req.resourceType }/#{ newRecord.id }/" }, 201
      da.createDoc db, opts      
        
  # Harvest an existing record
  harvestRecord: (req, res, next) ->
    if not req.url? or not req.format?
      next new errors.ArgumentError 'Request did not supply the requisite arguments: url and format.'
    else
      opts = # The first request gets the data at the URL specified.
        uri: req.url
      request opts, (err, response, body) ->
        if err?
          next new errors.RequestError 'The given URL resulted in an error: ' + err
        else
          if not utils.validateHarvestFormat req.format, body
            next new errors.ValidationError 'The document at the given URL did not match the format specified.'
          else            
            db = couch.getDb 'harvest'
            data = xml2json.toJson(body, { object: true, reversible: true })
            switch req.format
              when 'atom.xml'
                entry = data.feed.entry
                if _.isArray entry then entries = entry
                else if _.isObject entry then entries = [ entry ]
                else entries = []
              when 'iso.xml'
                entries = [ data ]                                 
            opts = # The second request creates the records in the harvests database
              docs: entries
              error: (err) ->
                next new errors.DatabaseWriteError 'Error writing to the database'
              success: (newHarvestDocs) ->                 
                opts = # The third request pulls the harvested records through the appropriate input view
                  design: 'input'
                  format: req.format
                  keys: (doc.id for doc in newHarvestDocs)
                  error: (err) ->
                    next new errors.DatabaseReadError 'Error reading document from database'
                  success: (transformedDocs) ->
                    db = couch.getDb 'record'
                    for doc in transformedDocs.rows
                      harvestInfo =
                        OriginalFormat: req.format
                        HarvestURL: req.url
                        HarvestDate: utils.getCurrentDate()
                        HarvestRecordId: doc.id
                      _.extend doc.value.HarvestInformation, harvestInfo 
                      _.extend doc.value, { Collections: req.collections || [] }
                    opts = # The fourth request places the transformed docs into the record database
                      docs: (doc.value for doc in transformedDocs.rows)
                      error: (err) ->
                        next new errors.DatabaseWriteError 'Error writing to the database'
                      success: (newRecords) ->
                        console.log 'NEW ' + req.resourceType + ' HARVESTED'
                        res.send ("/metadata/record/#{ rec.id }/" for rec in newRecords), 200                        
                    da.createDocs db, opts
                da.viewDocs db, opts
            da.createDocs db, opts
            
            
  # Retrieve a specific record or collection (as JSON)
  getResource: (req, res, next) ->
    db = couch.getDb req.resourceType
    opts =
      id: req.resourceId
      clean_docs: true
      error: (err) ->
        if err['status-code']? and err['status-code'] = 404
          next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' 
        else
          next new errors.DatabaseReadError 'Error reading document from database'
      success: (result) ->
        console.log 'RETRIEVE ' + req.resourceType + ': ' + req.resourceId
        res.send result
    da.getDoc db, opts


  # Retrieve a specific record in a specific format  
  viewRecord: (req, res, next) ->
    db = couch.getDb 'record'
    opts =
      design: 'output'
      format: req.format
      clean_docs: true
      key: req.resourceId
      error: (err) ->
        next new errors.DatabaseReadError 'Error running database view'
      success: (result) ->
        if result.length is 0
          next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found'
        else
          console.log 'VIEW RECORD ' + req.resourceId + ' AS ' + req.format
          result = result[0]
          if req.format.match(/iso\.xml/)? # Handle the special case of ISO record that needs extra collection keywords
            opts =
              id: req.resourceId
              recordsDb: couch.getDb 'record'
              collectionsDb: couch.getDb 'collection'
              error: (err) ->
                next new errors.DatabaseReadError 'Error reading from the database'
              success: (names) ->
                result = xml2json.toXml utils.addCollectionKeywords result, names
                res.header 'Content-Type', 'text/xml'
                res.send result
            da.getCollectionNames opts                     
          else
            if req.format.match(/atom\.xml/)? # Handle the special case of atom and the feed wrapper it needs
              result = utils.atomWrapper [result]
              result = xml2json.toXml result
              res.header 'Content-Type', 'text/xml'
            res.send result
    da.viewDocs db, opts
    

  # Retrieve all the records in a specific collection (as JSON)
  getCollectionRecords: (req, res, next) ->
    db = couch.getDb 'collection'
    opts = # The first exists request checks to see if the collection exists at all
      id: req.resourceId
      error: (err) ->
        next new errors.DatabaseReadError 'Error reading from the database'
      success: (exists) ->
        if not exists
          next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found'
        else          
          db = couch.getDb 'record'
          opts = # The second viewDocs request finds the records that are a part of this collection
            design: 'collections'
            format: 'ids'
            clean_docs: true
            key: req.resourceId
            error: (err) ->
              next new errors.DatabaseReadError 'Error running database view'
            success: (result) ->              
                ids = (doc.id for doc in result)
                console.log 'GOT COLLECTION RECORDS: ' + ids
                res.send result
          da.viewDocs db, opts
    da.exists db, opts
    
    
  # Retrieve all the records in a specific collection in a specific format
  viewCollectionRecords: (req, res, next) ->
    db = couch.getDb 'collection'
    opts = # The first exists request checks to see if the collection exists at all
      id: req.resourceId
      error: (err) ->
        next new errors.DatabaseReadError 'Error reading from the database'
      success: (exists) ->
        if not exists
          next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found'
        else 
          db = couch.getDb 'record'
          opts = # The second viewDocs request finds the IDs for records that are a part of this collection
            design: 'collections'
            format: 'ids'
            key: req.resourceId
            error: (err) ->
              next new errors.DatabaseReadError 'Error running database view'
            success: (result) ->
              console.log 'GOT COLLECTION RECORDS: ' + (doc.id for doc in result.rows)
              if req.format.match(/iso\.xml/)? # Handle the special case for iso.xml > web-accessible folder
                res.render 'waf.jade', { title: 'Placeholder Title', records: (doc.id for doc in result.rows) }
              else
                opts = # The third viewDocs request retrieves the collection's records through the right view
                  design: 'output'
                  format: req.format
                  keys: (doc.id for doc in result.rows)
                  clean_docs: true
                  error: (err) ->
                    next new errors.DatabaseReadError 'Error running database view'
                  success: (result) ->
                    if req.format.match(/atom\.xml/)? # Handle the special case for atom.xml's feed wrapper
                      result = utils.atomWrapper result
                      result = xml2json.toXml result
                      res.header('Content-Type', 'text/xml')
                    if req.format.match(/geojson/)? # Handle the special case for geojson's FeatureCollection wrapper
                      result = utils.featureCollection result
                    console.log 'VIEW COLLECTION ' + req.resourceId + ' RECORDS AS ' + req.format                         
                    res.send result
                da.viewDocs db, opts
          da.viewDocs db, opts
    da.exists db, opts


  # Update an existing record or collection
  updateResource: (req, res, next) ->
    db = couch.getDb req.resourceType
    
    if not da.validateRecord req.body, req.resourceType
      next new errors.ValidationError 'Uploaded data did not pass validation'
    else
      opts = # The first getDoc request retrieves the existing document
        id: req.resourceId
        error: (err) ->
          if err['status-code']? and err['status-code'] is 404
            next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' 
          else
            next new errors.DatabaseReadError 'Error reading document from database'
        success: (result) ->
          opts = # The second createDoc request updates the document
            id: req.resourceId
            data: _.extend(result, req.body, { ModifiedDate: utils.getCurrentDate() })
            clean_docs: true
            error: (err) ->
              next new errors.DatabaseWriteError 'Error writing document to the database'
            success: (result) ->
              console.log 'UPDATE ' + req.resourceType + ': ' + req.resourceId
              res.send '', { Location: "/metadata/#{ req.resourceType }/#{ result.id }/" }, 204
          da.createDoc db, opts
      da.getDoc db, opts
      
      
  # Delete a record or collection
  deleteResource: (req, res, next) ->
    db = couch.getDb req.resourceType
    
    opts = # The first getRev request finds the documemt's current revision
      id: req.resourceId
      error: (err) ->
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (rev) ->
        opts = # The second deleteDoc request delete's the document
          id: req.resourceId
          rev: rev
          error: (err) ->
            next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
            next new errors.DatabaseWriteError 'Error writing document to the database'
          success: (result) ->
            console.log 'DELETE ' + req.resourceType + ': ' + req.resourceId
            res.send()
        da.deleteDoc db, opts
    da.getRev db, opts
    
    
  # List files associated with a specific record
  listFiles: (req, res, next) ->
    db = couch.getDb 'record'
    opts = 
      id: req.resourceId
      error: (err) ->
        next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (doc) ->
        console.log 'LIST FILES: ' + req.resourceId
        result = [] if not doc._attachments?
        result = ( { filename: name, location: "/metadata/record/#{ req.resourceId}/file/#{ name }" } for name, info of doc._attachments ) if doc._attachments?
        res.send result
    da.getDoc db, opts
    

  # Associate a new file with a specific record
  newFile: (req, res, next) ->
    db = couch.getDb 'record'
    opts = # The first request gets the record's current revision
      id: req.resourceId
      error: (err) ->
        next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (rev) ->
        # The second request attaches the file to the record.
        file = (file for key, file of req.files)[0]
        fileStream = fs.createReadStream file.path
        fileStream.pipe db.attachment.insert req.resourceId, file.name, null, file.type, { rev: rev }, (err, body) ->
        #fileStream.on 'close', ->
          
          opts =
            id: req.resourceId
            error: (err) ->
              if err['status-code']? and err['status-code'] is 404
                next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' 
              else
                next new errors.DatabaseReadError 'Error reading document from database'
            success: (result) ->
              # Add a link for the new file
              link =
                Name: file.name
                URL: "/metadata/record/#{ req.resourceId }/file/#{ file.name }"
                isLocal: true
              result.Links = [] if not result.Links?
              result.Links.push link
              
              opts = # The fourth createDoc request updates the document
                id: req.resourceId
                data: _.extend(result, { ModifiedDate: utils.getCurrentDate() })
                clean_docs: true
                error: (err) ->
                  next new errors.DatabaseWriteError 'Error writing document to the database'
                success: (result) ->
                  console.log 'NEW FILE: ' + file.name + ' ATTACHED TO: ' + req.resourceId
                  res.send '', { Location: "/metadata/record/#{ req.resourceId }/file/#{ file.name }" }, 201
              da.createDoc db, opts
          da.getDoc db, opts
    da.getRev db, opts
    
    
  # Retrieve a specific file associated with a specific record
  getFile: (req, res, next) ->
    db = couch.getDb 'record'
    opts = 
      id: req.resourceId
      error: (err) ->
        next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (doc) ->
        if not doc._attachments? or not doc._attachments[req.fileName]?
          next new errors.NotFoundError 'Requested file: ' + req.fileName + ' was not found' 
        else
          console.log 'RETRIEVE FILE: ' + req.fileName + ' FROM RECORD: ' + req.resourceId        
          serverLoc = couch.fileUrl req.resourceId, req.fileName
          request.get(serverLoc).pipe res
    da.getDoc db, opts
  
  
  # Delete a specific file associated with a specific record  
  deleteFile: (req, res, next) ->
    db = couch.getDb 'record'
    opts = # The first request checks to make sure the requested record and file exist
      id: req.resourceId
      error: (err) ->
        next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (doc) ->
        if not doc._attachments? or not doc._attachments[req.fileName]?
          next new errors.NotFoundError 'Requested file: ' + req.fileName + ' was not found' 
        else
          opts = # The second request deletes the file
            id: req.resourceId
            rev: doc._rev
            fileName: req.fileName
            error: (err) ->
              next new errors.DatabaseWriteError 'Error writing document to the database'
            success: (result) ->
              opts = # The third request gets the record as it is now, without the file attached           
                id: req.resourceId
                error: (err) ->
                  if err['status-code']? and err['status-code'] is 404
                    next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' 
                  else
                    next new errors.DatabaseReadError 'Error reading document from database'
                success: (doc) ->
                  doc.Links = ( link for link in doc.Links when link.URL isnt "/metadata/record/#{ req.resourceId }/file/#{ req.fileName }" )
                  opts = # The fourth request updates the record, removing any Link elements
                    id: req.resourceId
                    data: _.extend(doc, { _rev: result.rev, ModifiedDate: utils.getCurrentDate() })
                    clean_docs: true
                    error: (err) ->
                      next new errors.DatabaseWriteError 'Error writing document to the database'
                    success: (result) ->
                      console.log 'DELETE FILE: ' + req.fileName + ' FROM RECORD: ' + req.resourceId
                      res.send()
                  da.createDoc db, opts  
              da.getDoc db, opts                           
          da.deleteFile db, opts
    da.getDoc db, opts
    