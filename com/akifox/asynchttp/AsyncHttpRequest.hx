package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/

class AsyncHttpRequest
{
	private var _finalised:Bool = false; //it was .sent at least once (no edit allowed)

	// ==========================================================================================

	public function new(?url:String="",?callback:AsyncHttpResponse->Void=null) {
		_fingerprint = new AsyncHttp().randomUID(8);
		this.url = url;
		this.callback = callback;
	}

	public function toString():String {
		return '[AsyncHttpRequest <$_fingerprint> ($_method $_url)]';
	}

	// ------------------------------------------------------------------------------------------

	public function send() {
		new AsyncHttp().send(this);
	}

	public function finalize() {
		_finalised = true; // it will not change
	}

	// ==========================================================================================

  /*
	* ------------------------------------------------------------------------------------------
	* The fingerprint is a unique 8 char key which identify this request
	*/
	private var _fingerprint:String;
	public var fingerprint(get,never):String;
	private function get_fingerprint():String {
		return _fingerprint;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The timeout in seconds
	*/
	private var _timeout:Int=10; //default 10 seconds
	public var timeout(get,set):Int;
	private function get_timeout():Int {
		return _timeout;
	}
	private function set_timeout(value:Int):Int {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.timeout] Can\'t modify a property when the instance is already sent');
			return _timeout;
		}
		return _timeout = value;
	}

  /*
	* ------------------------------------------------------------------------------------------
	* The HTTP URL
	* complete format: http://host:port/path?querystring
	*/
	private var _url:String;
	public var url(get,set):String;
	private function get_url():String {
		return _url;
	}
	private function set_url(value:String):String {
		#if (!js && !flash)
		if (!new AsyncHttp().REGEX_URL.match(value))
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: Not a valid url "$value"');
		#end
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.url] Can\'t modify a property when the instance is already sent');
			return _url;
		}
		return _url = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The HTTP Method
	* accepted values AsyncHttpMethod.GET, .POST, .PUT, .DELETE
	*/
	private var _method:String=AsyncHttpMethod.DEFAULT_METHOD;
	public var method(get,set):String;
	private function get_method():String {
		return _method;
	}
	private function set_method(value:String):String {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.method] Can\'t modify a property when the instance is already sent');
			return _method;
		}
		value = AsyncHttpMethod.validate(value);
		return _method = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The HTTP Content
	* Dynamic: could be a Bytes or a String, according to the Content-type
	*/
	private var _content:Dynamic=null;
	public var content(get,set):Dynamic;
	private function get_content():Dynamic {
		return _content;
	}
	private function set_content(value:Dynamic):Dynamic {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.content] Can\'t modify a property when the instance is already sent');
			return _content;
		}
		return _content = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The HTTP Content-Type
	* String: http://www.iana.org/assignments/media-types/media-types.xhtml
	*/
	private static inline var DEFAULT_CONTENT_TYPE:String = "application/x-www-form-urlencoded";
	private var _contentType:String=DEFAULT_CONTENT_TYPE;
	public var contentType(get,set):String;
	private function get_contentType():String {
		return _contentType;
	}
	private function set_contentType(value:String):String {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.contentType] Can\'t modify a property when the instance is already sent');
			return _contentType;
		}
		// default content type
		if (value==null) value = DEFAULT_CONTENT_TYPE;
		var ahttp = new AsyncHttp();
		_contentIsBinary = ahttp.determineBinary(ahttp.determineContentKind(value));
		return _contentType = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* Is the content binary data?
	*/
	private var _contentIsBinary:Bool=false;
	public var contentIsBinary(get,set):Bool;
	private function get_contentIsBinary():Bool {
		return _contentIsBinary;
	}
	private function set_contentIsBinary(value:Bool):Bool {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.contentIsBinary] Can\'t modify a property when the instance is already sent');
			return _contentIsBinary;
		}
		return _contentIsBinary = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The callback function to be called when the response returns
	*/
	private var _callback:AsyncHttpResponse->Void=null;
	public var callback(get,set):AsyncHttpResponse->Void;
	private function get_callback():AsyncHttpResponse->Void {
		return _callback;
	}
	private function set_callback(value:AsyncHttpResponse->Void):AsyncHttpResponse->Void {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.callback] Can\'t modify a property when the instance is already sent');
			return _callback;
		}
		return _callback = value;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The response will be parsed and the content will be an Object (Json => Anon Structure, XML => Class Xml)
	*/
	private var _autoParse:Bool=false;
	public var autoParse(get,set):Bool;
	private function get_autoParse():Bool {
		return _autoParse;
	}
	private function set_autoParse(value:Bool):Bool {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.autoParse] Can\'t modify a property when the instance is already sent');
			return _autoParse;
		}
		return _autoParse = value;
	}

}
