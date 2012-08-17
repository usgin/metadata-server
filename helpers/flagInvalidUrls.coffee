#############################################
# The purpose of this Node.js script is to 
#  flag docs that have invalid links
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
ftp = require 'ftp-get'
http = require 'request'
_ = require 'underscore'
Backbone = require 'backbone'

db = couch.getDb 'record'

class Link extends Backbone.Model
  initialize: (options) ->
    doc = options.Doc ? {}
    @set 'Doc', doc
    
  validateUrl: ->
    link = @
    doc = @get 'Doc'
    url = @get 'URL'
    if url.match /^ftp:\/\//
      ftp.head url, (error, size) ->
        valid = if error then false else true        
        doc.trigger 'linkValidated', valid, url, true
    else if url.match /^https?:\/\//
      http.head url, (error, response) ->
        valid = if error or response.statusCode >= 400 then false else true
        doc.trigger 'linkValidated', valid, url
    else            
      doc.trigger 'linkValidated', false, url
      
class Doc extends Backbone.Model
  idAttribute: "_id"
  
  initialize: (options) ->
    links = options.Links ? []
    @set 'Links', (new Link _.extend(link, { Doc: @ }) for link in links)
    @set 'LinkCount', @get('Links').length
    @badUrls = []
    @on 'linkValidated', @linkValidated      
      
  validateDoc: ->
    @set 'Count', 1
    @set 'Valid', true
    link.validateUrl() for link in @get 'Links'
  
  linkValidated: (valid, badUrl = null, isFtp = false) ->
    @set('Valid', false) if not valid
    @badUrls.push(badUrl) if not valid        
    count = @get 'Count'
        
    if count is @get 'LinkCount'
      @updateDoc(@get('Valid'))       
    
    count = count + 1
    @set 'Count', count
    
  updateDoc: (valid) ->    
    badUrls = @badUrls
    getOpts = 
      id: @id
      success: (theDoc) ->
        if valid
          delete theDoc.InvalidUrls if theDoc.InvalidUrls?
          data = theDoc
        else
          data = _.extend theDoc, { InvalidUrls: badUrls }
        
        updateOpts =
          id: theDoc._id
          data: data
          success: (updateResponse) ->
            console.log "Invalidated doc #{updateOpts.id}" if not valid
          error: (err) ->
            console.log "Error updating doc #{updateOpts.id}"
        access.createDoc db, updateOpts
      error: (err) ->
        console.log "Error retreiving doc #{getOpts.id}"
    access.getDoc db, getOpts
    
allDocOpts = 
  include_docs: true
  success: (results) ->
    docs = (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
    Docs = (new Doc doc for doc in docs)
    doc.validateDoc() for doc in Docs
  error: (err) ->
    console.log 'Error retrieving docs'
access.listDocs db, allDocOpts
