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
      #console.log "Entire row data= " + data
      return data
      
    .on 'record', (data, index) -> 
      #console.log "Record " + index
      if index is 0 # The row for field names
        for rf in requiredFields
          if (data.indexOf rf) is -1
            next new errors.ValidationError 'This is not a valid CSV metatdata.'
        for d in data
          #console.log "Field title= " + d
          fields.push d
      else # Other rows
        if data.length is fields.length # Identify if this is a valid record
           record = {}
           for da, i in data # Iterate fields for this record
             # Jessica Alisdairi commented out the code below, written by Genhan Chen,
             # because the harvest csv functionality from a remote source was not working.
             # With this line commented out the blank fields are not skipped and the harvest works again.
             #if (da? and (da != '')) then record[fields[i]] = da
             record[fields[i]] = da
             #console.log "Field " + i + " data= " + da                  
           entries.push record
        else
          console.log ('Record ' + index + ' is not correct!')
    
    .on 'end', (count) -> 
      #console.log entries
      req.entries = entries
      next()
