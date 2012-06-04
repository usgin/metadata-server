#!/bin/bash
lucene=`ps aux | grep [c]om.github.rnewson.couchdb.lucene.Main | awk '{print $2}'`
if [ -n $lucene ]; then
	kill $lucene
fi
app=`ps aux | grep [.]/build/server.js | awk '{print $2}'`
if [ -n $app ]; then
	kill $app
fi