module.exports =
  _id: '_design/search'
  language: 'javascript'
  views: {},
  fulltext:
    full: require './views/search-full'
    