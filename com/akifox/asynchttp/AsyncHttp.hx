package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence

@version 0.3.1
[Public repository](https://github.com/yupswing/akifox-asynchttp/)

#### Asyncronous HTTP Request HAXE Library
The akifox-asynchttp library provide a multi-threaded system
to make HTTP request and get responses.

#### Notes:
 * Inspired by Raivof "OpenFL: URLLoader() alternative using raw socket"
 * https://gist.github.com/raivof/dcdb1d74f93d17132a1e
 */

import haxe.Timer;
import haxe.io.Bytes;

using StringTools;


#if flash

	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.IOErrorEvent;

#elseif js

	import haxe.Http;

#end

typedef AsyncHttpHeaders = Map<String,String>;

#if (neko || cpp || java)

	#if neko
		typedef Thread = neko.vm.Thread;
		typedef Lib = neko.Lib;
	#elseif java
		typedef Thread = java.vm.Thread;
		typedef Lib = java.Lib;
	#elseif cpp
		typedef Thread = cpp.vm.Thread;
		typedef Lib = cpp.Lib;
	#end

	typedef Socket = sys.net.Socket;
	typedef Host = sys.net.Host;

	typedef Requester = {
		var status:Int;
		var headers:AsyncHttpHeaders;
		var socket:Socket;
	}

#end

enum AsyncHttpTransferMode {
  UNDEFINED;
  FIXED;
  CHUNKED;
}

enum ContentKind {
	XML;
	JSON;
	IMAGE;
	TEXT; //generic text type
	BYTES; //generic binary type
}

typedef ContentKindMatch = {
	var kind:ContentKind;
	var regex:EReg;
}

class AsyncHttp
{

	// ==========================================================================================

	// Thread safe static

	public static inline var USER_AGENT = "akifox-asynchttp";
	#if js
	public static inline var DEFAULT_CONTENT_TYPE = "text/plain";
	#else
	public static inline var DEFAULT_CONTENT_TYPE = "application/octet-stream";
	#end
	public static inline var DEFAULT_FILENAME = "untitled";

	private static var _contentKindMatch:Array<ContentKindMatch> = [
		{kind:ContentKind.IMAGE,regex:~/^image\/(jpe?g|png|gif)/i},
		{kind:ContentKind.XML,regex:~/(application\/xml|text\/xml|\+xml)/i},
		{kind:ContentKind.JSON,regex:~/^(application\/json|\+json)/i},
		{kind:ContentKind.TEXT,regex:~/(^text|application\/javascript)/i} //text is the last one
	];

	public static var logEnabled:Bool = #if debug true #else false #end;
	public static var errorSafe:Bool = #if debug false #else true #end;

	public static inline function log(message:String) {
		if (AsyncHttp.logEnabled) trace(message);
	}

	public static inline function error(message:String) {
		if (AsyncHttp.errorSafe) {
			log(message);
		} else {
			throw message;
		}
	}

	// ==========================================================================================

	public var REGEX_HTTP = ~/^http:/;
	public var REGEX_URL = ~/^https?:\/\/([^\/\?:]+)(:\d+|)(\/[^\?]*|)(\?.*|)/;
	public var REGEX_FILENAME = ~/([^?\/]*)($|\?.*)/;

	// ==========================================================================================

	public function new()
	{
		// One instance every Request.send() to be thread-safe
	}

	// ==========================================================================================

	// The content kind is used for autoParsing and determine if a content is Binary or Text
	public function determineContentKind(contentType:String):ContentKind {
		var contentKind = ContentKind.BYTES;
		for (el in _contentKindMatch) {
			if (el.regex.match(contentType)) {
				contentKind = el.kind;
				break;
			}
		}
		return contentKind;
	}

	public function determineBinary(contentKind:ContentKind):Bool {
		if (contentKind == ContentKind.BYTES || contentKind == ContentKind.IMAGE) return true;
		return false;
	}

	public function determineContentType(headers:AsyncHttpHeaders):String {
		var contentType = DEFAULT_CONTENT_TYPE;
		if (headers!=null) {
			if (headers.exists('content-type')) contentType = headers['content-type'];
		}
		return contentType;
	}

	public function determineFilename(url:String):String {
		var filename:String = "";
		var rx = REGEX_FILENAME;
		if (rx.match(url)) {
			filename = rx.matched(1);
		}
		if (filename=="") filename = AsyncHttp.DEFAULT_FILENAME;
		return filename;
	}

	// ==========================================================================================

	public function elapsedTime(start:Float):Float {
		return Std.int((Timer.stamp() - start)*1000)/1000;
	}

	// ==========================================================================================


	public function send(request:AsyncHttpRequest) {

		request.finalize(); // request will not change

		#if (neko || cpp || java)

			if (REGEX_HTTP.match(request.url)) {

				// Multithread version (only Neko, CPP and JAVA) HTTP protocol
				var worker = Thread.create(useSocket);
				worker.sendMessage(request);

				//useSocket(request); //REQUEST WITHOUT THREAD (TESTING PURPOSES)

			} else {

			  	error('${request.fingerprint} ERROR: Only HTTP Protocol supported -> ${request.url}');

			}

		#elseif flash

			// URLLoader version (FLASH)
			useURLLoader(request);

		#elseif js

			useHaxeHttp(request);

		#else

		  	error('ERROR: Platform not supported');

		#end

	}

	#if (neko || cpp || java)

	// ==========================================================================================
	// Multi-thread version for neko, CPP + JAVA


	// Open a socket, send a request and get the headers
	// (could be called more than once in case of redirects)
	private function useSocketRequest(url:String,request:AsyncHttpRequest):Requester {

		var s = new Socket();
		s.setTimeout(request.timeout);
		var headers = new AsyncHttpHeaders();
		var status:Int = 0;

		var rx = REGEX_URL; // decode url (HTTP://$HOST:$PORT/$PATH?$DATA)
		rx.match(url);
		var host = rx.matched(1);
		var port = rx.matched(2);
		if (port=="") port = "80";
		else port = port.substr(1); //removes ":"
		var path = rx.matched(3);
		if (path=="") path = "/";
		var querystring = rx.matched(4);

		// -- START REQUEST

		var connected = false;
		log('${request.fingerprint} INFO: Request\n> ${request.method} $host:$port$path$querystring');
		try {
			#if flash
			s.connect(host, Std.parseInt(port));
			#else
			s.connect(new Host(host), Std.parseInt(port));
			#end
			connected = true;
		} catch (msg:Dynamic) {
		  	error('${request.fingerprint} ERROR: Request failed -> $msg');
		}


		if (connected) {

			s.output.writeString('${request.method} $path$querystring HTTP/1.1\r\n');
			log('${request.fingerprint} HTTP > ${request.method} $path$querystring HTTP/1.1');
			s.output.writeString('User-Agent: '+USER_AGENT+'\r\n');
			log('${request.fingerprint} HTTP > User-Agent: akifox-asynchttp');
			s.output.writeString('Host: $host\r\n');
			log('${request.fingerprint} HTTP > Host: $host');
			if (request.content!=null) {
				s.output.writeString('Content-Type: ${request.contentType}\r\n');
				log('${request.fingerprint} HTTP > Content-Type: ${request.contentType}');
				s.output.writeString('Content-Length: '+request.content.length+'\r\n');
				log('${request.fingerprint} HTTP > Content-Length: '+request.content.length);
				s.output.writeString('\r\n');
				if (request.contentIsBinary) {
					s.output.writeBytes(cast(request.content,Bytes),0,request.content.length);
				} else {
					s.output.writeString(request.content.toString());
				}
			}
			s.output.writeString('\r\n');

			// -- END REQUEST

			// -- START RESPONSE

			var ln:String = '';
			while (true)
			{
				try {
					ln = s.input.readLine().trim();
				} catch(msg:Dynamic) {
					// error (probably unexpected connection terminated)
					error('${request.fingerprint} ERROR: Transfer failed -> $msg');
					ln = '';
					status = 0;
					s.close();
					s = null;
					headers = new AsyncHttpHeaders();
				}
				if (ln == '') break; //end of response headers

				if (status==0) {
					var r = ~/^HTTP\/\d+\.\d+ (\d+)/;
					r.match(ln);
					status = Std.parseInt(r.matched(1));
				} else {
					var a = ln.split(':');
					var key = a.shift().toLowerCase();
					headers[key] = a.join(':').trim();
				}
		  }

		  // -- END RESPONSE HEADERS
		}

		return {status:status,socket:s,headers:headers};
	}

	// Ask useSocketRequest to open a socket and send the request
	// then parse the response and handle it to the callback
	private function useSocket()
	{
		var request:AsyncHttpRequest = Thread.readMessage(true);
		if (request==null) return;

		var start = Timer.stamp();

		// RESPONSE
		var url:String=request.url; //the response url
		var content:Dynamic=null;
		var contentType:String=null;
		var contentLength:Int=0;
		var contentIsBinary:Bool=false;
		var filename:String = determineFilename(request.url);

		var connected:Bool = false;
		var redirect:Bool = false;

		var s:sys.net.Socket;
		var headers = new AsyncHttpHeaders();
		var status:Int = 0;


		do {
			var req:Requester = useSocketRequest(url,request);
			status = req.status;
			s = req.socket;
			headers = req.headers;
			req = null;

			connected = (status!=0);
			redirect = false;

			if (connected) {
				redirect = (status == 301 || status == 302 || status == 303 || status == 307);
				// determine if redirection
			  	if (redirect) {
			  		var newlocation = headers['location'];
			  		if (newlocation != "") {
			  			if (url!=newlocation) {
			  				url = newlocation;
							log('${request.fingerprint} REDIRECT: $status -> ${url}');
							s.close();
							s = null;
			  			} else {
			  				// redirect to same url
			  				redirect = false;
			  			}
			  		}
			    }
			}
		} while(redirect);

		if (connected) {

			// -- START RESPONSE CONTENT

		  	// determine content properties
			contentLength = Std.parseInt(headers['content-length']);
			contentType = determineContentType(headers);
			var contentKind:ContentKind = determineContentKind(contentType);
			contentIsBinary = determineBinary(contentKind);

			// determine transfer mode
			var mode:AsyncHttpTransferMode = AsyncHttpTransferMode.UNDEFINED;
			if (contentLength>0) mode = AsyncHttpTransferMode.FIXED;
			if (headers['transfer-encoding'] == 'chunked') mode = AsyncHttpTransferMode.CHUNKED;
			log('${request.fingerprint} TRANSFER MODE: $mode');

			var bytes_loaded:Int = 0;
			var contentBytes:Bytes=null;

			switch(mode) {
				case AsyncHttpTransferMode.UNDEFINED:

					// UNKNOWN CONTENT LENGTH

					try {
						contentBytes = s.input.readAll();
					} catch(msg:Dynamic) {
						error('${request.fingerprint} ERROR: Transfer failed -> $msg');
						status = 0;
						contentBytes = Bytes.alloc(0);
					}
					contentLength = contentBytes.length;
				  log('${request.fingerprint} LOADED: $contentLength/$contentLength bytes (100%)');

				case AsyncHttpTransferMode.FIXED:

					// KNOWN CONTENT LENGTH

			    contentBytes = Bytes.alloc(contentLength);
			    var block_len = 1024 * 1024;   // BLOCK SIZE: small value (like 64 KB) causes slow download
			    var nblocks = Math.ceil(contentLength / block_len);
			    var bytes_left = contentLength;
			    bytes_loaded = 0;

			    for (i in 0...nblocks)
			    {
			      var actual_block_len = (bytes_left > block_len) ? block_len : bytes_left;
						try {
				      s.input.readFullBytes(contentBytes, bytes_loaded, actual_block_len);
						} catch(msg:Dynamic) {
							error('${request.fingerprint} ERROR: Transfer failed -> $msg');
							status = 0;
							contentBytes = Bytes.alloc(0);
							break;
						}
			      bytes_left -= actual_block_len;

			      bytes_loaded += actual_block_len;
			      log('${request.fingerprint} LOADED: $bytes_loaded/$contentLength bytes (' + Math.round(bytes_loaded / contentLength * 1000) / 10 + '%)');
			    }

				case AsyncHttpTransferMode.CHUNKED:

					// CHUNKED MODE

					var bytes:Bytes;
					var buffer = new haxe.io.BytesBuffer();
					var chunk:Int;
					try {
						while(true) {
							var v:String = s.input.readLine();
							chunk = Std.parseInt('0x$v');
							if (chunk==0) break;
							bytes = s.input.read(chunk);
							bytes_loaded += chunk;
							buffer.add(bytes);
							s.input.read(2); // \n\r between chunks = 2 bytes
							log('${request.fingerprint} LOADED: $bytes_loaded bytes (Total unknown)');
						}
					} catch(msg:Dynamic) {
						error('${request.fingerprint} ERROR: Transfer failed -> $msg');
						status = 0;
						buffer = new haxe.io.BytesBuffer();
					}

					contentBytes = buffer.getBytes();
					contentLength = bytes_loaded;

					buffer = null;
					bytes = null;
			}

			//if (contentIsBinary)
			//	content = contentBytes;
			//else
			//	content = contentBytes.toString();

			// The response content is always given in bytes and handled by the AsyncHttpResponse object
			content = contentBytes;
			contentBytes = null;

		  	// -- END RESPONSE

		}

		if (s!=null) {
			s.close();
			s = null;
		}

		var time:Float = elapsedTime(start);

		log('${request.fingerprint} INFO: Response $status ($contentLength bytes in $time s)\n> ${request.method} $url');
		if (request.callback!=null)
		    request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
  	}

  	#elseif flash

	// ==========================================================================================
	// URLLoader version (FLASH)

	// Convert from the Flash format to a simpler Map<String,String>
	private function convertHeaders(urlLoaderHeaders:Array<Dynamic>):AsyncHttpHeaders {
		var headers = new AsyncHttpHeaders();
		if (urlLoaderHeaders!=null) {
			for (el in urlLoaderHeaders) {
				headers[el.name.trim().toLowerCase()] = el.value;
			}
		}
		return headers;
	}

	private function useURLLoader(request:AsyncHttpRequest) {
		if (request==null) return;

		var urlLoader:URLLoader = new URLLoader();
		var start = Timer.stamp();

		// RESPONSE FIELDS
		var url:String = request.url;
		var status:Int = 0;
		var headers = new AsyncHttpHeaders();
		var content:Dynamic = null;

		var contentType:String = DEFAULT_CONTENT_TYPE;
		var contentIsBinary:Bool = determineBinary(determineContentKind(contentType));;

		var filename:String = determineFilename(request.url);
		urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);

		log('${request.fingerprint} INFO: Request\n> ${request.method} ${request.url}');

		var urlRequest = new URLRequest(request.url);
		urlRequest.method = request.method;
		if (request.content!=null && request.method != AsyncHttpMethod.GET) {
			urlRequest.data = request.content;
			urlRequest.contentType = request.contentType;
			//urlRequest.dataFormat = (request.contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
		}

		var httpstatusDone = false;

		urlLoader.addEventListener("httpStatus", function(e:HTTPStatusEvent) {
			status = e.status;
		    log('${request.fingerprint} INFO: Response HTTP_Status $status');
			//content = null; // content will be retrive in EVENT.COMPLETE
			filename = determineFilename(url);
			urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
			httpstatusDone = true; //flash does not call this event
		});

		urlLoader.addEventListener("httpResponseStatus", function(e:HTTPStatusEvent) {
			url = e.responseURL;
			if (url==null) url = request.url;
			status = e.status;
		    log('${request.fingerprint} INFO: Response HTTP_Response_Status $status');
			try { headers = convertHeaders(e.responseHeaders); }
			//content = null; // content will be retrive in EVENT.COMPLETE
			contentType = determineContentType(headers);
			contentIsBinary = determineBinary(determineContentKind(contentType));
			filename = determineFilename(url);

			urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
			httpstatusDone = true; //flash does not call this event
		});

		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
		    var time = elapsedTime(start);
		    status = e.errorID;
		    error('${request.fingerprint} INFO: Response Error ' + e.errorID + ' ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
		    urlLoader = null;
		});

		urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent) {
		    var time = elapsedTime(start);
		    status = 0;
		    error('${request.fingerprint} INFO: Response Security Error ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
		    urlLoader = null;
		});

		urlLoader.addEventListener(Event.COMPLETE, function(e:Event) {
			if (!httpstatusDone) status = 200;

		    var time = elapsedTime(start);
		    content = Bytes.ofString(e.target.data);
		    log('${request.fingerprint} INFO: Response Complete $status ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
		    urlLoader = null;
		});

		try {
		  	urlLoader.load(urlRequest);
		} catch (msg:Dynamic) {
		    var time = elapsedTime(start);
		    error('${request.fingerprint} ERROR: Request failed -> $msg');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
		    urlLoader = null;
		}
	}

  	#elseif js

		private function useHaxeHttp(request:AsyncHttpRequest) {
			if (request==null) return;
			var start = Timer.stamp();

			// RESPONSE FIELDS
			var url:String = request.url;
			var status:Int = 0;
			var headers = new AsyncHttpHeaders();
			var content:Dynamic = null;

			var contentType:String = DEFAULT_CONTENT_TYPE;
			var contentIsBinary:Bool = determineBinary(determineContentKind(contentType));

			var filename:String = determineFilename(request.url);

			var r = new haxe.Http(request.url);
			r.async = true; //default
			//r.setHeader("User-Agent",USER_AGENT); //give warning in Chrome
			if (request.content!=null) {
				r.setPostData(Std.string(request.content));
			}

			var httpstatusDone = false;

			r.onError = function(msg:String) {
		    	error('${request.fingerprint} ERROR: Request failed -> $msg');
		    	var time = elapsedTime(start);
		    	if (request.callback!=null)
		    		request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
			};

			r.onData = function(data:String) {
				if (!httpstatusDone) status = 200;
		    	var time = elapsedTime(start);
		    	content = data;
		    	log('${request.fingerprint} INFO: Response Complete $status ($time s)\n> ${request.method} ${request.url}');
		    	if (request.callback!=null)
		    		request.callback(new AsyncHttpResponse(request.fingerprint,time,url,headers,status,content,contentIsBinary,filename,request.autoParse));
			};

			r.onStatus = function(http_status:Int) {
				status = http_status;
			    log('${request.fingerprint} INFO: Response HTTP Status $status');
				httpstatusDone = true; //flash does not call this event
			}

			r.request(request.content!=null);
		}

	#end

	// ==========================================================================================

	//##########################################################################################
	//
	// UID Generator
	//
	//##########################################################################################

	private static var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

	public function randomUID(?size:Int=32):String
	{
		var nchars = UID_CHARS.length;
		var uid = new StringBuf();
		for (i in 0 ... size){
			uid.addChar(UID_CHARS.charCodeAt( Std.random(nchars) ));
		}
		return uid.toString();
	}

}
