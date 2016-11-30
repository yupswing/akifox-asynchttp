package com.akifox.asynchttp;
import com.akifox.asynchttp.AsyncHttp;

/**
##HttpRequestOptions

This object is used to pass parameters to an HttpRequest class instance

(All the parameter are directly connected to the HttpRequest properties

**Check the HttpRequest documentation to have more information on every parameter**)

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@licence MIT Licence
**/
typedef HttpRequestOptions = {
  //?fingerprint:String,
  ?async:Bool,
  ?http11:Bool,
  ?url:Dynamic,
  ?callback:HttpResponse->Void,
  ?callbackProgress:Int->Int->Void,
  ?callbackError:HttpResponse->Void,
  ?headers:HttpHeaders,
  ?timeout:Int,
  ?method:String,
  ?content:Dynamic,
  ?contentType:String,
  ?contentIsBinary:Bool
}

/**
##HttpRequest

This class represents an Http Request

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@licence MIT Licence
**/
class HttpRequest {

  /**
   * Tell if the instance is immutable
   *
   * **NOTE:** The only way to change an immutable instance is copying it (`instance.clone()`) and change the copy
   **/
  public var finalised(get, never):Bool;
  private var _finalised:Bool = false; //it was .sent at least once (no edit allowed)
  private function get_finalised():Bool {
    return _finalised;
  }

  // ==========================================================================================

  /**
   * Class instance
   *
   * @param options  HttpRequestOptions object or null (**NOTE:** every parameter could be changed also after the class instance)
   **/
  public function new(?options:HttpRequestOptions = null) {
    _fingerprint = new AsyncHttp().randomUID(8); //make a random fingerprint to make this request unique

    if (options != null) {
      if (options.async != null) async = options.async;
      if (options.http11 != null) http11 = options.http11;
      if (options.url != null) url = options.url;
      if (options.callback != null) callback = options.callback;
      if (options.callbackProgress != null) callbackProgress = options.callbackProgress;
      if (options.callbackError != null) callbackError = options.callbackError;
      if (options.headers != null) _headers = options.headers.clone(); // get a mutable copy of the headers
      if (options.timeout != null) timeout = options.timeout;
      if (options.method != null) method = options.method;
      if (options.content != null) content = options.content;
      if (options.contentType != null) contentType = options.contentType;
      if (options.contentIsBinary != null) contentIsBinary = options.contentIsBinary;
    }
  }

  /**
   * @returns   Debug representation of the HttpRequest instance
   **/
  public function toString():String {
    return '[HttpRequest <$_fingerprint> ($_method $_url)]';
  }

  /**
   * Deep copy of the HttpRequest
   *
   * **NOTE:** The copy will be always mutable despite of the master status
   *
   * @returns   A new HttpRequest
   **/
  public function clone():HttpRequest {
    return new HttpRequest({
      async:this._async,
      http11:this._http11,
      url:this._url,
      callback:this._callback,
      callbackProgress:this._callbackProgress,
      headers:this._headers,
      timeout:this._timeout,
      method:this._method,
      content:this._content,
      contentType:this._contentType,
      contentIsBinary:this._contentIsBinary
    });
  }

  /**
   * Make this instance immutable
   *
   * **NOTE:** This method is called automatically once this HttpRequest instance is sent
   **/
  public function finalise() {
    _headers.finalise(); // makes the headers object immutable
    _finalised = true; // it will not change
  }

  // ==========================================================================================


  /**
   * Send the request and call the callback when it is done
   *
   * **NOTE:** When `async==true` the application execution will be hold until the request is completed
   *
   * **NOTE:** When a HttpRequest is sent the instance is made immutable (you have to clone it to send again the same request)
   **/
  public function send() {
    new AsyncHttp().send(this);
  }

  // ==========================================================================================

  /**
   * The fingerprint is a unique 8 char key which identify this request instance
   **/
  public var fingerprint(get, never):String;
  private var _fingerprint:String;
  private function get_fingerprint():String {
    return _fingerprint;
  }

  /**
   * The request headers
   **/
  public var headers(get, never):HttpHeaders;
  private var _headers:HttpHeaders = new HttpHeaders();
  private function get_headers():HttpHeaders {
    return _headers;
  }
  private function set_headers(value:HttpHeaders):HttpHeaders {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.headers -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _headers;
    }
    return _headers = value;
  }

  /**
   * The request timeout in seconds (default:10)
   *
   * If the request receive no answer for more than the timeout it aborts
   **/
  public var timeout(get, set):Int;
  private var _timeout:Int = 10; //default 10 seconds
  private function get_timeout():Int {
    return _timeout;
  }
  private function set_timeout(value:Int):Int {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.timeout -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _timeout;
    }
    if (value < 1) value = 1;
    return _timeout = value;
  }

  /**
   * Asynchronous (default is `true`)
   *
   * **NOTE:** When `async==true` the application execution will be hold until the request is completed
   *
   * **NOTE:** Always true in FLASH due to platform limitations
   **/
  public var async(get, set):Bool;
  private var _async:Bool = true;
  private function get_async():Bool {
    return _async;
  }
  private function set_async(value:Bool):Bool {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.async -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _async;
    }
    return _async = value;
  }

  /**
   * Http Protocol Version flag
   *
   * Tells if enable HTTP/1.1 (true <default>) or HTTP/1.0 (false)
   **/
  public var http11(get, set):Bool;
  private var _http11:Bool = true;
  private function get_http11():Bool {
    return _http11;
  }
  private function set_http11(value:Bool):Bool {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.http11 -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _http11;
    }
    return _http11 = value;
  }

  /**
   * The URL to be retrived
   *
   * Accept a string (format:`protocol://host:port/resource?querystring`) or a URL instance
   *
   * **NOTE:** It supports HTTP+HTTPS protocol (HTTPS on CPP+NEKO platform only with the HXSSL library)
   *
   * **NOTE:** On FLASH and JAVASCRIPT relative URLs are allowed
   **/
  public var url(get, set):URL;
  private var _url:URL = null;
  private function get_url():URL {
    return _url;
  }
  private function set_url(value:Dynamic):URL {
    var v:URL = null;
    switch (Type.getClassName(Type.getClass(value))) {
      case 'String':
        v = new URL(value);
      case 'com.akifox.asynchttp.URL' | 'URL':
        v = value.clone();
      default:
        AsyncHttp.error('HttpRequest.url -> Please specify an URL Object or a String', _fingerprint, true);
        return _url;
    }

#if (!js && !flash)
    if (v.isRelative || !v.isHttp) {
      AsyncHttp.error('HttpRequest.url -> `$value` is not a valid HTTP URL', _fingerprint, true);
    }
#end

    if (_finalised) {
      AsyncHttp.error('HttpRequest.url -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _url;
    }
    return _url = v;
  }

  /**
   * The HTTP Method
   *
   * Accepted values are HttpMethod.GET, .POST, .PUT, .DELETE
   *
   * **NOTE:** On JAVASCRIPT only GET and POST are functional due to platform limitations
   **/
  public var method(get, set):String;
  private var _method:String = HttpMethod.DEFAULT_METHOD;
  private function get_method():String {
    return _method;
  }
  private function set_method(value:String):String {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.method -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _method;
    }
    value = HttpMethod.validate(value);
    return _method = value;
  }

  /**
   * The HTTP Content
   *
   * **NOTE:** You could provide  a Bytes or a String according to the Content-type (Binary or Text)
   **/
  public var content(get, set):Dynamic;
  private var _content:Dynamic = null;
  private function get_content():Dynamic {
    return _content;
  }
  private function set_content(value:Dynamic):Dynamic {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.content -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _content;
    }
    return _content = value;
  }

  /**
   * The HTTP Content-Type (default:`application/x-www-form-urlencoded`)
   *
   * Content-Type list:(http://www.iana.org/assignments/media-types/media-types.xhtml)
   **/
  public var contentType(get, set):String;
  private static inline
  var DEFAULT_CONTENT_TYPE:String = "application/x-www-form-urlencoded";
  private var _contentType:String = DEFAULT_CONTENT_TYPE;
  private function get_contentType():String {
    return _contentType;
  }
  private function set_contentType(value:String):String {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.contentType -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _contentType;
    }
    // default content type
    if (value == null) value = DEFAULT_CONTENT_TYPE;
    _contentIsBinary = AsyncHttp.determineIsBinary(AsyncHttp.determineContentKind(value));
    return _contentType = value;
  }

  /**
   * Content binary flag (tells if the content binary or text)
   *
   * **NOTE:** This is set automatically when a content-type is set
   */
  public var contentIsBinary(get, set):Bool;
  private var _contentIsBinary:Bool = false;
  private function get_contentIsBinary():Bool {
    return _contentIsBinary;
  }
  private function set_contentIsBinary(value:Bool):Bool {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.contentIsBinary -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _contentIsBinary;
    }
    return _contentIsBinary = value;
  }

  /**
   * The callback function to be called when the response returns
   *
   * **NOTE:** This will be called always if no `callbackError` is set
   *
   * Otherwise it will be called only if the response is valid
   **/
  public var callback(get, set):HttpResponse->Void;
  private var _callback:HttpResponse->Void = null;
  private function get_callback():HttpResponse->Void {
    return _callback;
  }
  private function set_callback(value:HttpResponse->Void):HttpResponse->Void {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.callback -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _callback;
    }
    return _callback = value;
  }

  /**
   * The callback error (**optional**) function to be called when the response returns an error
   *
   * **NOTE:** This will be called only if set and in error case
   **/
  public var callbackError(get, set):HttpResponse->Void;
  private var _callbackError:HttpResponse->Void = null;
  private function get_callbackError():HttpResponse->Void {
    return _callbackError;
  }
  private function set_callbackError(value:HttpResponse->Void):HttpResponse->Void {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.callbackError -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _callbackError;
    }
    return _callbackError = value;
  }

  /**
   * The callbackProgress (**optional**) function to be called when get any data on an HTTP Transfer
   * It gets called for sure at the beginning and end of any transfer
   * and (if the HTTP transfer mode supports it) also in between the transfer.
   *
   * The function has to accept two parameters:
   *
   * - loaded:Int  the received bytes
   *
   * - total:Int   the total bytes (-1 if unknown)
   **/
  public var callbackProgress(get, set):Int->Int->Void;
  private var _callbackProgress:Int->Int->Void = null;
  private function get_callbackProgress():Int->Int->Void {
    return _callbackProgress;
  }
  private function set_callbackProgress(value:Int->Int->Void):Int->Int->Void {
    if (_finalised) {
      AsyncHttp.error('HttpRequest.callbackProgress -> Can\'t modify a property when the instance is already sent', _fingerprint, true);
      return _callbackProgress;
    }
    return _callbackProgress = value;
  }

}
