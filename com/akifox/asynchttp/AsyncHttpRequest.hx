package com.akifox.asynchttp;
import com.akifox.asynchttp.AsyncHttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/

typedef AsyncHttpRequestOptions = {
		//? fingerprint : String,
    ? async: Bool,
    ? url: Dynamic,
    ? callback: AsyncHttpResponse->Void,
		? headers : AsyncHttpHeaders,
		? timeout : Int,
		? method: String,
		? content: Dynamic,
		? contentType: String,
		? contentIsBinary: Bool
}

class AsyncHttpRequest
{
	private var _finalised:Bool = false; //it was .sent at least once (no edit allowed)

	// ==========================================================================================

	public function new(?options:AsyncHttpRequestOptions=null) {
		_fingerprint = new AsyncHttp().randomUID(8);

		if(options != null) {
			if(options.async != null)						async = options.async;
			if(options.url != null)							url = options.url;
			if(options.callback != null)				callback = options.callback;
			if(options.headers != null)					_headers = options.headers;
			if(options.timeout != null)					timeout = options.timeout;
			if(options.method != null)					method = options.method;
			if(options.content != null)					content = options.content;
			if(options.contentType != null)			contentType = options.contentType;
			if(options.contentIsBinary != null)	contentIsBinary = options.contentIsBinary;
		}
	}

	public function toString():String {
		return '[AsyncHttpRequest <$_fingerprint> ($_method $_url)]';
	}

	// ------------------------------------------------------------------------------------------

	public function clone():AsyncHttpRequest {
		return new AsyncHttpRequest({
			async : this._async,
			url : this._url,
			callback : this._callback,
			headers : this._headers,
			timeout : this._timeout,
			method : this._method,
			content : this._content,
			contentType : this._contentType,
			contentIsBinary : this._contentIsBinary
		});
	}

	public function send() {
		new AsyncHttp().send(this);
	}

	public function finalise() {
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
	* Request headers
	*/
	private var _headers:AsyncHttpHeaders;
	public var headers(get,never):AsyncHttpHeaders;
	private function get_headers():AsyncHttpHeaders {
		return _headers;
	}
	public function addHeader(header:String,value:String):AsyncHttpRequest {
		_headers[header] = value;
		return this;
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
		if (value<1) value = 1;
		return _timeout = value;
	}

  /*
	* ------------------------------------------------------------------------------------------
	* Asynchronous
	*/
	private var _async:Bool=true;
	public var async(get,set):Bool;
	private function get_async():Bool {
		return _async;
	}
	private function set_async(value:Bool):Bool {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.async] Can\'t modify a property when the instance is already sent');
			return _async;
		}
		return _async = value;
	}

  /*
	* ------------------------------------------------------------------------------------------
	* The URL
	* complete format: http://host:port/path?querystring
	*/
	private var _url:URL = null;
	public var url(get,set):URL;
	private function get_url():URL {
		return _url;
	}
	private function set_url(value:Dynamic):URL {

    var v:URL = null;
    switch(Type.getClassName(Type.getClass(value))) {
      case 'String':
        v = new URL(value);
      case 'URL':
        v = value.clone();
      default:
  			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.url] Please specify an URL Object or a String');
  			return _url;
    }

		#if (!js && !flash) //TODO check URL
      if (v.relative || !v.http) {
        AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.url] `$value` is not a valid HTTP URL');
      }
		#end

		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.url] Can\'t modify a property when the instance is already sent');
			return _url;
		}
		return _url = v;
	}

   /*
	* ------------------------------------------------------------------------------------------
	* The HTTP Method
	* accepted values HttpMethod.GET, .POST, .PUT, .DELETE
	*/
	private var _method:String=HttpMethod.DEFAULT_METHOD;
	public var method(get,set):String;
	private function get_method():String {
		return _method;
	}
	private function set_method(value:String):String {
		if (_finalised) {
			AsyncHttp.error('AsyncHttpRequest $_fingerprint ERROR: [.method] Can\'t modify a property when the instance is already sent');
			return _method;
		}
		value = HttpMethod.validate(value);
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

}
