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
        entries: 
          entry: entries
        
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
        
  addCollectionKeywords: (iso, collectionNames) ->        
    outputKeywords = iso["gmd:MD_Metadata"]["gmd:identificationInfo"]["gmd:MD_DataIdentification"]["gmd:descriptiveKeywords"]
    collectionNames = ({"gco:CharacterString": { "$t": name } } for name in collectionNames)
    if collectionNames.length > 0
      newKeywordBlock =
        "gmd:MD_Keywords":
          "gmd:keyword": collectionNames
          "gmd:thesaurusName":
            "xlink:href": "/metadata/collection/"
            "gmd:CI_Citation":
              "gmd:title":
                "gco:CharacterString":
                  "$t": "Server Collections"
              "gmd:date":
                "gmd:CI_Date":
                  "gmd:date":
                    "gco:Date":
                      "$t": "2012-06-06"
                  "gmd:dateType":
                    "gmd:CI_DateTypeCode":
                      "codeList": "http://standards.iso.org/ittf/PubliclyAvailableStandards/ISO_19139_Schemas/resources/Codelist/gmxCodelists.xml#CI_DateTypeCode"
                      "codeListValue": "publication"
      outputKeywords.push newKeywordBlock
    return iso
