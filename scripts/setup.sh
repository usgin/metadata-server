#!/bin/bash
if [ ! -e couchdb-lucene/target/couchdb-lucene-0.8.0-dist.zip ]; then
	cd couchdb-lucene
	mvn
	cd target
	unzip couchdb-lucene-0.8.0-dist.zip
	cd ../..
fi
cake build
node build/setup.js