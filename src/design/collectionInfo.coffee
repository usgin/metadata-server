module.exports =
  _id: '_design/collectionInfo'
  language: 'javascript'
  views:
    allNames: require './views/collectionInfo-allNames'
    children: require './views/collectionInfo-children'
