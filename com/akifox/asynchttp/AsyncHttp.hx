package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence

@version 0.2.1
[Public repository](https://github.com/yupswing/akifox-asynchttp/)

#### Asyncronous HTTP Request HAXE/OpenFL Library
The akifox-asynchttp library provide a multi-threaded system
to make HTTP request and get responses.

#### Notes:
 * Inspired by Raivof "OpenFL: URLLoader() alternative using raw socket"
 * https://gist.github.com/raivof/dcdb1d74f93d17132a1e

 */

import haxe.Timer;
using StringTools;

#if (neko || cpp || java)

	import haxe.io.Bytes;

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

#else

	import openfl.net.URLLoader;
	import openfl.net.URLRequest;
	import openfl.events.Event;
	import openfl.events.IOErrorEvent;

#end
 

enum TRANSFER_MODE {
  UNDEFINED;
  FIXED;
  CHUNKED;
}
 
class AsyncHttp
{

	private function new()
	{
		//no instance
	}

	public static var logEnabled:Bool = #if debug true #else false #end;

	public static inline function log(message:String) {
		if (logEnabled) trace('$message'); 
	}

	public static function send(request:AsyncHttpRequest) {

		#if (neko || cpp || java)

		// Multithread version for NEKO, CPP + JAVA
		var worker = Thread.create(useSocket);
		worker.sendMessage(request);

		#else

		// URLLoader version (HTML5 + FLASH)
		useURLLoader(request);

		#end

	}

	#if (neko || cpp || java)

	// Multithread version for NEKO, CPP + JAVA

	private static function useSocket()
	{
		var request:AsyncHttpRequest = Thread.readMessage(true);
		if (request==null) return;

		var fingerprint:String = request.fingerprint;
		var url:String = request.url;
		var method:String = request.method;
		var data:String = request.content;
		var contentType:String = request.contentType;
		var responseF:AsyncHttpResponse->Void = request.responseF;

		var contentString:String=null;
		var contentBytes:Bytes=null;
		var contentLength:Int=0;
		var start = Timer.stamp();

		// decode url (HTTP://$HOST:$PORT/$PATH?$DATA)
		var r = ~/https?:\/\/([^\/\?:]+)(:\d+|)(\/[^\?]*|)(\?.*|)/;
		r.match(url);
		var host = r.matched(1);
		var port = r.matched(2);
		if (port=="") port = "80";
		else port = port.substr(1); //removes ":"
		var path = r.matched(3);
		if (path=="") path = "/";
		var querystring = r.matched(4);

		log('$fingerprint INFO: Request\n> $method $host:$port$path$querystring');
		var s = new sys.net.Socket();
		var connected = false;
		try {
			s.connect(new sys.net.Host(host), Std.parseInt(port));
			connected = true;
		} catch (m:String) {
		  	log('$fingerprint ERROR: Request failed -> $m');
		}

		var headers = new Map<String, String>();
		var response_code:Int = 0;
		var bytes_loaded:Int = 0;

		if (connected) {
			s.output.writeString('$method $path$querystring HTTP/1.1\r\n');
			log('$fingerprint HTTP > $method $path$querystring HTTP/1.1');
			s.output.writeString('User-Agent: akifox-asynchttp\r\n');
			log('$fingerprint HTTP > User-Agent: akifox-asynchttp');
			s.output.writeString('Host: $host\r\n');
			log('$fingerprint HTTP > Host: $host');
			if (data!=null) {
				s.output.writeString('Content-Type: $contentType\r\n');
				log('$fingerprint HTTP > Content-Type: $contentType');
				s.output.writeString('Content-Length: '+data.length+'\r\n');
				log('$fingerprint HTTP > Content-Length: '+data.length);
				s.output.writeString('\r\n');
				s.output.writeString(data);
			}
			s.output.writeString('\r\n');

			var response:String = "";
			while (true)
			{
				var ln = s.input.readLine().trim();
				if (ln == '') break; //end of response headers

				if (response=="") {
					response = ln;
					var r = ~/^HTTP\/\d+\.\d+ (\d+)/;
					r.match(response);
					response_code = Std.parseInt(r.matched(1));
				} else {
					var a = ln.split(':');
					var key = a.shift().toLowerCase();
					headers[key] = a.join(':').trim();   
				}   
		  	}

			var chunked = (headers['transfer-encoding'] == 'chunked');
			contentLength = Std.parseInt(headers['content-length']);

			var mode:TRANSFER_MODE = TRANSFER_MODE.UNDEFINED;
			if (contentLength>0) mode = TRANSFER_MODE.FIXED;
			if (chunked) mode = TRANSFER_MODE.CHUNKED;

			var bytes:Bytes;

			switch(mode) {
				case TRANSFER_MODE.UNDEFINED, TRANSFER_MODE.FIXED:
					// fixed mode explicit a content-lenght
					// but the READALL already load data in predefined chunk
					// based on platform (so no need to chunk the process)

					bytes = s.input.readAll();
					bytes_loaded = bytes.length;
					contentBytes = bytes;
					contentLength = bytes_loaded;
					contentString = contentBytes.toString();

				case TRANSFER_MODE.CHUNKED:

					var buffer = new Array<Bytes>();
					var chunk:Int;
					while(true) {
						var v:String = s.input.readLine();
						//trace(v.toString());
						chunk = Std.parseInt('0x$v');
						//trace('chunk $chunk');
						if (chunk==0) break;
						bytes = s.input.read(chunk);
						bytes_loaded += chunk;
						buffer.push(bytes);
						s.input.read(2); // \n\r between chunks = 2 bytes
					}

					//contentBytes = content; //todo has to be bytes
					contentLength = bytes_loaded;
					contentString = buffer.join('');

					buffer = null;
			}

		  bytes = null;

		}

		s.close();
		s = null;

		var time = Std.int((Timer.stamp() - start)*1000)/1000;

		log('$fingerprint INFO: Response $response_code ($bytes_loaded bytes in $time s)\n> $method $host:$port$path$querystring');
		if (responseF!=null)
		    responseF(new AsyncHttpResponse(fingerprint,headers,response_code,contentString,time));
  	}

	#else
	  
	// URLLoader version (HTML5 + FLASH)

	private static function useURLLoader(request:AsyncHttpRequest) {
		if (request==null) return;
		var urlLoader:URLLoader = new URLLoader();
		var start = Timer.stamp();

		var fingerprint:String = request.fingerprint;
		var url:String = request.url;
		var method:String = request.method;
		var data:String = request.content;
		var contentType:String = request.contentType;
		var responseF:AsyncHttpResponse->Void = request.responseF;

		log('$fingerprint INFO: Request\n> $method $url');

		urlLoader.addEventListener(Event.COMPLETE, function(e:Event) {
		    var time = Std.int((Timer.stamp() - start)*1000)/1000;
		    log('$fingerprint INFO: Response 200 ($time s)\n> $method $url');
		    if (responseF!=null)
		    	responseF(new AsyncHttpResponse(fingerprint,null,200,e.target.data,time));
		    urlLoader = null;
		});
		urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
		    var time = Std.int((Timer.stamp() - start)*1000)/1000;
		    log('$fingerprint INFO: Response ' + e.errorID + ' ($time s)\n> $method $url');
		    if (responseF!=null)
		    	responseF(new AsyncHttpResponse(fingerprint,null,e.errorID,null,time));
		    urlLoader = null;
		});

		var urlRequest = new URLRequest(url);
		urlRequest.method = method;
		if (data!=null) {
			urlRequest.data = data;
			urlRequest.contentType = contentType;
		}

		try {
		  	urlLoader.load(urlRequest);
		} catch ( msg : Dynamic ) {
		    var time = Std.int((Timer.stamp() - start)*1000)/1000;
		    log('$fingerprint ERROR: Request failed -> ' + msg.toString());
		    if (responseF!=null)
		    	responseF(new AsyncHttpResponse(fingerprint,null,0,null,time));
		    urlLoader = null;
		} 
	}

	#end

	//##########################################################################################
	//
	// UID Generator
	//
	//##########################################################################################
	
	private static var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

	public static function randomUID(?size:Int=32):String
	{
		var nchars = UID_CHARS.length;
		var uid = new StringBuf();
		for (i in 0 ... size){
			uid.addChar(UID_CHARS.charCodeAt( Std.random(nchars) ));
		}
		return uid.toString();
	}

}