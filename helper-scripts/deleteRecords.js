(function () {
  var nano = require('nano')('http://couchdb.stategeothermaldata.org:8001'),
      db = nano.use('records');
  db.view('helpers', 'publishedOrNot', {key: 'unpublished', include_docs: true}, function(err, response) {
    if (err) return console.log(err);
    response.rows.forEach(function (row) {
      var doc = row.doc,
          north = doc.GeographicExtent.NorthBound,
          east = doc.GeographicExtent.EastBounds;

      if (north === "Missing" || east === null) {
        var doc._deleted = true;
        db.insert(doc, function(err, response) {
          if (err) return console.log(err);
          else console.log('Successfully deleted document: ' + doc._id)
        })
      }
    })
  })
}).call(this);