couch = require './couch-config'
utils = require './utils'
_ = require 'underscore'
errors = require './errors'
fs = require 'fs'
request = require 'request'
da = require './data-access'
xml2json = require 'xml2json'
  
### THESE ARE ALL THE ROUTE MIDDLEWARE FUNCTIONS ###
module.exports =


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
        success: (result) ->
          console.log 'NEW ' + req.resourceType + ' CREATED'
          res.send '', { Location: "/#{ req.resourceType }/#{ newRecord.id }/" }, 201
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
            opts = # The second request creates the record in the harvests database
              data: xml2json.toJson(body, { object: true, reversible: true })
              error: (err) ->
                next new errors.DatabaseWriteError 'Error writing to the database'
              success: (newHarvestDoc) ->                 
                opts = # The third request pulls the harvested record through the appropriate input view
                  design: 'input'
                  format: req.format
                  key: newHarvestDoc.id
                  clean_docs: true
                  error: (err) ->
                    next new errors.DatabaseReadError 'Error reading document from database'
                  success: (transformedDoc) ->
                    db = couch.getDb 'record'
                    harvestInfo =
                      OriginalFormat: req.format
                      HarvestURL: req.url
                      HarvestDate: utils.getCurrentDate()
                      HarvestRecordId: newHarvestDoc.id
                    transformedDoc = transformedDoc[0]
                    _.extend transformedDoc.HarvestInformation, harvestInfo 
                    _.extend transformedDoc, { Collections: req.collections } if req.collections?
                    opts = # The fourth request places the transformed doc into the record database
                      data: transformedDoc
                      error: (err) ->
                        next new errors.DatabaseWriteError 'Error writing to the database'
                      success: (newRecord) ->
                        console.log 'NEW ' + req.resourceType + ' HARVESTED'
                        res.send '', { Location: "/record/#{ newRecord.id }/" }, 201                        
                    da.createDoc db, opts
                da.viewDocs db, opts
            da.createDoc db, opts
            
            
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
        console.log 'VIEW RECORD ' + req.resourceId + ' AS ' + req.format
        result = result[0]
        if req.format.match(/\.xml$/)? # Handle the special case where JSON needs to be converted to XML
          if req.format.match(/atom\.xml/)? # Handle the special case of atom and the feed wrapper it needs
            result = utils.atomWrapper [result]
          result = xml2json.toXml result
          res.header('Content-Type', 'text/xml')
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
          opts = # The second viewDocs request finds the IDs for records that are a part of this collection
            design: 'collections'
            format: 'ids'
            key: req.resourceId
            error: (err) ->
              next new errors.DatabaseReadError 'Error running database view'
            success: (result) ->
              if not result.rows[0]?
                res.send []
              else
                ids = result.rows[0].value
                console.log 'GOT COLLECTION RECORDS: ' + ids
                opts = # The third fetchDocs request retrieves the collection's records
                  keys: ids
                  clean_docs: true
                  include_docs: true
                  error: (err) ->
                    next new errors.DatabaseReadError 'Error reading documents from the database'
                  success: (result) ->
                    console.log 'GOT COLLECTION RECORDS: ' + ids
                    res.send result
                da.listDocs db, opts
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
              console.log 'GOT COLLECTION RECORDS: ' + result.rows[0].value
              if req.format.match(/iso\.xml/)? # Handle the special case for iso.xml > web-accessible folder
                res.render 'waf.jade', { title: 'Placeholder Title', records: result.rows[0].value }
              else
                opts = # The third viewDocs request retrieves the collection's records through the right view
                  design: 'output'
                  format: req.format
                  keys: result.rows[0].value
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
              res.send '', { Location: "/#{ req.resourceType }/#{ newRecord.id }/" }, 204
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
        result = ( { filename: name, location: "/record/#{ req.resourceId}/file/#{ name }" } for name, info of doc._attachments ) if doc._attachments?
        res.send result
    da.getDoc db, opts
    

  # Associate a new file with a specific record
  newFile: (req, res, next) ->
    db = couch.getDb 'record'
    opts =
      id: req.resourceId
      error: (err) ->
        next new errors.NotFoundError 'Requested document: ' + req.resourceId + ' was not found' if err['status-code']? and err['status-code'] = 404
        next new errors.DatabaseReadError 'Error reading document from database'
      success: (rev) ->
        file = (file for key, file of req.files)[0]
        fileStream = fs.createReadStream file.path
        fileStream.pipe db.attachment.insert req.resourceId, file.name, null, file.type, { rev: rev }
        
        console.log 'NEW FILE: ' + file.name + ' ATTACHED TO: ' + req.resourceId
        res.send '', { Location: "/record/#{ req.resourceId }/file/#{ file.name }" }, 202
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
              console.log 'DELETE FILE: ' + req.fileName + ' FROM RECORD: ' + req.resourceId
              res.send()
          da.deleteFile db, opts
    da.getDoc db, opts
    