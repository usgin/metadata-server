getNodes = require('./repositoryArray').getNodes
fs = require 'fs'
path = require 'path'
Backbone = require 'backbone'

class Logger extends Backbone.Model
  initialize: (options) ->
    @set stdLogPath: path.join __dirname, 'htaccessRedirects.txt'
    @set errLogPath: path.join __dirname, 'redirectErrors.log'
    
    @stdLog = fs.createWriteStream @get 'stdLogPath'
    @errLog = fs.createWriteStream @get 'errLogPath'
    
  logMessage: (message) ->
    @stdLog.write "#{message}\n"
  
  errMessage: (message) ->
    @errLog.write "#{message}\n"
    
logger = new Logger()

getNodes (nodesInUse, nodeLookup) ->
  for node in nodesInUse
    dlioUrl = "uri_gin/usgin/dlio/#{node}"
    metadataUrl = "http://repository.stategeothermaldata.org/repository/resource/#{nodeLookup[node].metadataId}/"
    logger.logMessage "RewriteRule #{dlioUrl} #{metadataUrl} [R=301,L]"
     
    
