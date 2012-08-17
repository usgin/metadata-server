module.exports =
  _id: '_design/manage'
  language: 'javascript'
  views:
    invalidUrls: require './views/invalidUrls'