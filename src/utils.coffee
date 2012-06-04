org = require './organization-config'
xml2json = require 'xml2json'

module.exports = utils =
  atomWrapper: (entries) ->
    wrapper =
      feed:
        xmlns: "http://www.w3.org/2005/Atom"
        'xmlns:georss': "http://www.georss.org/georss"
        'scast': "http://sciflo.jpl.nasa.gov/serviceCasting/2009v1"
        id:
          $t: "#{ org.orgUrl }/resources/atom"
        title:
          $t: "#{ org.orgName } Atom Feed"
        updated:
          $t: utils.getCurrentDate()
        author:
          name:
            $t: org.orgName
          email:
            $t: org.orgEmail
        entries: entries
        
  featureCollection: (entries) ->
    wrapper =
      type: "FeatureCollection"
      features: entries
      
  getCurrentDate: -> 
    ISODateString = (d) ->
      pad = (n) ->
        return '0'+n if n<10
        return n
      return "#{ d.getUTCFullYear() }-#{ pad d.getUTCMonth() + 1}-#{ pad d.getUTCDate() }T#{ pad d.getUTCHours() }:#{ pad d.getUTCMinutes() }:#{ pad d.getUTCSeconds() }Z"    
    now = new Date()
    return ISODateString now
    
  validateHarvestFormat: (format, data) ->
    try
      json = xml2json.toJson data, { object: true, reversible: true }
    catch error
      return false
    switch format
      when 'atom.xml'
        return true if json.feed?
        return false
      when 'iso.xml'
        return true if json['gmd:MD_Metadata']?
        return false
