package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


import haxe.Json;


class AsyncHttpResponse {

	private var _fingerprint:String;
	public var fingerprint(get,never):String;
	private function get_fingerprint():String {
		return _fingerprint;
	}

	private var _headers:Map<String,String>;
	public var headers(get,never):Map<String,String>;
	private function get_headers():Map<String,String> {
		return _headers;
	}

	private var _status:Int;
	public var status(get,never):Int;
	private function get_status():Int {
		return _status;
	}

	private var _content:String;
	public var content(get,never):String;
	private function get_content():String {
		return _content;
	}

	private var _contentType:String;
	public var contentType(get,never):String;
	private function get_contentType():String {
		if (_headers.exists('content_type')) {
			return _headers['content_type'];
		} else {
			return "text/plain";
		}
	}

	private var _contentLength:Int;
	public var contentLength(get,never):Int;
	private function get_contentLength():Int {
		return _content.length;
	}

	private var _time:Float;
	public var time(get,never):Float;
	private function get_time():Float {
		return _time;
	}

	public function new(fingerprint:String,headers:Map<String,String>,status:Int,content:String,time:Float) {
		_fingerprint = fingerprint;
		_headers = headers;
		_status = status;
		_content = content;
		_time = time;
	}

	public function toString():String {
		return '[AsyncHttpResponse <$_fingerprint> (status $_status, $_contentLength bytes in $_time sec)]';
	}

	public var contentXml(get,never):Xml;
	private function get_contentXml():Xml {
		var _contentXml:Xml;
		try {
			_contentXml = Xml.parse(_content);
		} catch( msg : String ) {
			AsyncHttp.log('$_fingerprint ERROR: parse Xml -> $msg');
			return null;
		}
		return _contentXml;
	}
	
	public var contentJson(get,never):Dynamic;
	private function get_contentJson():Dynamic {
		var _contentJson:Dynamic;
		try {
			_contentJson = haxe.Json.parse(_content);
		} catch( msg : String ) {
			AsyncHttp.log('$_fingerprint ERROR: parse Json -> $msg');
			return null;
		}
		return _contentJson;
	}
}