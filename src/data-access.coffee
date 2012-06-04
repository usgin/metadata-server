_ = require 'underscore'
schemas = require './schemas'

# Simple function to clean up a document coming out of CouchDB
cleanDoc = (doc) ->
  cleaned = _.extend {}, doc
  #cleaned.id = doc._id
  delete cleaned._id
  delete cleaned._rev
  delete cleaned._attachments
  return cleaned

module.exports = 
  # Create a new document in the given database
  createDoc: (db, options) ->
    options.data ?= {}
    options.success ?= ->
    options.error ?= ->
    results = (err, response) ->
      if err?
        options.error err
      else
        options.success response
    if options.id?
      db.insert options.data, options.id, results
    else
      db.insert options.data, results
  
  # Retrieve a document by its ID from the given database      
  getDoc: (db, options) ->
    options.clean_doc ?= false
    options.success ?= ->
    options.error ?= ->
    options.id ?= ''
    db.get options.id, (err, response) ->
      if err?
        options.error err
      else
        if options.clean_docs
          options.success cleanDoc response
        else
          options.success response
  
  # Check that a document exists in the given database
  exists: (db, options) ->
    options.id ?= ''
    options.success ?= ->
    options.error ?= ->
    db.head options.id, (err, body, headers) ->
      if err?
        if err['status-code']? and err['status-code'] is 404
          options.success false
        else
          options.error err
      else
        options.success true
      
  # Return the revision ID for a specific document from the given database
  getRev: (db, options) ->
    options.success ?= ->
    options.error ?= ->
    options.id ?= ''
    db.head options.id, (err, body, headers) ->
      if err?
        options.error err
      else
        options.success headers.etag.replace(/"/g, '')
  
  # List all documents in the given database  
  listDocs: (db, options) ->
    options.include_docs ?= false
    options.clean_docs ?= false
    options.success ?= ->
    options.error ?= ->
      
    params =
      include_docs: options.include_docs
    params.keys = options.keys if options.keys
    
    db.list params, (err, response) ->
      if err?
        options.error err
      else
        if options.clean_docs
          options.success (cleanDoc row.doc for row in response.rows when not row._id.match(/^_/)?)
        else
          options.success response        
   
  # Pass all or specific documents through a specified database view  
  viewDocs: (db, options) ->
    options.design ?= ''
    options.format ?= ''
    options.clean_docs ?= false
    options.success ?= ->
    options.error ?= ->
        
    params = {}
    params.key = options.key if options.key?
    params.keys = options.keys if options.keys?
    params.reduce = options.reduce if options.reduce?
    
    db.view options.design, options.format, params, (err, response) ->
      if err?
        options.error err
      else
        if options.clean_docs
          options.success (row.value for row in response.rows)
        else
          options.success response
  
  # Delete a document
  deleteDoc: (db, options) ->
    options.id ?= ''
    options.rev ?= ''
    options.success ?= ->
    options.error ?= ->
    db.destroy options.id, options.rev, (err, response) ->
      if err?
        options.error err
      else
        options.success response
  
  # Delete an attachment
  deleteFile: (db, options) ->
    options.id ?= ''
    options.rev ?= ''
    options.fileName ?= ''
    options.success ?= ->
    options.error ?= ->
    db.attachment.destroy options.id, options.fileName, options.rev, (err, response) ->
      if err?
        options.error err
      else
        options.success response
        
  # Validate data
  validateRecord: (data, resourceType) ->
    schema = schemas.byName('metadata') if resourceType is 'record'
    schema = schemas.byName('collection') if resourceType is 'collection'
    return schemas.validate data, schema
           