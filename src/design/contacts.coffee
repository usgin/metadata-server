module.exports =
  _id: '_design/contacts'
  language: 'javascript'
  views:
    byName: require './views/contacts-byName'
    allNames: require './views/contacts-allNames'
