csv = require 'csv'

module.exports = csv2json = 
  
  # Read CSV files
  readCSV: (body, req, res, next) ->
    fields = []
    entries = []   
    
    csv().from(body)
    .transform (data) ->    
      return data
      
    .on 'record', (data, index) -> 
      if index is 0 # The row for field names
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
