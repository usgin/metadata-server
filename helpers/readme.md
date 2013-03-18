Command Line Functions
======================
CURRENT_DIR = directory `metadata-server/build/helpers`

!!! Remember to update Django database 

## deleteCollection
Delete the specified collections and their children records
	```
	node {CURRENT_DIR}/deleteCollection.js {COLLECTION_ID_1} {COLLECTION_ID_2} ...
	```  
	
e.g. Delete collections with id "0a8092505cc3e1797fa54585e6001a8" and "757831162f50186d4ec0f75c63c57a8f" and their children records  
	```
	node {CURRENT_DIR}/deleteCollection.js "0a8092505cc3e1797fa54585e6001a8" "757831162f50186d4ec0f75c63c57a8f"
	```
## publishCollection
Publish all the records under the specified collection
	```
	node {CURRENT_DIR}/publishCollection.js {COLLECTION_ID_1} {COLLECTION_ID_2} ...
	``` 
	
## deleteUnpublishedRecords
Delete all unpublished records
	```
	node {CURRENT_DIR}/deleteUublishedCollection.js
	``` 