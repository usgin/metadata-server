module.exports =
  _id: '_design/manage'
  language: 'javascript'
  views:
    invalidUrls: require './views/invalidUrls'
    fromDrupalRepository: require './views/fromDrupalRepository'
    fromMetaWiz: require './views/fromMetaWiz'
