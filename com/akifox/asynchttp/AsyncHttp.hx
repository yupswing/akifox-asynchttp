package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence

@version 0.4.0
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


	typedef AbstractSocket = {
		var input(default,null) : haxe.io.Input;
		var output(default,null) : haxe.io.Output;
		function connect( host : Host, port : Int ) : Void;
		function setTimeout( t : Float ) : Void;
		function write( str : String ) : Void;
		function close() : Void;
		function shutdown( read : Bool, write : Bool ) : Void;
	}

	// TCP Socket
	typedef SocketTCP = sys.net.Socket;

	// TCP+SSL Socket
	#if php
	typedef SocketSSL = php.net.SslSocket;
	#elseif java
	typedef SocketSSL = java.net.SslSocket;
	#elseif hxssl
		// #if neko
		// typedef SocketSSL = neko.tls.Socket;
		// #else
		typedef SocketSSL = sys.ssl.Socket;
		// #end
	#else
	typedef SocketSSL = sys.net.Socket; // NO SSL
	#end

	// Host
	typedef Host = sys.net.Host;

	typedef Requester = {
		var status:Int;
		var headers:AsyncHttpHeaders;
		var socket:AbstractSocket;
	}

#end

enum HttpTransferMode {
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

	public static inline var MAX_REDIRECTION:Int = 10; // 10 jumps allowed

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
			trace(message);
		} else {
			throw message;
		}
	}

	// ==========================================================================================

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

		request.finalise(); // request will not change

		#if (neko || cpp || java)

			if (request.async) {
				// Asynchronous (with a new thread)
				var worker = Thread.create(socketThread);
				worker.sendMessage(request);
			} else {
				// Synchronous (same thread)
				useSocket(request);
			}

		#elseif flash

			// URLLoader version (FLASH)
			useURLLoader(request);

		#elseif js

			// Standard Haxe HTTP
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
	private function useSocketRequest(url:URL,request:AsyncHttpRequest):Requester {

		var headers = new AsyncHttpHeaders();
		var status:Int = 0;

		var s:AbstractSocket;
		if (url.ssl) {
			s = new SocketSSL();
			#if (!php && !java && !hxssl)
			error('${request.fingerprint} ERROR: requested HTTPS but no SSL support (fallback on HTTP)\n
																		On Neko/CPP the library support hxssl (you have to install and reference it with `-lib hxssl`');
			#end
		} else {
			s = new SocketTCP();
		}
		s.setTimeout(request.timeout);

		// -- START REQUEST

		var connected = false;
		log('${request.fingerprint} INFO: Request\n> ${request.method} ${url}');
		try {
			#if flash
			s.connect(url.host, url.port);
			#else
			s.connect(new Host(url.host), url.port);
			#end
			connected = true;
		} catch (msg:Dynamic) {
		  error('${request.fingerprint} ERROR: Request failed -> $msg');
		}


		if (connected) {

			try {
				s.output.writeString('${request.method} ${url.resource}${url.querystring} HTTP/1.1\r\n');
				log('${request.fingerprint} HTTP > ${request.method} ${url.resource}${url.querystring} HTTP/1.1');
				s.output.writeString('User-Agent: '+USER_AGENT+'\r\n');
				log('${request.fingerprint} HTTP > User-Agent: akifox-asynchttp');
				s.output.writeString('Host: ${url.host}\r\n');
				log('${request.fingerprint} HTTP > Host: ${url.host}');
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
			} catch (msg:Dynamic) {
				error('${request.fingerprint} ERROR: Request failed -> $msg');
				status = 0;
				s.close();
				s = null;
				headers = new AsyncHttpHeaders();
				connected = false;
			}

		} // -- END REQUEST

		// -- START RESPONSE
		if (connected) {
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
					connected = false;
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

	private function socketThread() {
		var request:AsyncHttpRequest = Thread.readMessage(true);
		useSocket(request);
	}

	// Ask useSocketRequest to open a socket and send the request
	// then parse the response and handle it to the callback
	private function useSocket(request:AsyncHttpRequest)
	{
		//var request:AsyncHttpRequest = Thread.readMessage(true);
		if (request==null) return;

		var start = Timer.stamp();

		// RESPONSE
		var url:URL=request.url;
		var content:Dynamic=null;
		var contentType:String=null;
		var contentLength:Int=0;
		var contentIsBinary:Bool=false;
		var filename:String = determineFilename(request.url.toString());

		var connected:Bool = false;
		var redirect:Bool = false;

		var s:AbstractSocket;
		var headers = new AsyncHttpHeaders();
		var status:Int = 0;

		// redirects url list to avoid loops
		var redirectChain = new Array<String>();
		redirectChain.push(url.toString());

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
							var newURL = new URL(newlocation);
							newURL.merge(url);
			  			if (redirectChain.length<=MAX_REDIRECTION && redirectChain.indexOf(newURL.toString())==-1) {
								url = newURL;
								redirectChain.push(url.toString());
								log('${request.fingerprint} REDIRECT: $status -> ${url}');
								s.close();
								s = null;
			  			} else {
			  				// redirect loop
			  				redirect = false;
								s.close();
								s = null;
								connected = false;
								if (redirectChain.length>MAX_REDIRECTION) {
									error('${request.fingerprint} ERROR: Too many redirection (Max $MAX_REDIRECTION)\n'+redirectChain.join('-->'));
								} else {
									error('${request.fingerprint} ERROR: Redirection loop\n'+redirectChain.join('-->')+'-->'+redirectChain[0]);
								}

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
			var mode:HttpTransferMode = HttpTransferMode.UNDEFINED;
			if (contentLength>0) mode = HttpTransferMode.FIXED;
			if (headers['transfer-encoding'] == 'chunked') mode = HttpTransferMode.CHUNKED;
			log('${request.fingerprint} TRANSFER MODE: $mode');

			var bytes_loaded:Int = 0;
			var contentBytes:Bytes=null;

			switch(mode) {
				case HttpTransferMode.UNDEFINED:

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

				case HttpTransferMode.FIXED:

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

				case HttpTransferMode.CHUNKED:

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
			if (connected) s.close();
			s = null;
		}

		var time:Float = elapsedTime(start);

		log('${request.fingerprint} INFO: Response $status ($contentLength bytes in $time s)\n> ${request.method} $url');
		if (request.callback!=null)
		    request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
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
		var url:URL = request.url;
		var status:Int = 0;
		var headers = new AsyncHttpHeaders();
		var content:Dynamic = null;

		var contentType:String = DEFAULT_CONTENT_TYPE;
		var contentIsBinary:Bool = determineBinary(determineContentKind(contentType));;

		var filename:String = determineFilename(request.url.toString());
		urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);

		log('${request.fingerprint} INFO: Request\n> ${request.method} ${request.url}');

		var urlRequest = new URLRequest(request.url.toString());
		urlRequest.method = request.method;
		if (request.content!=null && request.method != HttpMethod.GET) {
			urlRequest.data = request.content;
			urlRequest.contentType = request.contentType;
			//urlRequest.dataFormat = (request.contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
		}

		var httpstatusDone = false;

		urlLoader.addEventListener("httpStatus", function(e:HTTPStatusEvent) {
			status = e.status;
		    log('${request.fingerprint} INFO: Response HTTP_Status $status');
			//content = null; // content will be retrive in EVENT.COMPLETE
			filename = determineFilename(url.toString());
			urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
			httpstatusDone = true; //flash does not call this event
		});

		urlLoader.addEventListener("httpResponseStatus", function(e:HTTPStatusEvent) {
			var newUrl = new URL(e.responseURL);
			newURL.merge(request.url);
			url = newURL;
			status = e.status;
		    log('${request.fingerprint} INFO: Response HTTP_Response_Status $status');
			try { headers = convertHeaders(e.responseHeaders); }
			//content = null; // content will be retrive in EVENT.COMPLETE
			contentType = determineContentType(headers);
			contentIsBinary = determineBinary(determineContentKind(contentType));
			filename = determineFilename(url.toString());

			urlLoader.dataFormat = (contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
			httpstatusDone = true; //flash does not call this event
		});

		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
		    var time = elapsedTime(start);
		    status = e.errorID;
		    error('${request.fingerprint} INFO: Response Error ' + e.errorID + ' ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
		    urlLoader = null;
		});

		urlLoader.addEventListener(SecurityErrorEvent.SECurity_ERROR, function(e:SecurityErrorEvent) {
		    var time = elapsedTime(start);
		    status = 0;
		    error('${request.fingerprint} INFO: Response Security Error ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
		    urlLoader = null;
		});

		urlLoader.addEventListener(Event.COMPLETE, function(e:Event) {
			if (!httpstatusDone) status = 200;

		    var time = elapsedTime(start);
		    content = Bytes.ofString(e.target.data);
		    log('${request.fingerprint} INFO: Response Complete $status ($time s)\n> ${request.method} ${request.url}');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
		    urlLoader = null;
		});

		try {
		  	urlLoader.load(urlRequest);
		} catch (msg:Dynamic) {
		    var time = elapsedTime(start);
		    error('${request.fingerprint} ERROR: Request failed -> $msg');
		    if (request.callback!=null)
		    	request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
		    urlLoader = null;
		}
	}

  	#elseif js

		private function useHaxeHttp(request:AsyncHttpRequest) {
			if (request==null) return;
			var start = Timer.stamp();

			// RESPONSE FIELDS
			var url:URL = request.url;
			var status:Int = 0;
			var headers = new AsyncHttpHeaders();
			var content:Dynamic = null;

			var contentType:String = DEFAULT_CONTENT_TYPE;
			var contentIsBinary:Bool = determineBinary(determineContentKind(contentType));

			var filename:String = determineFilename(url.toString());

			var r = new haxe.Http(url.toString());
			trace(url.toString());
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
		    		request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
			};

			r.onData = function(data:String) {
				if (!httpstatusDone) status = 200;
		    	var time = elapsedTime(start);
		    	content = data;
		    	log('${request.fingerprint} INFO: Response Complete $status ($time s)\n> ${request.method} ${request.url}');
		    	if (request.callback!=null)
		    		request.callback(new AsyncHttpResponse(request,time,url,headers,status,content,contentIsBinary,filename));
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
