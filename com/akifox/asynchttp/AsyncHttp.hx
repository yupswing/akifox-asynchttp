package com.akifox.asynchttp;

/*
@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence

@version 0.4.7
[Public repository](https://github.com/yupswing/akifox-asynchttp/)

#### Asyncronous HTTP+HTTPS Request HAXE Library
The akifox-asynchttp library provide a multi-threaded tool
to handle HTTP+HTTPS requests with a common API.

#### Notes:
 * Inspired by Raivof "OpenFL: URLLoader() alternative using raw socket"
 * https://gist.github.com/raivof/dcdb1d74f93d17132a1e
 */

import haxe.Timer;
import haxe.io.Bytes;

using StringTools;

#if flash

// Standard Flash URLLoader
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestHeader;
import flash.events.Event;
import flash.events.HTTPStatusEvent;
import flash.events.SecurityErrorEvent;
import flash.events.IOErrorEvent;

#elseif js

// Standard Haxe Http
import haxe.Http;

#elseif(neko || cpp || java)

// Threading
#if neko
private typedef Thread = neko.vm.Thread;
private typedef Lib = neko.Lib;
#elseif java
private typedef Thread = java.vm.Thread;
private typedef Lib = java.Lib;
#elseif cpp
private typedef Thread = cpp.vm.Thread;
private typedef Lib = cpp.Lib;
#end

// Sockets
private typedef AbstractSocket = {
  var input(default, null):haxe.io.Input;
  var output(default, null):haxe.io.Output;

  function connect(host:Host, port:Int):Void;
  function setTimeout(t:Float):Void;
  function write(str:String):Void;
  function close():Void;
  function shutdown(read:Bool, write:Bool):Void;
}

// TCP Socket
private typedef SocketTCP = sys.net.Socket;

// TCP+SSL Socket
#if java
  private typedef SocketSSL = java.net.SslSocket;
#elseif php
  private typedef SocketSSL = php.net.SslSocket;
#elseif (python || neko || macro || cpp || lua)
  private typedef SocketSSL = sys.ssl.Socket;
#else
  // Fallback to normal socket
  private typedef SocketSSL = sys.net.Socket;
#end

// Host
private typedef Host = sys.net.Host;

// Used by httpViaSocketConnect() to exchange data with httpViaSocket()
private typedef Requester = {
  var status:Int;
  var headers:HttpHeaders;
  var socket:AbstractSocket;
  var errorMessage:String;
}

#else

#error "Platform not supported (yet!)\n
Post a request to the official repository:\n
https://github.com/yupswing/akifox-asynchttp/issues"

#end

private enum HttpTransferMode {
  UNDEFINED;
  FIXED;
  CHUNKED;
  NO_CONTENT;
}

@:dox(hide)
enum ContentKind {
  XML;
  JSON;
  IMAGE;
  TEXT; //generic text type
  BYTES; //generic binary type
}

private typedef ContentKindMatch = {
  var kind:ContentKind;
  var regex:EReg;
}

// DEPRECATED Kept for 0.1.x to 0.3.x compatibility
@:dox(hide)
typedef AsyncHttpResponse = HttpResponse;
@:dox(hide)
typedef AsyncHttpRequest = HttpRequest;


/**
##AsyncHttp

This is the main class of the library

**NOTE:** It is used by most of the library to keep common functions and variables

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@licence MIT Licence
**/
class AsyncHttp {

  // ==========================================================================================

  // Global settings (customisable)

  /**
   * Force log to console
   *
   * (default set to true on -debug)
   **/
  public static var logEnabled:Bool = #if debug true #else false #end;
  public static var logErrorEnabled:Bool = true;

  /**
   * Deprecated and ignored (will be dropped in 0.5) #TODO
   **/
  public static var errorSafe:Bool = false;

  /**
   * The HTTP User Agent string sent on request (default:'akifox-asynchttp')
   *
   * **NOTE:** This is a global setting that will apply to every request
   *
   * **WARNING:** This option is not used on Flash and JS (due to platforms limitations)
   **/
  public static var userAgent:String = "akifox-asynchttp";

  /**
   * The maximum number of redirection allowed per request
   *
   * **NOTE:** This is a global setting that will apply to every request
   *
   * **WARNING:** This option is not used on Flash and JS (due to platforms limitations)
   **/
  public static var maxRedirections:Int = 10;

  // ==========================================================================================

  // Logging trace
  @:dox(hide)
  public static inline function log(message:String, fingerprint:String = ''):String {
    if (AsyncHttp.logEnabled) {
      trace('${fingerprint} INFO:${message}');
    }
    return message;
  }

  // Error trace
  @:dox(hide)
  public static inline function error(message:String, fingerprint:String = '', throwError:Bool = false):String {
    if (AsyncHttp.logErrorEnabled) {
      trace('${fingerprint} ERROR:${message}');
    }
    if (throwError) throw 'AsyncHttp Error:${message}';
    return message;
  }

  // ==========================================================================================

  @:dox(hide)
  public function new() {
    // One instance every Request.send() to be thread-safe
  }

  // ==========================================================================================


  @:dox(hide)
  public function send(request:HttpRequest) {

    if (request.finalised) {
      error('Unable to send the request:it was already sent before\n' +
        'To send it again you have to clone it before.',
        request.fingerprint, true); // throw error!
      return;
    }

    request.finalise(); // request will not change

#if (neko || cpp || java)

      if (request.async) {
        // Asynchronous (with a new thread)
        var worker = Thread.create(httpViaSocket_Threaded);
        worker.sendMessage(request);
      } else {
        // Synchronous (same thread)
        httpViaSocket(request);
      }

#elseif flash

    // URLLoader version (FLASH)
    httpViaUrlLoader(request);

    #elseif js

    // Standard Haxe HTTP
    httpViaHaxeHttp(request);

#end

  }

  private inline
  function callback(request:HttpRequest, time:Float, url:URL, headers:HttpHeaders, status:Int, content:Bytes, ?error:String = "") {
    headers.finalise(); // makes the headers object immutable
    var response = new HttpResponse(request, time, url, headers, status, content, error);
    if (request.callbackError != null && !response.isOK) {
      request.callbackError(response);
    } else if (request.callback != null) {
      request.callback(response);
    }
    response = null;
  }

  private inline
  function callbackProgress(request:HttpRequest, loaded:Int, total:Int):Void {
    if (request.callbackProgress != null) request.callbackProgress(loaded, total);
  }

#if (neko || cpp || java)

  // ==========================================================================================
  // Multi-thread version for neko, CPP + JAVA

    private function httpViaSocket_Threaded() {
    var request:HttpRequest = null;
    try {
      request = Thread.readMessage(true);
      httpViaSocket(request);
    } catch (error:String) {
      // very unlikely it will fall in this case
      // (just to be safe and don't let the sub thread crash the whole application)
      callback(request, 0.0, request.url, new HttpHeaders(), 0, null, error);
    }
  }

  // Open a socket, send a request and get the headers
  // (could be called more than once in case of redirects)
  private function httpViaSocketConnect(url:URL, request:HttpRequest):Requester {

    var errorMessage:String = '';
    var headers = new HttpHeaders();
    var status:Int = 0;

    var s:AbstractSocket;
    if (url.isSsl) {
      s = new SocketSSL();
#if (!python && !neko && !java && !macro && !cpp && !lua && !php)
      error('Requested HTTPS but no SSL support (fallback on HTTP)', request.fingerprint);
#end
    } else {
      s = new SocketTCP();
    }

    // -- START REQUEST

    var connected = false;
    log('Request\n> ${request.method} ${url}',
      request.fingerprint);
    try {
      s.setTimeout(request.timeout);
#if flash
      s.connect(url.host, url.port);
#else
      s.connect(new Host(url.host), url.port);
#end
      connected = true;
    } catch (msg:Dynamic) {
      errorMessage = error('Request failed -> $msg', request.fingerprint);
    }

    if (connected) {

      var httpVersion = "1.1";
      if (!request.http11) httpVersion = "1.0";

      try {
        s.output.writeString('${request.method} ${url.resource}${url.querystring} HTTP/$httpVersion\r\n');
        log('HTTP > ${request.method} ${url.resource}${url.querystring} HTTP/$httpVersion', request.fingerprint);
        s.output.writeString('User-Agent:$userAgent\r\n');
        log('HTTP > User-Agent:$userAgent', request.fingerprint);
        s.output.writeString('Host:${url.host}\r\n');
        log('HTTP > Host:${url.host}', request.fingerprint);
        if (request.http11) {
          // tell the server we want to close the connection after the request
          s.output.writeString('Connection: close\r\n');
        }

        if (request.headers != null) {
          //custom headers
          for (key in request.headers.keys()) {
            var value = request.headers.get(key);
            if (HttpHeaders.validateRequest(key)) {
              s.output.writeString('$key:$value\r\n');
              log('HTTP > $key:$value', request.fingerprint);
            }
          }
        }

        if (request.content != null) {
          s.output.writeString('Content-Type:${request.contentType}\r\n');
          log('HTTP > Content-Type:${request.contentType}', request.fingerprint);
          s.output.writeString('Content-Length:' + request.content.length + '\r\n');
          log('HTTP > Content-Length:' + request.content.length, request.fingerprint);
          s.output.writeString('\r\n');
          if (request.contentIsBinary) {
            s.output.writeBytes(cast(request.content, Bytes), 0, request.content.length);
          } else {
            s.output.writeString(request.content.toString());
          }
        }
        s.output.writeString('\r\n');
      } catch (msg:Dynamic) {
        errorMessage = error('Request failed -> $msg', request.fingerprint);
        status = 0;
        s.close();
        s = null;
        headers = new HttpHeaders();
        connected = false;
      }

    } // -- END REQUEST

    // -- START RESPONSE
    if (connected) {
      var ln:String = '';
      while (true) {
        try {
          ln = s.input.readLine().trim();
        } catch (msg:Dynamic) {
          // error (probably unexpected connection terminated)
          errorMessage = error('Transfer failed -> $msg', request.fingerprint);
          ln = '';
          status = 0;
          s.close();
          s = null;
          headers = new HttpHeaders();
          connected = false;
        }
        if (ln == '') break; //end of response headers

        if (status == 0) {
          var r = ~/^HTTP\/\d+\.\d+ (\d+)/;
          r.match(ln);
          status = Std.parseInt(r.matched(1));
        } else {
          var a = ln.split(':');
          var key = a.shift().toLowerCase();
          headers.add(key, a.join(':').trim());
        }
      }
      // -- END RESPONSE HEADERS
    }

    return {
      status:status,
      socket:s,
      headers:headers,
      errorMessage:errorMessage
    };
  }

  // Ask httpViaSocketConnect to open a socket and send the request
  // then parse the response and handle it to the callback
  private function httpViaSocket(request:HttpRequest) {
    if (request == null) return;

    var start = Timer.stamp();

    // RESPONSE
    var url:URL = request.url;
    var content:Dynamic = null;
    var contentLength:Int = 0;
    var errorMessage:String = '';

    var connected:Bool = false;
    var redirect:Bool = false;

    var s:AbstractSocket;
    var headers = new HttpHeaders();
    var status:Int = 0;

    // redirects url list to avoid loops
    var redirectChain = new Array<String>();
    redirectChain.push(url.toString());

    do {
      var req:Requester = httpViaSocketConnect(url, request);
      status = req.status;
      s = req.socket;
      headers = req.headers;
      errorMessage = req.errorMessage;
      req = null;

      connected = (status != 0);
      redirect = false;

      if (connected) {
        redirect = (status == 301 || status == 302 || status == 303 || status == 307);
        // determine if redirection
        if (redirect) {
          var newlocation = headers.get('location');
          if (newlocation != "") {
            var newURL = new URL(newlocation);
            newURL.merge(url);
            if (redirectChain.length <= maxRedirections && redirectChain.indexOf(newURL.toString()) == -1) {
              url = newURL;
              redirectChain.push(url.toString());
              log('Redirect $status -> ${url}', request.fingerprint);
              s.close();
              s = null;
            } else {
              // redirect loop
              redirect = false;
              s.close();
              s = null;
              connected = false;
              if (redirectChain.length > maxRedirections) {
                errorMessage = error('Too many redirection (Max $maxRedirections)\n' + redirectChain.join('-->'), request.fingerprint);
              } else {
                errorMessage = error('Redirection loop\n' + redirectChain.join('-->') + '-->' + redirectChain[0], request.fingerprint);
              }
            }
          }
        }
      }
    } while (redirect);

    if (connected) {

      // -- START RESPONSE CONTENT

      // determine content properties
      contentLength = Std.parseInt(headers.get('content-length'));

      // determine transfer mode
      var mode:HttpTransferMode = HttpTransferMode.NO_CONTENT;
      if (contentLength > 0)
        mode = HttpTransferMode.FIXED;
      else if(status < 400)
        mode = HttpTransferMode.UNDEFINED;
      if (headers.get('transfer-encoding') == 'chunked') mode = HttpTransferMode.CHUNKED;
      log('Transfer mode -> $mode', request.fingerprint);

      var bytes_loaded:Int = 0;
      var contentBytes:Bytes = null;
      this.callbackProgress(request, 0, -1);

      switch (mode) {
        case HttpTransferMode.UNDEFINED:
          // UNKNOWN CONTENT LENGTH
          try {
            contentBytes = s.input.readAll();
          } catch (msg:Dynamic) {
            errorMessage = error('Transfer failed -> $msg', request.fingerprint);
            status = 0;
            contentBytes = Bytes.alloc(0);
          }
          contentLength = contentBytes.length;
          this.callbackProgress(request, contentLength, contentLength);
          log('Loaded $contentLength/$contentLength bytes (100%)', request.fingerprint);

        case HttpTransferMode.FIXED:

          // KNOWN CONTENT LENGTH

          contentBytes = Bytes.alloc(contentLength);
          var block_len = 1024 * 1024; // BLOCK SIZE:small value (like 64 KB) causes slow download
          var nblocks = Math.ceil(contentLength / block_len);
          var bytes_left = contentLength;
          bytes_loaded = 0;

          for (i in 0...nblocks) {
            var actual_block_len = (bytes_left > block_len)?block_len:bytes_left;
            try {
              s.input.readFullBytes(contentBytes, bytes_loaded, actual_block_len);
            } catch (msg:Dynamic) {
              errorMessage = error('Transfer failed -> $msg', request.fingerprint);
              status = 0;
              contentBytes = Bytes.alloc(0);
              break;
            }
            bytes_left -= actual_block_len;

            bytes_loaded += actual_block_len;
            this.callbackProgress(request, bytes_loaded, contentLength);
            log('Loaded $bytes_loaded/$contentLength bytes (' + Math.round(bytes_loaded / contentLength * 1000) / 10 + '%)', request.fingerprint);
          }

        case HttpTransferMode.CHUNKED:

          // CHUNKED MODE

          var bytes:Bytes;
          var buffer = new haxe.io.BytesBuffer();
          var chunk:Int;
          try {
            while (true) {
              var v:String = s.input.readLine();
              chunk = Std.parseInt('0x$v');
              if (chunk == 0) break;
              bytes = s.input.read(chunk);
              bytes_loaded += chunk;
              buffer.add(bytes);
              s.input.read(2); // \n\r between chunks = 2 bytes
              this.callbackProgress(request, bytes_loaded, -1);
              log('Loaded $bytes_loaded bytes (Total unknown)', request.fingerprint);
            }
          } catch (msg:Dynamic) {
            errorMessage = error('Transfer failed -> $msg', request.fingerprint);
            status = 0;
            buffer = new haxe.io.BytesBuffer();
          }

          contentBytes = buffer.getBytes();
          contentLength = bytes_loaded;

          buffer = null;
          bytes = null;

        case HttpTransferMode.NO_CONTENT:
          errorMessage = error('Transfer failed -> No content');
      }

      // The response content is always given in bytes and handled by the HttpResponse object
      content = contentBytes;
      contentBytes = null;

      // -- END RESPONSE

    }

    if (s != null) {
      if (connected) s.close();
      s = null;
    }

    var time:Float = elapsedTime(start);

    log('Response $status ($contentLength bytes in $time s)\n> ${request.method} $url', request.fingerprint);
    this.callback(request, time, url, headers, status, content, errorMessage);
  }

#elseif flash

  // ==========================================================================================
  // URLLoader version (FLASH)

  // Convert from the Flash format
  private function convertFromFlashHeaders(urlLoaderHeaders:Array<Dynamic>):HttpHeaders {
    var headers = new HttpHeaders();
    if (urlLoaderHeaders != null) {
      for (el in urlLoaderHeaders) {
        headers.add(el.name.trim().toLowerCase(), el.value);
      }
    }
    headers.finalise(); // makes the headers object immutable
    return headers;
  }

  private function convertToFlashHeaders(httpHeaders:HttpHeaders):Array<Dynamic>{
    var headers = new Array<URLRequestHeader>();
    if (httpHeaders != null) {
      for (key in httpHeaders.keys()) {
        var value = httpHeaders.get(key);
        if (HttpHeaders.validateRequest(key)) {
          headers.push(new URLRequestHeader(key, value));
        }
      }
    }
    return headers;
  }

  private function httpViaUrlLoader(request:HttpRequest) {
    if (request == null) return;

    var urlLoader:URLLoader = new URLLoader();
    var start = Timer.stamp();

    // RESPONSE FIELDS
    var url:URL = request.url;
    var status:Int = 0;
    var headers = new HttpHeaders();
    var content:Bytes = null;

    urlLoader.dataFormat = URLLoaderDataFormat.BINARY; //(contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);

    log('Request\n> ${request.method} ${request.url}', request.fingerprint);
    var urlRequest = new URLRequest(request.url.toString());
    urlRequest.method = request.method;
    if (request.content != null && request.method != HttpMethod.GET) {
      urlRequest.data = request.content;
      urlRequest.contentType = request.contentType;
      //urlRequest.dataFormat = (request.contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
    }

    // if (request.headers!=null) { // TODO check if supported (it looks only on POST and limited)
    // 	// custom headers
    // 	urlRequest.requestHeaders = convertToFlashHeaders(request.headers);
    // }

    var httpstatusDone = false;

    urlLoader.addEventListener("httpStatus", function(e:HTTPStatusEvent) {
      status = e.status;
      log('Response HTTP_Status $status', request.fingerprint);
      //content = null; // content will be retrive in EVENT.COMPLETE
      //urlLoader.dataFormat = URLLoaderDataFormat.BINARY;//(contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
      httpstatusDone = true; //flash does not call this event
    });

    urlLoader.addEventListener("httpResponseStatus", function(e:HTTPStatusEvent) {
      var newUrl:URL = new URL(e.responseURL);
      newUrl.merge(request.url);
      url = newUrl;
      status = e.status;
      log('Response HTTP_Response_Status $status', request.fingerprint);
      try {
        headers = convertFromFlashHeaders(e.responseHeaders);
      } catch (e:Dynamic) {}
      //content = null; // content will be retrive in EVENT.COMPLETE

      //urlLoader.dataFormat = URLLoaderDataFormat.BINARY;(contentIsBinary?URLLoaderDataFormat.BINARY:URLLoaderDataFormat.TEXT);
      httpstatusDone = true; //flash does not call this event
    });

    urlLoader.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
      var time = elapsedTime(start);
      status = e.errorID;
      var errorMessage = error('Response Error ' + e.errorID + ' ($time s)\n> ${request.method} ${request.url}', request.fingerprint);
      this.callback(request, time, url, headers, status, content, errorMessage);
      urlLoader = null;
    });

    urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, function(e:SecurityErrorEvent) {
      var time = elapsedTime(start);
      status = 0;
      var errorMessage = error('Response Security Error ($time s)\n> ${request.method} ${request.url}', request.fingerprint);
      this.callback(request, time, url, headers, status, content, errorMessage);
      urlLoader = null;
    });

    urlLoader.addEventListener(Event.COMPLETE, function(e:Event) {
      if (!httpstatusDone) status = 200;

      var time = elapsedTime(start);
      content = Bytes.ofString(e.target.data);
      log('Response Complete $status ($time s)\n> ${request.method} ${request.url}', request.fingerprint);
      this.callback(request, time, url, headers, status, content);
      urlLoader = null;
    });

    try {
      urlLoader.load(urlRequest);
    } catch (msg:Dynamic) {
      var time = elapsedTime(start);
      var errorMessage = error('Request failed -> $msg', request.fingerprint);
      this.callback(request, time, url, headers, status, content, errorMessage);
      urlLoader = null;
    }
  }

#elseif js

  private function httpViaHaxeHttp(request:HttpRequest) {
    if (request == null) return;
    var start = Timer.stamp();

    // RESPONSE FIELDS
    var url:URL = request.url;
    var status:Int = 0;
    var headers = new HttpHeaders(); //no headers got on haxe.Http (so we make it empty to be coherent)
    var content:Bytes = null;

    var r = new haxe.Http(url.toString());
    r.async = request.async;
    //r.setHeader("User-Agent",userAgent); //TODO disabled because it gives a warning in Chrome
    if (request.content != null) {
      r.setPostData(Std.string(request.content));
    }

    var httpstatusDone = false;

    r.onError = function(msg:String) {
      var errorMessage = error('Request failed -> $msg', request.fingerprint);
      var time = elapsedTime(start);
      this.callback(request, time, url, headers, status, content, errorMessage);
    };

    r.onData = function(data:String) {
      if (!httpstatusDone) status = 200; // see onStatus below
      var time = elapsedTime(start);
      content = Bytes.ofString(data);
      log('Response Complete $status ($time s)\n> ${request.method} ${request.url}', request.fingerprint);
      this.callback(request, time, url, headers, status, content);
    };

    r.onStatus = function(http_status:Int) {
      status = http_status;
      log('Response HTTP Status $status', request.fingerprint);
      httpstatusDone = true; // it could not be called (so it will be set on 200 in onData if no onStatus)
    }

    r.request(request.content != null);
  }

#end

  // ==========================================================================================

  private function elapsedTime(start:Float):Float {
    return Std.int((Timer.stamp() - start) * 1000) / 1000;
  }

  // ==========================================================================================

  @:dox(hide)
#if js
  public static inline var DEFAULT_CONTENT_TYPE = "text/plain";
#else
  public static inline var DEFAULT_CONTENT_TYPE = "application/octet-stream";
#end

  @:dox(hide)
  public static inline var DEFAULT_FILENAME = "unknown";

  private static
  var CONTENT_KIND_MATCHES:Array<ContentKindMatch> = [{
      kind:ContentKind.IMAGE,
      regex:~/^image\/(jpe?g|png|gif)/i
    }, {
      kind:ContentKind.XML,
      regex:~/(application\/xml|text\/xml|\+xml)/i
    }, {
      kind:ContentKind.JSON,
      regex:~/^(application\/json|\+json)/i
    }, {
      kind:ContentKind.TEXT,
      regex:~/(^text|application\/javascript)/i
    } //text is the last one
  ];

  // The content kind is used to determine if a content is Binary or Text
  @:dox(hide)
  public static function determineContentKind(contentType:String):ContentKind {
    var contentKind = ContentKind.BYTES;
    for (el in CONTENT_KIND_MATCHES) {
      if (el.regex.match(contentType)) {
        contentKind = el.kind;
        break;
      }
    }
    return contentKind;
  }

  @:dox(hide)
  public static function determineIsBinary(contentKind:ContentKind):Bool {
    if (contentKind == ContentKind.BYTES || contentKind == ContentKind.IMAGE) return true;
    return false;
  }

  // ==========================================================================================

  //##########################################################################################
  // UID Generator
  //##########################################################################################
  private static
  var UID_CHARS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

  @:dox(hide)
  public function randomUID( ?size:Int = 32):String {
    var nchars = UID_CHARS.length;
    var uid = new StringBuf();
    for (i in 0...size) {
      uid.addChar(UID_CHARS.charCodeAt(Std.random(nchars)));
    }
    return uid.toString();
  }

}
