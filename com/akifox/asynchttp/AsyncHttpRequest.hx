package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/

class AsyncHttpRequest
{

	private var _fingerprint:String;
	public var fingerprint(get,never):String;
	private function get_fingerprint():String {
		return _fingerprint;
	}

	private var _url:String;
	public var url(get,never):String;
	private function get_url():String {
		return _url;
	}

	private var _method:String;
	public var method(get,never):String;
	private function get_method():String {
		return _method;
	}

	private var _content:String;
	public var content(get,never):String;
	private function get_content():String {
		return _content;
	}

	private var _contentType:String;
	public var contentType(get,never):String;
	private function get_contentType():String {
		return _contentType;
	}

	private var _responseF:AsyncHttpResponse->Void;
	public var responseF(get,never):AsyncHttpResponse->Void;
	private function get_responseF():AsyncHttpResponse->Void {
		return _responseF;
	}

	private static var _methods = ["GET","POST","PUT","DELETE"];

	public function new(url:String,method:String="GET",?content:String=null,?contentType:String=null,?responseF:AsyncHttpResponse->Void=null) {
		// default content type
		if (contentType==null) contentType = "application/x-www-form-urlencoded";
		// validate method
		method = method.toUpperCase();
		if (_methods.indexOf(method)<0) method = "GET";

		_fingerprint = AsyncHttp.randomUID(8);
		_url = url;
		_method = method;
		_content = content;
		_contentType = contentType;
		_responseF = responseF;
	}

	public function toString():String {
		return '[AsyncHttpRequest <$_fingerprint> ($_method $_url)]';
	}

	public function send() {
		AsyncHttp.send(this);
	}

}