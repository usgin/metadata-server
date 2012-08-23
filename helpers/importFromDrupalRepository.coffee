nano = require 'nano'
access = require '../data-access'
couch = require '../couch-config'
_ = require 'underscore'
Backbone = require 'backbone'
getNodes = require('./repositoryArray').getNodes
request = require 'request'
fs = require 'fs'
path = require 'path'

config =
  importCollectionId: "c9c0ad665765064c99d1788a1411efe3"
  linkHost: 'repository.stategeothermaldata.org'
  sourceHost: 'repository.usgin.org'
  transferAllFiles: false
  
class Logger extends Backbone.Model
  initialize: (options) ->
    @set stdLogPath: path.join __dirname, 'importFromDrupal.log'
    @set errLogPath: path.join __dirname, 'importFromDrupalErrors.log'
    
    @stdLog = fs.createWriteStream @get 'stdLogPath'
    @errLog = fs.createWriteStream @get 'errLogPath'
    
  logMessage: (message) ->
    @stdLog.write "#{message}\n"
  
  errMessage: (message) ->
    @errLog.write "#{message}\n"
    
globalLogger = new Logger()
    
class FileQueue extends Backbone.Model
  initialize: (options) ->
    @queue = new Array()
    @on 'fileLoaded', @nextFile
    
  nextFile: ->
    self = @
    if @queue.length > 0      
      fileDef = @queue[0]
      newFile = new NewFile fileDef
      newFile.on 'transferComplete', ->
        self.removeFromQueue fileDef
        self.nextFile()
      newFile.transfer()
      
  addToQueue: (fileDef) ->
    @queue.push fileDef
    @nextFile() if @queue.length is 1
    
  removeFromQueue: (fileDef) ->
    @queue.splice 0, 1    
    globalLogger.logMessage "#{@queue.length} files left in the queue."
    
globalFileQueue = new FileQueue()

class NewFile extends Backbone.Model
  initialize: (options) ->
    @set couchUrl: options.dlio.get 'couchUrl'
    @set metadataId: options.dlio.get 'metadataId'    
    @dlio = options.dlio
    
  transfer: ->
    couchUrl = @get 'couchUrl'
    metadataId = @get 'metadataId'
    fileName = @get 'fileName'
    fileUrl = @get 'fileUrl'
    dlio = @dlio
    self = @
    
    request.head uri: couchUrl, (err, response) ->
      rev = response.headers['etag'].replace(/"/g, '')           
      newFileUrl = "#{couchUrl}/#{fileName}?rev=#{rev}"
      fileReq = request.get uri: fileUrl
      fileReq.pipe request.put uri: newFileUrl, (err, response, body) ->
        if err?
          globalLogger.errMessage "Error transferring file: #{fileName} || #{metadataId}"
          
        globalLogger.logMessage "Attach: #{fileName} || #{metadataId}"
        self.trigger 'transferComplete'
        dlio.trigger 'fileTransferred', fileName
        
class Dlio extends Backbone.Model
  initialize: (options) ->    
    if _.isString options.files
      @set files: [ options.files ]         
    
    @on 'harvested', @transferFiles
    @on 'fileTransferred', @addLink
    
  harvest: ->
    self = @
    postOpts =
      url: 'http://localhost:3000/metadata/harvest/'
      method: 'POST'
      json:
        recordUrl: @get 'metadata'
        inputFormat: 'iso.xml'
        destinationCollections: [ "#{config.importCollectionId}" ]
    request postOpts, (err, response, body) ->
      if err?
        globalLogger.errMessage "Error harvesting #{self.id}: #{err}"
        return
      if response.statusCode > 399
        globalLogger.errMessage "Error harvesting #{self.id}: #{body}"
        return
        
      self.set metadataUrl: body[0]      
      self.set metadataId: body[0].match(/\/metadata\/record\/(.*)\/$/)[1]
      self.set couchUrl: "http://localhost:5984/records/#{self.get 'metadataId'}"
      self.trigger 'harvested'
      globalLogger.logMessage "Harvested node: #{self.id} | Created record: #{self.get 'metadataId'}"
      
  transferFiles: ->
    files = @get 'files'
    
    for fileUrl in files
      globalFileQueue.addToQueue
        fileUrl: fileUrl
        fileName: fileUrl.split('/').pop()
        dlio: @
      
  addLink: (fileName) ->
    metadataId = @get 'metadataId'
    couchUrl = @get 'couchUrl'
    request.get uri: couchUrl, (err, response, body) ->
      if err?
        globalLogger.errMessage "Error getting #{metadataId} from CouchDB: #{err}"
        return
        
      data = JSON.parse(body)
      data.Links = new Array() if not data.Links?
      data.Links.push
        URL: "http://#{config.linkHost}/metadata/record/#{metadataId}/file/#{fileName}"
        Name: "Downloadable File"
      request.put { uri: couchUrl, json: data }, (err, response, body) ->
        if err?
          globalLogger.errMessage "Error updating links in #{metadataId}: #{err}"
          return
          
        globalLogger.logMessage "Updated Links: #{metadataId}"
        
        
getNodes (nodesInUse, nodeLookup) ->
  url = "http://#{config.sourceHost}/node-files"
  request uri: url, (err, response, body) ->
    if not err and response.statusCode is 200
      globalLogger.logMessage "#{_.uniq(nodesInUse, true).length} Drupal Records are already in this repository."
      dliosToHarvest = new Array()
      dliosToTransfer = new Array()
      for row in JSON.parse(body).drupals
        if parseInt(row.dlio.id) not in nodesInUse # Nodes not in the new repository need to be harvested
          #if dliosToHarvest.length < 10
          row.dlio.files = new Array() if not row.dlio.files?
          d = new Dlio(row.dlio)          
          d.harvest()
          dliosToHarvest.push d
        else # Nodes that are already in the repository need to have files transferred
          if config.transferAllFiles
            dlio = _.extend row.dlio, 
              metadataId: nodeLookup[row.dlio.id].metadataId
              metadataUrl: nodeLookup[row.dlio.id].metadataUrl
              couchUrl: "http://localhost:5984/records/#{nodeLookup[row.dlio.id].metadataId}"          
            dlio.files = new Array() if not dlio.files?                      
            #if dliosToTransfer.length < 10
            d = new Dlio(dlio) 
            d.transferFiles()
            dliosToTransfer.push d
      globalLogger.logMessage "Should harvest #{dliosToHarvest.length} out of #{JSON.parse(body).drupals.length} records from the Drupal Repository."
    else
      globalLogger.errMessage 'There was an error requesting information from Drupal.'
  
