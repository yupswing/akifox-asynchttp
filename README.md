[![akifox-asynchttp](https://img.shields.io/badge/library-akifox%20asynchttp%200.4.0-brightgreen.svg)]()
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Haxe 3](https://img.shields.io/badge/language-Haxe%203-orange.svg)](http://www.haxe.org)

[![Library](https://img.shields.io/badge/type-haxelib%20library-orange.svg)](http://lib.haxe.org/p/akifox-asynchttp)
[![Haxelib](https://img.shields.io/badge/distr-v0.3.2-yellow.svg)](http://lib.haxe.org/p/akifox-asynchttp)

# akifox-asynchttp (com.akifox.asynchttp.*)
**HAXE Asynchronous HTTP Request library**

The akifox-asynchttp library provides an easy-to-use tool to manage HTTP and HTTPS Requests in an pure Asynchronous way using multi-threading on available targets (Neko, CPP, Java), the flash.net.URLLoader on Flash target and haxe.Http on Javascript target.

### Inspiration

I've taken inspiration to write the library from this snippet by Raivof
https://gist.github.com/raivof/dcdb1d74f93d17132a1e

Thanks mate!

## Table of Contents

 * [Install and use with Haxe](#install-and-use-with-haxe)
  * [Use it in OpenFL Projects](#use-it-in-openfl-projects)
 * [Features](#features)
 * [What's new](#whats-new-040-breaking-api)
 * [Important notes](#important-notes)
 * [Quick reference](#quick-reference)
 * [Examples](#examples)
 * [Write to a file the response](#write-to-a-file-the-response)


## Install and use with Haxe

You can easily install the library thru haxelib

```
haxelib install akifox-asynchttp
```

import it in your project files
```
import com.akifox.asynchttp.*;
```

compile with
```-lib akifox-asynchttp```

and add the hxssl library (only needed on NEKO/CPP) to have SSL support
```-lib hxssl```

### Use it in OpenFL Projects
After installing the library via Haxelib, add the library reference in your ```project.xml```

```
<haxelib name="akifox-asynchttp" />
<haxelib name="hxssl" />
```

and finally you can import it in your project files
```
import com.akifox.asynchttp.*;
```

## Features
- Target support
  - [x] Neko+CPP+Java: Socket with multi-threading
  - [x] Flash: flash.net.URLLoader
  - [x] Javascript: XmlHttpRequest
  - [ ] Other platforms?
- HTTP Protocol Support
  - Request methods
    - [x] Support standard methods (GET, POST)
    - [x] Support restful methods (PUT, DELETE)
  - Transfer modes
    - [x] Support unknown transfer mode (HTTP/1.0+)
    - [x] Support fixed content-length transfer mode (HTTP/1.0+)
    - [x] Support chunked transfer mode (HTTP/1.1)
  - Redirects
    - [x] Support redirect (Status 301,302,303,307)
    - [x] Support relative urls **[v0.4+]**
    - [x] Block 'infinite loops' + 'too many redirects (max: 10)' **[v0.4+]**
  - [x] Choose if HTTP/1.0 or HTTP/1.1 **[v0.4+]**
  - [x] HTTP over SSL (HTTPS) support **[v0.4+]**
  - [x] Custom headers + custom user-agent **[v0.4+]**
  - [x] Timeout on request **[v0.3.1+]**
- Parsing
  - [x] Json to Anonymous Structure
  - [x] XML to Xml object
  - [x] Image (Png,Jpeg, Gif) to BitmapData object (only with OpenFL support)
- Additional features
  - [x] Synchronous request option **[v0.4+]**
- Future releases
  - [ ] Posting content on request (it should work but needs extensive tests)
  - [ ] Chain requests (one thread multiple requests)
  - [ ] Test socket solution on Flash target (it could be better than URLLoader)

---

## What's new 0.4.0 *[breaking API]*

- SSL support (cpp+neko using [hxssl](https://github.com/tong/hxssl), java using standard haxe)
- Easier instances (options instead of arguments for *new* Request objects)
- Better redirect handling (max 10 jumps + relative URLs support)
- Custom headers on Request
- Removed autoparse option
- User-agent option
- HTTP version option (1.0 or 1.1)
- Synchronous/Asynchronous option
- Request cloning (to perform a request more than once)

The API change is minimal but breaking:
Instead of making a Request object with 2 parameters
````haxe
// version <= 3.x
new AsyncHttpRequest('urlString',callbackFunction);
````
you can pass every setting as options
````haxe
// version >= 4.x
new AsyncHttpRequest({url:'urlString',callback:callbackFunction});
````

Fix your code! This edit was necessary to make future improvements easier with less future API changes.

## What's new 0.3.1 (fixed issue #1)

- Timeout option (request)
- Handling unexpected connection termination

## What's new 0.3 *[breaking API]*

- The library doesn't rely on OpenFL anymore and it is a pure Haxe library!
- Flash target use the default URLLoader (async)
- Javascript target use the default Haxe.Http (async XmlHttpRequest)
- The content (both on request and response) is now fully functional.
- The library is now thread-safe (major problems in 0.2)
- Support for redirection (HTTP STATUS 30x)
- Using sockets make requests around 50% faster than OpenFL URLLoader

## What's new 0.2

- First public release (relying on OpenFL)

---

## Important notes

**FLASH**: isBinary is always TRUE on the response object, the headers are always empty and don't rely on contentType

**JAVASCRIPT**: isBinary is always FALSE on the response object, the headers are always empty and don't rely on contentType

On both platforms you have to know what you are going to fetch to parse it as you need (toText(), toJson(), toXml()...)

## Quick reference

### Basic example

````haxe
// This is a basic GET example
var request = new AsyncHttpRequest({
         url : "http://www.google.com",
    callback : function(response:AsyncHttpResponse):Void {
                if (response.isOK) {
                  trace(response.content);
                  trace('DONE (HTTP STATUS ${response.status})');
                } else {
                  trace('ERROR (HTTP STATUS ${response.status})');
                }
              }  
});

request.send();
````


### All the available variables exposed

````haxe

// NOTE:
// An AsyncHttpRequest is mutable until sent
// An AsyncHttpResponse is immutable

// Force log to console (default enabled on -debug)
AsyncHttp.logEnabled = true;

// Force not throwing errors but trace (default disabled on -debug)
AsyncHttp.errorSafe = true;

// Global custom user-agent header [v0.4+]
AsyncHttp.userAgent = "akifox-asynchttp";

// This is a basic GET example that shows all the exposed variables
// NOTE: In FLASH and JAVASCRIPT cross-domain policies applies
//		 Security errors and failed requests could happen
var request = new AsyncHttpRequest({

  // String	 The request url "http://host:port/path?querystring"
  // NOTE: relative urls are accepted in FLASH and JAVASCRIPT
  url : "http://www.google.com",

  // Callback	 The function that will handle the response)
  callback : function(response:AsyncHttpResponse):Void {
         if (response.isOK) {
           // A Good response
           // isOK == true if status is >= 200 and < 400

           // An unique ID that match the request.fingerprint
           var fingerprint:String = response.fingerprint;

           // The immutable request object relative to this response
           var request:AsyncHttpRequest = response.request;

           // Time elapsed from request start to response end
           var time:Float = response.time;

           // The URL fetched (after all HTTP 30x redirections)
           // (Usually is the same as request.url)
           var url:String = response.urlString;

           // The guessued filename for the URL requested
           var filename:String = response.filename;

           // HTTP response headers
           // NOTE: You can use the following methods:
           //       .get('key'):String, .exists('key'):Bool, .keys():Iterator<String>
           // NOTE: Null in FLASH and JAVASCRIPT
           var headers:HttpHeaders = response.headers;

           // HTTP response status (set to 0 if connection error)
           var status:Int = response.status;

           // The response content (String or Bytes)
           // 		Based on content-type (XML, Json, Image [PNG, JPEG, GIF])
           // NOTE: Always Bytes in FLASH
           // NOTE: Always String in Javascript
           var content:Dynamic = response.content;

           // The response content untouched (Bytes)
           var contentRaw:Bytes = response.contentRaw;

           // The response content mime-type
           // NOTE: Always 'application/octet-stream' in FLASH
           // NOTE: Always 'text/plain' in JAVASCRIPT
           var contentType:String = response.contentType;

           // The response content length (in bytes or char)
           var contentLength:Int = response.contentLength;

           // Tells if the response.content is String or Byte
           // NOTE: Always true in FLASH
           // NOTE: Always false in JAVASCRIPT
           var isBinary:Bool = response.isBinary;
           var isText:Bool = response.isText; // == !isBinary

           // Tells if the response.content is Xml data
           // NOTE: Always false in FLASH and JAVASCRIPT
           var isXml:Bool = response.isXml; // == !isBinary

           // Tells if the response.content is Json data
           // NOTE: Always false in FLASH and JAVASCRIPT
           var isJson:Bool = response.isJson; // == !isBinary

           // Parse the content as Text [String]
           // Convert the data to String
           // (Usually is made in automatic, but using this
           //	function make sure it will be a String type)
           var contentText:String = response.toText();

           // Parse the content as Json
           //		[Anonymous Structure Object] (returns null on error)
           var contentJson:Dynamic = response.toJson();

           // Parse the content as Xml
           //		[Xml Object] (returns null on error)
           var contentXml:Xml = response.toXml();

           trace('DONE (HTTP STATUS ${response.status})');

         } else {

           // Any connection or status error
           trace('ERROR (HTTP STATUS ${response.status})');

         }
      },

  // HttpMethod | The request http method
  // Values are GET (default), POST, PUT or DELETE
  // NOTE: Only GET and POST are supported in Javascript
  method : HttpMethod.GET,

  // HttpHeaders | Custom HTTP headers (default 'empty')
  // NOTE: Not supported on FLASH and JAVASCRIPT
  // NOTE: You CANNOT set the basic headers as the library manage them
  //       Forbidden headers: "User-Agent","Host","Content-Type" and "Content-Length"
  headers : new HttpHeaders({
                  'Pragma':'no-cache',
                  'Accept-Language':'en-US'
                }),

  // Int     | Request timeout in seconds (default 10 seconds) [v0.3.1+]
  timeout : 10,

  // Bool    | Make the request asynchronous (default is true) [v0.4+]
  async : true,

  // Bool    | Use HTTP/1.1 otherwise 1.0 (default is true) [v0.4+]
  http11 : true,

  // Dynamic | The request content data to be sent
  content : null,

  // String  | The request content mime-type
  contentType : null // default "application/x-www-form-urlencoded"

}); //end AsyncHttpRequest instance

// String     | An unique ID to identify the request (generated)
var fingerprint:String =  request.fingerprint;

// You can also set or reset every property after the object creation
// NOTE: after being sent the request will be made as immutable
//       and the only way to change it would be cloning it ( request.clone() )
request.timeout = 20; // example to set the timeout to 20 seconds

request.send(); // start the request as set

````

## Examples

### Simple example with concurrent multiple requests
[Check it out](/samples/simple/)

The example shows how to handle multiple requests and responses

### Interactive example
[Check it out](/samples/interactive/)

The example allow the user to try any URL to see the behaviour of the library with redirects, errors and his own urls.

### Javascript example
[Check it out](/samples/javascript/)

A simple example in javascript that shows

### OpenFL Image URL to Stage (Bitmap) example
[Check it out](/samples/openfl/)

The example shows how to load a picture from an URL and display it on stage as Bitmap

NOTE: This example works only with OpenFL because it supports decoding of images (Jpeg, PNG and GIF) from raw bytes data.

## Write to a file the response
If you want to write in a file the response content you can use this snippet.

It will handle binary file (i.e. Images, Zip...) or text file (i.e. Html, Xml, Json...)

**NOTE:** *Take care of the path on different platforms!*

````haxe
request.callback = function(response:AsynchHttpResponse):Void {
					 var file = sys.io.File.write("/the/path/you/want/"+response.filename,response.contentIsBinary);
		             try {
		                file.write(response.contentRaw);
		                file.flush();
		             }
		                catch(err: Dynamic){
		                trace('Error writing file '+err);
		             }
		             file.close();
			       };
````
