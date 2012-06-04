express = require 'express'
errors = require './errors'
routes = require './routes'

# Setup the server
server = express.createServer()
server.use express.bodyParser()
server.use express.errorHandler { showStack: true, dumpExceptions: true }
server.set 'view engine', 'jade'
server.set 'view options', { layout: false }

notReadyYet = (req, res, next) ->
  next new errors.NotImplementedError req.routeId + ' Functionality not yet implemented'  

# setParams sets request parameters so they are easy to access by other middleware
setParams = (req, res, next) ->
  switch req.routeId
    when 'search'
      req.searchTerms = req.body.searchTerms
      req.limit = req.body.limit if req.body.limit
      req.skip = req.body.skip if req.body.skip
      req.publishedOnly = req.body.publishedOnly or false
    when 'listResources', 'newResource'
      req.resourceType = req.params[0]
    when 'viewRecords'
      req.format = req.params[0]
    when 'harvestRecord'
      req.url = req.body.recordUrl
      req.format = req.body.inputFormat
      req.collections = req.body.destinationCollections if req.body.destinationCollections?
    when 'getResource', 'updateResource', 'deleteResource'
      req.resourceType = req.params[0]
      req.resourceId = req.params[1]
    when 'viewRecord', 'viewCollectionRecords'
      req.resourceId = req.params[0]
      req.format = req.params[1]
    when 'listFiles', 'newFile', 'getCollectionRecords'
      req.resourceId = req.params[0]
    when 'getFile', 'deleteFile'
      req.resourceId = req.params[0]
      req.fileName = req.params[1]  
  next()
      
### ROUTE DEFINITIONS ###
# The pattern is 
#  1) a function to set a routeId 
#  2) a function to set request parameters 
#  3) a chain of middleware functions that actually do something

# Text-based search for records
server.post /^\/search\/$/, ((req, res, next) -> 
  req.routeId = 'search'
  next()), setParams,
  routes.search

# List records or collections (as JSON)     
server.get /^\/(record|collection)\/$/, ((req, res, next) -> 
  req.routeId = 'listResources'
  next()), setParams,
  routes.listResources
  
# List records in a specific format  
server.get /^\/record\.(iso\.xml|atom\.xml|geojson)$/, ((req, res, next) -> 
  req.routeId = 'viewRecords'
  next()), setParams,
  routes.viewRecords

# Create a new record or collection  
server.post /^\/(record|collection)\/$/, ((req, res, next) -> 
  req.routeId = 'newResource'
  next()), setParams,
  routes.newResource
  
# Harvest an existing record
server.post /^\/harvest\/$/, ((req, res, next) -> 
  req.routeId = 'harvestRecord'
  next()), setParams,
  routes.harvestRecord
  
# Retrieve a specific record or collection (as JSON)
server.get /^\/(record|collection)\/([^\/]*)\/$/, ((req, res, next) -> 
  req.routeId = 'getResource'
  next()), setParams,
  routes.getResource
  
# Retrieve a specific record in a specific format  
server.get /^\/record\/([^\/]*)\.(iso.xml|atom\.xml|geojson)$/, ((req, res, next) -> 
  req.routeId = 'viewRecord'
  next()), setParams,
  routes.viewRecord

# Retrieve all the records in a specific collection (as JSON)
server.get /^\/collection\/([^\/]*)\/records\//, ((req, res, next) -> 
  req.routeId = 'getCollectionRecords'
  next()), setParams,
  routes.getCollectionRecords

# Retrieve all the records in a specific collection in a specific format
server.get /^\/collection\/([^\/]*)\/records\.(iso.xml|atom\.xml|geojson)$/, ((req, res, next) -> 
  req.routeId = 'viewCollectionRecords'
  next()), setParams,
  routes.viewCollectionRecords
  
# Update an existing record or collection  
server.put /^\/(record|collection)\/([^\/]*)\/$/, ((req, res, next) -> 
  req.routeId = 'updateResource'
  next()), setParams,
  routes.updateResource
  
# Delete a record or collection  
server.del /^\/(record|collection)\/([^\/]*)\/$/, ((req, res, next) -> 
  req.routeId = 'deleteResource'
  next()), setParams,
  routes.deleteResource
  
# List files associated with a specific record  
server.get /^\/record\/([^\/]*)\/file\/$/, ((req, res, next) -> 
  req.routeId = 'listFiles'
  next()), setParams,
  routes.listFiles
  
# Associate a new file with a specific record  
server.post /^\/record\/([^\/]*)\/file\/$/, ((req, res, next) -> 
  req.routeId = 'newFile'
  next()), setParams,
  routes.newFile
  
# Retrieve a specific file associated with a specific record
server.get /^\/record\/([^\/]*)\/file\/(.*)$/, ((req, res, next) -> 
  req.routeId = 'getFile'
  next()), setParams,
  routes.getFile
  
# Delete a specific file associated with a specific record  
server.del /^\/record\/([^\/]*)\/file\/(.*)$/, ((req, res, next) -> 
  req.routeId = 'deleteFile'
  next()), setParams,
  routes.deleteFile
  
### END OF ROUTE DEFINITIONS ###
  
# Handle errors
server.error (err, req, res, next) ->
  res.send err.msg, err.status
  next err

# Start listening    
server.listen 3000
