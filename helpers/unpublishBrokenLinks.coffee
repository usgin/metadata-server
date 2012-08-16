#############################################
# The purpose of this Node.js script is to 
#  add remove non-ASCII characters
#############################################

nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'
backbone = require 'backbone'
ftp = require 'ftp-get'
http = require 'request'
futures = require 'futures'

db = couch.getDb 'record'

docSeq = futures.sequence()

docSeq.then (next) ->
  allDocOpts = 
    include_docs: true
    success: (results) ->
      next (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
    error: (err) ->
      console.log 'Error retrieving docs'
    return
  access.listDocs db, allDocOpts

docSeq.then (next, docs) ->
  
  

allDocOpts = 
  include_docs: true
  success: (results) ->
    # Setup object that contains a list of all the docs I want to loop through
    docs = 
      docList: (result.doc for result in results.rows when not result.doc._id.match(/^_design/))
      currentIndex: 0      
      brokenLinks: []
      
    # Extend the object so that it can utilize events  
    _.extend docs, backbone.Events    
    docs.on 'next', (brokenLinks)->      
      if brokenLinks.length > 0
        currentDoc = docs.docList[docs.currentIndex]
        currentDoc.Published = false
        currentDoc.InvalidLinks = brokenLinks
        runUpdate currentDoc
        #console.log "Would update #{currentDoc._id}"
      docs.currentIndex++
      if docs.currentIndex + 1 is docs.docList.length
        console.log "We're done!"
      else
        checkLinks docs.docList[docs.currentIndex]
    
    # Function to check the links in a doc
    checkLinks = (doc) ->
      # Setup object that contains a list of all the links in this doc
      links = 
        linkList: (link for link in doc.Links when link?)
        currentIndex: 0
        broken: []
        
      # Extend the object so that it can utilize events
      _.extend links, backbone.Events
      links.on 'next', (update, url, error)->
        links.broken.push {url:error} if update
        links.currentIndex++
        if links.currentIndex + 1 is links.linkList.length
          docs.trigger 'next', links.broken
        else
          nextLink = links.linkList[links.currentIndex]
          if nextLink?
            checkOneLink nextLink, links
          else
            links.trigger 'next', false
      
      # Get started checking them
      checkOneLink links.linkList[links.currentIndex], links
      
    # Function to check one link
    checkOneLink = (link, links) ->
      url = link.URL
      if url.match /^ftp:\/\//
        ftp.head url, (error, size) ->
          if error
            console.log "FTP ERROR #{error}"
            links.trigger 'next', true, url, error
          else
            links.trigger 'next', false
      else if url.match /^https?:\/\//
        http.head url, (error, response) ->
          if error
            console.log "HTTP ERROR #{error}"
            links.trigger 'next', true, url, error
          else if response.statusCode >= 400
            console.log "Status code >= 400"
            links.trigger 'next', true, url, error
          else
            links.trigger 'next', false
      else
        console.log "Invalid Protocol"
        links.trigger 'next', true, url, "Invalid Protocol"
   
    # Actually update a record
    runUpdate = (updateDoc) ->
      updateOpts =
        id: updateDoc._id
        data: updateDoc
        success: (result) ->
          console.log "Updated #{result.id}"
          return
        error: (err) ->
          console.log "Error updating #{result.id}"
          return
      access.createDoc db, updateOpts
      
    # Try and actually do it.
    checkLinks docs.docList[docs.currentIndex]      
        
  error: ->
    console.log 'Error retrieving docs'
    return
access.listDocs db, allDocOpts