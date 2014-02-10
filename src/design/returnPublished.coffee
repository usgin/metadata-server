module.exports =
  _id: '_design/returnPublished'
  language: 'javascript'
  views:
    'filtered-iso.xml': require './views/output-filtered-iso'
