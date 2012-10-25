errors = require './errors'
csv = require 'csv'

module.exports = csv2json = 
  
  # Read CSV files
  readCSV: (body, req, res, next) ->
    requiredFields = [
      'title', 'description', 'publication_date', 'north_bounding_latitude'
      'south_bounding_latitude', 'east_bounding_longitude', 'west_bounding_longitude'
      'metadata_contact_org_name', 'metadata_contact_email', 'originator_contact_org_name'
      'originator_contact_person_name', 'originator_contact_position_name', 'originator_contact_email'
      'originator_contact_phone', 'metadata_uuid', 'metadata_date'
    ]
    fields = []
    entries = []   
    
    csv().from(body)
    .transform (data) ->    
      return data
      
    .on 'record', (data, index) -> 
      if index is 0 # The row for field names
        for rf in requiredFields
          if (data.indexOf rf) is -1
            next new errors.ValidationError 'This is not a valid CSV metatdata.'
        for d in data
          fields.push d
      else # Other rows
        if data.length is fields.length # Identify if this is a valid record
           record = {}
           for da, i in data # Iterate fields for this record
             record[fields[i]] = da            
           entries.push record                
        else
          console.log ('Record' + index + 'is not correct!')
    
    .on 'end', (count) -> 
      req.entries = entries
      next()
