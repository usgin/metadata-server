access = require '../data-access'
couch = require '../couch-config'

allowedViews = 
  'collectionInfo-allNames': 'collection'
  'collectionInfo-children': 'collection'
  'collections-ids': 'record'
  'input-atom': 'harvest'
  'input-iso': 'harvest'
  'output-atom': 'record'
  'output-geojson': 'record'
  'output-iso': 'record'


example = "for example: node --debug-brk debug-views input-iso ba2f0b9d21f71acfe10609f76e17d55a"

viewName = process.argv[2]
docId = process.argv[3]
  
if not docId? or not viewName?
  console.log "You must specify a view and a document ID to test it against"
  console.log example
  return
    
if viewName not in (key for key, value of allowedViews)
  console.log "#{viewName} is not the name of a valid view"
  return

viewPrefix = '../design/views/'
viewFn = require("#{viewPrefix}#{viewName}").map

db = couch.getDb allowedViews[viewName]
opts =
  id: docId
  error: (err) ->
    console.log "ERROR: Could not retrieve document #{docId}"
    return
  success: (doc) ->
    ###
    ----------------------------------------------------------
    Put a breakpoint here and step into the next function call
    ----------------------------------------------------------
    ###    
    
    result = viewFn doc, true
    return
    
access.getDoc db, opts



