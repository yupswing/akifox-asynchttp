package com.akifox.asynchttp;
import com.akifox.asynchttp.AsyncHttp;
import haxe.io.Bytes;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence

You don't need to use this class!
It is the Response Class that will be passed to a request callback
**/


import haxe.Json;

class HttpResponse {

	// ==========================================================================================

	public function new(request:HttpRequest, // the original request
											time:Float,					 // the response time
											url:URL,						 // the final url retrived (could be different from request.url because redirects)
											headers:HttpHeaders, // the response headers
											status:Int,					 // the response status (0 if error otherwise HTTP standard response code)
											content:Bytes 			 // the response content
										 ) {

		_request = request;
		_time = time;

		_url = url;
		_status = status;
		_isOK = (_status >= 200 && _status < 400);
		_headers = headers;

		// set content type
		if (_headers.exists('content-type')) _contentType = _headers.get('content-type');
		else _contentType = AsyncHttp.DEFAULT_CONTENT_TYPE;

		// content properties
		_contentKind = AsyncHttp.determineContentKind(_contentType);
		_contentIsBinary = AsyncHttp.determineIsBinary(_contentKind);

		_contentRaw = content;
		if (!_contentIsBinary) _content = toText();
		else _content = _contentRaw;

		//set content length
		_contentLength = 0;
		if (_headers.exists('content-length')) {
			_contentLength = Std.parseInt(_headers.get('content-length'));
		}
		else if (content != null) {
			_contentLength = _content.length; //works on Bytes and String
		}

	}

	// ==========================================================================================

	public function toString():String {
		return '[HttpResponse <$_fingerprint> (isOK $_isOK, status $_status, $_contentLength bytes in $_time sec)]';
	}

	// ==========================================================================================
	// PARSING

	public var isBinary(get,never):Bool;
	private function get_isBinary():Bool {
		return _contentIsBinary;
	}
	public var isText(get,never):Bool;
	private function get_isText():Bool {
		return !_contentIsBinary;
	}
	public var isXml(get,never):Bool;
	private function get_isXml():Bool { return (_contentKind==ContentKind.XML); }
	public var isJson(get,never):Bool;
	private function get_isJson():Bool { return (_contentKind==ContentKind.JSON); }
	public var isImage(get,never):Bool;
	private function get_isImage():Bool { return (_contentKind==ContentKind.IMAGE); }

	// ------------------------------------------------------------------------------------------

	public function toXml():Xml {
		var _contentXml:Dynamic = null;
		try {
			_contentXml = Xml.parse(toText());
		} catch( msg : Dynamic ) {
			AsyncHttp.error('HttpResponse $_fingerprint ERROR: parse Xml -> $msg');
		}
		return _contentXml;
	}

	public function toJson():Dynamic {
		var _contentJson:Dynamic = null;
		try {
			_contentJson = haxe.Json.parse(toText());
		} catch( msg : Dynamic ) {
			AsyncHttp.error('HttpResponse $_fingerprint ERROR: parse Json -> $msg');
		}
		return _contentJson;
	}

	public function toText():String {
		var _contentText:String = null;
		try {
			_contentText = Std.string(_contentRaw);
		} catch( msg : Dynamic ) {
			AsyncHttp.error('HttpResponse $_fingerprint ERROR: parse Text -> $msg');
		}
		return _contentText;
	}

	#if (openfl && !flash && !js) //TODO support for flash and js

	public function toBitmapData():openfl.display.BitmapData {
		var _contentBitmapData:openfl.display.BitmapData = null;

		// FLASH VERSION (Loader is Async)
		// var loader = new openfl.display.Loader();
		// var loaded:Bool = false;
		// loader.contentLoaderInfo.addEventListener(openfl.events.Event.COMPLETE,function(e:openfl.events.Event) {
		// 	trace(loader.content);
		// 	_contentBitmapData = cast(loader.content, openfl.display.Bitmap).bitmapData.clone();
		// 	loaded = true;
		// });
		// loader.contentLoaderInfo.addEventListener(openfl.events.IOErrorEvent.IO_ERROR, function(e:openfl.events.IOErrorEvent) {
		// 	trace(e.errorID);
		// 	loaded = true;
		// });
		// loader.loadBytes(_content);
		// while(!loaded) {
		// 	trace(haxe.Timer.stamp());
		// }

		// OPENFL VERSION (Loader is Sync)
		try {
			// convert from Bytes to ByteArray
			var bytearray = new openfl.utils.ByteArray();
			bytearray.writeUTFBytes(_contentRaw.toString());
			#if (legacy || v2)
			_contentBitmapData = openfl.display.BitmapData.loadFromBytes(bytearray);
			#else
			_contentBitmapData = openfl.display.BitmapData.fromBytes(bytearray);
			#end
		} catch( msg : Dynamic ) {
			AsyncHttp.error('HttpResponse $_fingerprint ERROR: parse Image -> $msg');
		}
		return _contentBitmapData;
	}

	#end

	// ==========================================================================================

	private var _contentKind:ContentKind;

	private var _request:HttpRequest;
	public var request(get,never):HttpRequest;
	private function get_request():HttpRequest {
		return _request;
	}

	private var _fingerprint:String;
	public var fingerprint(get,never):String;
	private function get_fingerprint():String {
		return _request.fingerprint;
	}

	private var _url:URL;
	public var url(get,never):URL;
	private function get_url():URL {
		return _url;
	}

	public var urlString(get,never):String;
	private function get_urlString():String {
		return _url.toString();
	}

	private var _headers:HttpHeaders;
	public var headers(get,never):HttpHeaders;
	private function get_headers():HttpHeaders {
		return _headers;
	}

	private var _status:Int;
	public var status(get,never):Int;
	private function get_status():Int {
		return _status;
	}

	private var _content:Dynamic;
	public var content(get,never):Dynamic;
	private function get_content():Dynamic {
		return _content;
	}

	private var _contentRaw:Bytes;
	public var contentRaw(get,never):Bytes;
	private function get_contentRaw():Bytes {
		return _contentRaw;
	}

	private var _contentType:String;
	public var contentType(get,never):String;
	private function get_contentType():String {
		return _contentType;
	}

	private var _contentIsBinary:Bool;
	public var contentIsBinary(get,never):Bool;
	private function get_contentIsBinary():Bool {
		return _contentIsBinary;
	}

	private var _contentLength:Int;
	public var contentLength(get,never):Int;
	private function get_contentLength():Int {
		return _contentLength;
	}

	private var _time:Float;
	public var time(get,never):Float;
	private function get_time():Float {
		return _time;
	}

	private var _filename:String=null;
	public var filename(get,never):String;
	private function get_filename():String {
		if (_filename==null) {
			var filename:String = "";
			var rx = ~/([^?\/]*)($|\?.*)/;
			if (rx.match(_url.toString())) {
				filename = rx.matched(1);
			}
			if (filename=="") filename = AsyncHttp.DEFAULT_FILENAME;
			_filename = filename;
		}
		return _filename;
	}

	private var _isOK:Bool;
	public var isOK(get,never):Bool;
	private function get_isOK():Bool {
		return _isOK;
	}

	// ==========================================================================================

}
