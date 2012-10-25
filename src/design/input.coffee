module.exports =
  _id: '_design/input'
  language: 'javascript'
  views: 
    'iso.xml': require './views/input-iso'
    'atom.xml': require './views/input-atom'
    'fgdc.xml': require './views/input-fgdc'
    'csv': require './views/input-csv'
