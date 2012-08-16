module.exports =
  _id: '_design/output'
  language: 'javascript'
  views:
    invalidUrls: require './views/invalidUrls'