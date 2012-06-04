module.exports =
  _id: '_design/output'
  language: 'javascript'
  views:
    'iso.xml': require './views/output-iso'
    'atom.xml': require './views/output-atom'
    geojson: require './views/output-geojson'
