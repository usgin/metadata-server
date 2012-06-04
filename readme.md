# Installation
## Prerequisites:
1. Node.js and NPM
2. CouchDB
3. Expat and Node dev libraries

## Do this:
*Get the code*

	git clone git://github.com/rclark/metadata-server.git

*Adjust the application configuration by editing these files:*

	src/couch-config.coffee
	src/organization-config.coffee
		
*Use NPM to install*
	
	cd metadata-server
	npm install
	
*Run the application*
	
	npm start

*Stop the application*
	
	npm stop
		
# API Documentation 
## Variables
- resourceType: one of either *collection* or *record*
- format: one of *iso.xml, atom.xml* or *geojson*
- resourceId: the identifier for a resource
- fileName: the name of a file attached to a metadata record

## GET /{resourceType}/
Lists all the available metadata collections or records in JSON format.

### Possible Responses:
- 200: A successful response will include an array of the records.
- 500: There was an error reading from the database. 

## GET /record.{format}
Lists all the available metadata records in the format specified.

### Possible Responses:
- 200: A successful response will depend on the requested format.
	- *iso.xml*: The response will be an HTML page containing links to each individual record an XML document that conforms to the USGIN profile for ISO 19139.
	- *atom.xml*: The response will be an XML document that conforms to the Atom standard.
	- *geojson*: The response will be a JSON document containing a *FeatureCollection* which includes all the metadata records in GeoJSON format.
- 500: There was an error reading from the database.

## POST /{resourceType}/
Creates a new metadata collection or record from POST data.

### Input Requirements:
The POST data should be a JSON object representing a metadata collection or record. The structure of both data types are described in [schemas.coffee](https://github.com/rclark/metadata-server/blob/master/src/coffee/schemas.coffee), and can be adjusted.
### Possible Responses:
- 201: The request was successful. The *Location* header contains the URL that can be used to access the new resource.
- 400: POST data did not pass validation. POST data must abide by the requirements outlined in [schemas.coffee](https://github.com/rclark/metadata-server/blob/master/src/coffee/schemas.coffee) for each resource type.
- 500: There was an error writing to the database.

## POST /harvest/
Creates a new metadata record by harvesting an existing record from a location specified in POST data

### Input Requirements:
The POST data should be a JSON object similar to the following:

	{
		"recordUrl": "http://somewhere.com/path/to/metadata/record.xml",
		"inputFormat": "iso.xml",
		"destinationCollection": "identifier-for-some-collection" // <-- optional parameter
	}

... where inputFormat is one of *iso.xml* or *atom.xml*
### Possible Responses:
- 201: The request was successful. The *Location* header contains the URL that can be used to access the new resource.
- 400: Either POST data did not contain the requisite data, the URL given was invalid, or the content at the given URL did not conform to the specified inputFormat
- 500: There was an error reading and/or writing to the database

## GET /{resourceType}/{resourceId}/
Retreives a single metadata record or collection, specified by its resourceId, in JSON format

### Possible Responses:
- 200: A successful response will contain the metadata record or collection in JSON format.
- 404: The requested resourceId does not exist in the database.
- 500: There was an error reading from the database.

## GET /record/{resourceId}.{format}
Retrieves a single metadata record, specified by its resourceId, in the specified format

### Possible Responses:
- 200: A successful response wil depend on the requested format.
	- *iso.xml*: The response will be an XML document that conforms to the USGIN profile for ISO 19139.
	- *atom.xml*: The response will be an XML document that represents an Atom feed containing a single entry.
	- *geojson*: The response will be a JSON document containing a single GeoJSON *Feature*
- 500: There was an error reading and/or formatting the document.

## GET /collection/{resourceId}/records/
Retrieves all the metadata records that belong to a collection specified by its resourceId in JSON format.

### Possible Responses:
- 200: A successfule response will include an array of metadata records.
- 404: A metadata collection with the requested resourceId could not be found.
- 500: There was an error reading from the database.

## GET /collection/{resourceId}/records.{format}
Retrieves all the metadata records that belong to a collection specified by its resourceId in the specified format.

### Possible Responses:
- 200: A successful response will depend on the requested format.
	- *iso.xml*: The response will be an HTML page containing links to each individual metadata record in the specified collection as an XML document that conforms to the USGIN profile for ISO 19139.
	- *atom.xml*: The response will be an XML document that conforms to the Atom standard and containing an entry for each metadata record in the specified collection.
	- *geojson*: The response will be a JSON document containing a *FeatureCollection* which includes all the metadata records in the specified collection as GeoJSON *Features*.
- 404: A metadata collection with the requested resourceId could not be found.
- 500: There was an error reading and/or formatting the response.

## PUT /{resourceType}/{resourceId}/
Updates an existing metadata record or collection using PUT data.

### Input Requirements:
The PUT data should be a JSON object representing a metadata collection or record. The structure of both data types are described in [schemas.coffee](https://github.com/rclark/metadata-server/blob/master/src/coffee/schemas.coffee), and can be adjusted. 
### Possible Responses:
- 204: The request was successful. The *Location* header contains the URL that can be used to access the updated resource.
- 400: PUT data did not pass validation. PUT data must abide by the requirements outlined in [schemas.coffee](https://github.com/rclark/metadata-server/blob/master/src/coffee/schemas.coffee) for each resource type.
- 404: The requested resourceId does not exist in the database.
- 500: There was an error reading and/or writing to the database.

## DELETE /{resourceType}/{resourceId}/
Deletes an existing metadata record or collection specified by its resourceId.

### Possible Responses:
- 201: The request was successful.
- 404: The requested resourceId does not exist in the database.
- 500: There was an error reading and/or writing to the database.

## GET /record/{resourceId}/file/
Lists all the file names and URLs that are attached to the metadata record specified by its resourceId.

### Possible Responses:
- 200: A successful response will contain an array of JSON objects. Each object will identify the a file's name, and a URL at which the file can be accessed.
- 404: The requested resourceId does not exist in the database.
- 500: There was an error reading from the database.

## POST /record/{resourceId}/file/
Attach an uploaded file to an existing metadata record specified by its resourceId.

### Input Requirements
Currently a little confused about the details of generating a proper POST. However, the following HTML form will upload files properly:
	
	<form enctype="multipart/form-data" action="/record/47f4b4ebb226f7db16ba19b6d8001a5e/file/" method="POST">
		<input type="file" name="upload-file">
		<input type="submit" value="Submit">
	</form>
	
### Possible Responses:
- 202: The request was accepted. The *Location* header contains the URL that can be used to access the file directly.
- 404: The requested resourceId does not exist in the database.
- 500: There was an error writing to the database.

## GET /record/{resourceId}/file/{fileName}
Retrieve a file specified by its fileName from a metadata record specified by its resourceId.

### Possible Responses:
- 200: A successful request will allow direct access to the file specified.
- 404: Either the resourceId or fileName requested does not exist in the database.
- 500: There was an error reading from the database.

## DELETE /record/{resourceId}/file/{fileName}
Deletes a file specified by its fileName from a metadata record specified by its resourceId.

### Possible Responses:
- 204: The request was successful.
- 404: Either the resourceId or fileName requested does not exist in the database.
- 500: There was an error writing to the database. 
