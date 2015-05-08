[![akifox-asynchttp](https://img.shields.io/badge/library-akifox%20asynchttp%200.4.1-brightgreen.svg)]()
[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Haxe 3](https://img.shields.io/badge/language-Haxe%203-orange.svg)](http://www.haxe.org)

[![Library](https://img.shields.io/badge/type-haxelib%20library-orange.svg)](http://lib.haxe.org/p/akifox-asynchttp)
[![Haxelib](https://img.shields.io/badge/distr-v0.4.1-yellow.svg)](http://lib.haxe.org/p/akifox-asynchttp)

## BREAKING API VERSION 0.4
If you were using akifox-asynchttp, please check what have changed in the new version 0.4 and update your code as explained [here](CHANGELOG.md#whats-new-040-breaking-api)

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
 * [What's new](CHANGELOG.md)
 * [Important platform notes](#important-platform-notes)
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
  - [ ] More platforms (php, python...)? Post a [ticket](https://github.com/yupswing/akifox-asynchttp/issues) if you would like one
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
  - [ ] Support SSL for iOS and Android (need to make [hxssl](https://github.com/tong/hxssl) NDLLs for those platform)
  - [ ] Posting content on request (it should work but needs extensive tests)
  - [ ] Chain requests (one thread multiple requests)
  - [ ] Test socket solution on Flash target (it could be better than URLLoader)

---

## Important platform notes

**CPP/NEKO/JAVA**
- Full support

**FLASH**:
- *response.isBinary* is always TRUE on the response object
- *response.headers* is always empty, so don't rely on *response.contentType*
- you have to know what you are going to fetch to parse it as you need (toText(), toJson(), toXml()...)

**JAVASCRIPT**:
- *response.isBinary* is always FALSE on the response object
- *response.headers* is always empty, so don't rely on *response.contentType*
- you have to know what you are going to fetch to parse it as you need (toText(), toJson(), toXml()...)
- no support for methods PUT and DELETE

## Quick reference

### Basic example

````haxe
import com.akifox.asynchttp.*;

//[...]

// This is a basic GET example
var request = new HttpRequest({
         url : "http://www.google.com",
    callback : function(response:HttpResponse):Void {
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
import com.akifox.asynchttp.*;

// [...]

// NOTE:
// An HttpRequest is mutable until sent
// An HttpResponse is immutable

// Force log to console (default enabled on -debug)
AsyncHttp.logEnabled = true;

// Force not throwing errors but trace (default disabled on -debug)
AsyncHttp.errorSafe = true;

// Global custom user-agent header (default "akifox-asynchttp") [v0.4+]
AsyncHttp.userAgent = "akifox-asynchttp";

// Global maximum number of redirection allowed (default 10) [v0.4+]
AsyncHttp.maxRedirections = 10;

// This is a basic GET example that shows all the exposed variables
// NOTE: In FLASH and JAVASCRIPT cross-domain policies applies
//		 Security errors and failed requests could happen
var request = new HttpRequest({

  // String | The request url (format is "protocol://host:port/resource?querystring")
  // NOTE: relative urls are accepted in FLASH and JAVASCRIPT
  url : "http://www.google.com",

  // Callback	 The function that will handle the response
  callback : function(response:HttpResponse):Void {
         // NOTE: If callbackError is set the errors will be given to that function instead
         //       and response.isOK will be always True here
         if (response.isOK) {
           // A Good response
           // isOK == true if status is >= 200 and < 400

           // An unique ID that match the request.fingerprint
           var fingerprint:String = response.fingerprint;

           // The immutable request object relative to this response
           var request:HttpRequest = response.request;

           // Time elapsed from request start to response end
           var time:Float = response.time;

           // The URL fetched (after all HTTP 30x redirections)
           // (Usually it is the same as request.url)
           var url:String = response.urlString;

           // The guessued filename for the URL requested
           var filename:String = response.filename;

           // HTTP response headers
           // NOTE: You can use the following methods:
           //       .get('key'):String, .exists('key'):Bool, .keys():Iterator<String>
           // NOTE: Null in FLASH and JAVASCRIPT
           var headers:HttpHeaders = response.headers;

           // HTTP response status (set to 0 if connection error)
           // NOTE: If callbackError is set the errors will be given to that function instead
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

  // !OPTIONAL! If set this function will handle all the response errors
  // otherwise success and failure responses will be given to the standard 'callback'
  callbackError : function(response:HttpResponse):Void {
         // response.isOK is always False here

         // HTTP response status
         // 0 if connection error
         // HTTP error status if connection is ok (<200 or >=400)
         var status:Int = response.status;

         trace('ERROR (HTTP STATUS ${status})');

      },

  // HttpMethod | The request http method
  // Values are GET (default), POST, PUT or DELETE
  // NOTE: Only GET and POST are supported in Javascript
  method : HttpMethod.GET,

  // HttpHeaders | Custom HTTP headers (default 'empty')
  // NOTE: Not supported on FLASH and JAVASCRIPT
  // NOTE: You CANNOT set the basic headers as the library manage them
  //       Ignored headers: "User-Agent","Host","Content-Type" and "Content-Length"
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

}); //end HttpRequest instance

// String     | An unique ID to identify the request (generated)
var fingerprint:String =  request.fingerprint;

// You can also set or reset every property after the object creation
// NOTE: after being sent the request will be made as immutable
//       and the only way to change it would be cloning it ( request.clone() )
request.timeout = 20; // example to set the timeout to 20 seconds

request.send(); // start the request as set

// If you want to send the request again you have to clone it
// It will get a new fingerprint and you can change all its properties
// (This is because once a request is sent it gets finalised and it becomes immutable)
var newRequest = request.clone();
newRequest.timeout = 10; //change a property example
newRequest.send();

````

## Examples

### Simple example with concurrent multiple requests
[Check it out](/samples/simple/)

The example shows how to handle multiple requests and responses

### Interactive example
[Check it out](/samples/interactive/)

The example allow the user to try any URL to see the behavior of the library with redirects, errors and his own urls.

### SSL example
[Check it out](/samples/ssl/)

The example shows the seamless SSL support (the only difference between HTTP and HTTPS is in the URL).

### Javascript example
[Check it out](/samples/javascript/)

A simple example in javascript that shows how to use the library.

### Flash example
[Check it out](/samples/flash/)

A simple example in flash that shows how to use the library.

### OpenFL Image URL to Stage (Bitmap) example
[Check it out](/samples/openfl/)

The example shows how to load a picture from an URL and display it on stage as Bitmap

NOTE: This example works only with OpenFL because it supports decoding of images (Jpeg, PNG and GIF) from raw bytes data.

## Write to a file the response
If you want to write in a file the response content you can use this snippet.

It will handle binary file (i.e. Images, Zip...) or text file (i.e. Html, Xml, Json...)

**NOTE:** *Take care of the path on different platforms!*

````haxe
request.callback = function(response:HttpResponse):Void {
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
