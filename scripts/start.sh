#!/bin/bash
if [ ! -d "logs" ]; then
	mkdir logs
fi
lucene=`ps aux | grep [c]om.github.rnewson.couchdb.lucene.Main | awk '{print $2}'`
if [ -z $lucene ]; then
	./couchdb-lucene-0.8.0/bin/run &> logs/lucene.log & 
fi
node ./build/server.js &> logs/server.log & 