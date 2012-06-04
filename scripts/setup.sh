#!/bin/bash

if [ ! "$(ls -A couchdb-lucene)" ]; then
	git submodule init
	git submodule update
	cd couchdb-lucene
	mvn
	cd target
	unzip couchdb-lucene-0.8.0-dist.zip
	cd ../..
fi
cake build
node build/setup.js