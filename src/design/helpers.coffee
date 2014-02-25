module.exports =
  _id: '_design/helpers'
  language: 'javascript'
  views:
    'publishedOrNot': require './views/publishedOrNot'
