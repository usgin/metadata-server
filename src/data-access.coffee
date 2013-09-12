_ = require 'underscore'
schemas = require './schemas'
request = require 'request'
orgConfig = require './organization-config'

# Simple function to clean up a document coming out of CouchDB
cleanDoc = (doc) ->
  cleaned = _.extend {}, doc
  cleaned.id = doc._id if doc._id?
  delete cleaned._id
  delete cleaned._rev
  delete cleaned._attachments
  return cleaned

cleanKeywords = (doc) ->
  doc.Keywords ?= []
  _.each doc.Keywords, (keyword) ->
    if keyword.split(',').length > 1
        doc.Keywords = _.union doc.Keywords, keyword.split ','
    else if keyword.split(';').length > 1
        doc.Keywords = _.union doc.Keywords, keyword.split ';'
        
  doc.Keywords = _.map doc.Keywords, (keyword) ->
    return keyword.toLowerCase().trim()

  doc.Keywords = _.reject doc.Keywords, (keyword) ->
    return keyword is '' or keyword.indexOf(',') isnt -1 or keyword.indexOf(';') isnt -1
  return doc

module.exports = da =
  # Create a new document in the given database
  createDoc: (db, options) ->
    options.data ?= {}
    options.success ?= ->
    options.error ?= ->
    
    options.data = cleanKeywords options.data
    
    results = (err, response) ->
      if err?
        options.error err
      else
        options.success response
    if options.id?
      db.insert options.data, options.id, results
    else
      db.insert options.data, results
  
  # Create multiple documents in the given database
  createDocs: (db, options) ->
    options.docs ?= []
    options.success ?= ->
    options.error ?= ->
    
    options.docs = _.map options.docs, cleanKeywords
    
    db.bulk { "docs": options.docs }, (err, response) ->
      if err?
        options.error err
      else
        options.success response
    
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
          options.success (cleanDoc row.doc for row in response.rows when (row.id? and not row.id.match(/^_/)?) and (row.doc?))
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
        response = (cleanDoc row.value for row in response.rows) if options.clean_docs                              
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
  
  # Get collection names
  getCollectionNames: (options) ->
    options.id ?= ''
    options.success ?= ->
    options.error ?= ->
    if not options.recordsDb? or not options.collectionsDb?
      options.error()
    else  
      opts =
        id: options.id
        clean_docs: true
        error: (err) ->
          options.error err
        success: (doc) ->
          opts =
            keys: doc.Collections
            include_docs: true
            clean_docs: true
            error: (err) ->
              options.error err
            success: (collections) ->
              names = (col.Title for col in collections when col.Title?)
              options.success names
          da.listDocs options.collectionsDb, opts
      da.getDoc options.recordsDb, opts
      
  # Validate data
  validateRecord: (data, resourceType) ->
    if resourceType is 'record'
      schema = schemas.byName('metadata')
      _.extend(data, { MetadataContact: orgConfig.defaultMetadataContact } ) if not data.MetadataContact?
    if resourceType is 'collection'
      schema = schemas.byName('collection') 
    return schemas.validate data, schema
    
  # Perform a search
  search: (searchUrl, options) ->
    options.index ?= 'full'
    options.search_terms ?= ''
    options.include_docs ?= true
    options.sort ?= true
    options.limit ?= 999999
    options.published_only ?= false
    options.error ?= ->
    options.success ?= ->
    
    params = "?include_docs=#{ options.include_docs }&limit=#{ options.limit }"    
    params += "&skip=#{ options.skip }" if options.skip?
    params += "&sort=title" if options.sort
    params += "&q=#{ options.search_terms }"
    params += "%20AND%20published:true" if options.published_only
    
    url = "#{ searchUrl }#{ options.index }#{ params }"
    opts =
      uri: url
    request opts, (err, response, body) ->
      if err?
        options.error err
      else
        options.success body
      
      
      
      
             