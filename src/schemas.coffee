_ = require 'underscore'

schemas =
  link:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-link/'
    type: 'object'
    properties:
      URL:
        type: 'string'
        format: 'uri'
        required: true
      Name:
        type: 'string'
        required: false
      Description:
        type: 'string'
        required: false
      Distributor:
        type: 'string'
        required: false

  serviceLink:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-service-link/'
    type: 'object'
    properties: 
      ServiceType:
        type: 'string'
        required: true
        enum: ['OGC:WMS', 'OGC:WFS', 'OGC:WCS', 'OPeNDAP', 'ESRI']
      LayerId:
        type: 'string'
        required: false 
    'extends': 'http://resources.usgin.org/uri-gin/usgin/schema/json-link/'
  
  address:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-address/'
    type: 'object'
    properties:
      Street:
        type: 'string'
        required: true
      City:
        type: 'string'
        required: true
      State:
        type: 'string'
        required: true
      Zip:
        type: 'string'
        required: true
  
  contactInformation:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-contact-information/'
    type: 'object'
    properties:
      Phone:
        type: 'string'
        format: 'phone'
        required: false
      email:
        type: 'string'
        format: 'email'
        required: true
      Address:
        required: false
        $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-address/'
        
  contact:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata-contact/'
    type: 'object'
    properties:
      Name: 
        type: 'string'
        required: false
      OrganizationName:
        type: 'string'
        required: false
      ContactInformation:
        required: true
        $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-contact-information/'
        
  geographicExtent: 
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-geographic-extent/'
    type: 'object'
    properties:
      NorthBound:
        type: 'number'
        minimum: -90
        maximum: 90
        required: true
      SouthBound:
        type: 'number'
        minimum: -90
        maximum: 90
        required: true
      EastBound:
        type: 'number'
        minimum: -180
        maximum: 180
        required: true
      WestBound:
        type: 'number'
        minimum: -180
        maximum: 180
        required: true
  
  harvestInfo:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-harvest-information/'
    type: 'object'
    properties:
      OriginalFileIdentifier:
        type: 'string'
        required: false
      OriginalFormat:
        type: 'string'
        required: false
      HarvestRecordId:
        type: 'string'
        required: true
      HarvestURL:
        type: 'string'
        required: true
      HarvestDate:
        type: 'string'
        format: 'date-time'
        required: true     
         
  metadata:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata/'
    type: 'object'
    properties:
      Title:
        type: 'string'
        required: true
      Description:
        type: 'string'
        required: true
        minLength: 50
      PublicationDate:
        type: 'string'
        format: 'date-time'
        required: true
      ResourceId:
        type: 'string'
        required: false
      Authors:
        type: 'array'
        required: true
        minItems: 1
        items:
          $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata-contact/'    
      Keywords:
        type: 'array'
        required: true
        minItems: 1
        items:
          type: 'string' 
      GeographicExtent:
        required: true
        $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-geographic-extent/'
      Distributors:
        type: 'array'
        required: true
        minItems: 1
        items:
          $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata-contact/'
      Links:
        type: 'array'
        required: true
        minItems: 0
        items:
          $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-link/'
      MetadataContact:
        required: true
        $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata-contact/'
      HarvestInformation:
        required: false
        $ref: 'http://resources.usgin.org/uri-gin/usgin/schema/json-harvest-information/'
      Collections:
        type: 'array'
        required: true
        minItems: 0
        items:
          type: 'string'
      Published:
        type: 'boolean'
        required: true
        
  collection:
    id: 'http://resources.usgin.org/uri-gin/usgin/schema/json-metadata-collection/'
    type: 'object'
    properties:
      Title:
        type: 'string'
        required: true
      Description:
        type: 'string'
        required: false
      ParentCollections:
        type: 'array'
        required: false
        items:
          type: 'string'

schemaCopy = (schema) ->
  copy = {}
  for key, sch of schema
    if key is 'items'
      copy.items = _.clone sch 
    else if key is 'properties'
      copy.properties = {}
      for name, value of sch
        copy.properties[name] = schemaCopy value
    else
      copy[key] = _.clone sch      
  return copy
  
resolveRefs = (schema) ->
  schema = schemaCopy schema
  
  # Follow $refs
  if schema.$ref?
    resolved = _.extend {}, schema, schemaUtils.byId(schema.$ref) 
    delete resolved.$ref
  else
    resolved = _.extend {}, schema
    
  # Include any extensions
  _.extend resolved.properties, schemaUtils.byId(resolved['extends']).properties if resolved['extends']?
  delete resolved['extends']
  
  # Resolve any $refs in items
  if resolved.items? and resolved.items.$ref?
    resolved.items = resolveRefs schemaUtils.byId resolved.items.$ref
    
  # Resolve references in any properties
  for name, prop of resolved.properties
    resolved.properties[name] = resolveRefs(prop)
  
  resolved
          
module.exports = schemaUtils = 
  byId: (id) ->
    for name, schema of schemas
      return schema if schema.id? and schema.id == id
    null
    
  byName: (name) ->
    return schemas[name] if schemas[name]?
    null        
  
  all: -> 
    return ({ name: key, schema: value } for key, value of schemas)
      
  validate: (obj, schema) ->
    # First resolve schema refs
    schema = resolveRefs schema
    
    # Validate different schema types
    switch schema.type
      when 'string'
        return false if not _.isString(obj)
        return false if schema.minLength? and obj.length < schema.minLength
        return false if schema.maxLength? and obj.length > schema.maxLength
        return false if schema.enum? and obj not in schema.enum
      when 'number'
        return false if not _.isNumber(obj)
        return false if schema.minimum? and obj < schema.minimum
        return false if schema.maximum? and obj > schema.maximum
      when 'boolean' then return false if not _.isBoolean(obj)
      when 'array'
        return false if not _.isArray(obj)
        return false if schema.minItems and obj.length < schema.minItems
        return false if schema.maxItems and obj.length > schema.maxItems
        itemSchema = resolveRefs schema.items
        return false if false in (schemaUtils.validate item, itemSchema for item in obj)     
      when 'object'
        return false if not _.isObject(obj)
        for name, prop of schema.properties
          return false if prop.required and not obj[name]?          
          return false if obj[name]? and schemaUtils.validate(obj[name], prop) is false
    true
    
  resolve: resolveRefs
  
  emptyInstance: (schema) ->
    schema = resolveRefs schema
    switch schema.type
      when 'string' then return ''
      when 'number' then return 0
      when 'boolean' then return true
      when 'array' then return [ ]
      when 'object'
        result = {}
        for name, prop of schema.properties
          result[name] = schemaUtils.emptyInstance prop
        return result
 
