package com.akifox.asynchttp;
import com.akifox.asynchttp.AsyncHttp;
import haxe.io.Bytes;
import haxe.Json;

/**
##HttpRequest

This class represents an Http Request

**NOTE:** You don't need to use this class!
It is the HttpResponse object that will be passed to an HttpRequest callback

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@licence MIT Licence
**/

class HttpResponse {

  // ==========================================================================================

  /**
   * Class instance
   *
   * **NOTE:** YOU DON'T NEED TO MAKE AN INSTANCE OF THE RESPONSE, IT IS HANDLED INTERNALLY BY THE LIBRARY
   *
   * The instance is anyway allowed for third party uses of the library
   *
   * @param 	request		original request
   * @param 	time			the response time
   * @param 	url				the final url retrived (could be different from the requested URL because of redirects)
   * @param 	headers		the response headers
   * @param 	status		the response status (0 if error otherwise HTTP standard response code)
   * @param 	content		the response content
   * @param  error     the internal error message (optional)
   **/
  public function new(request:HttpRequest, time:Float, url:URL, headers:HttpHeaders, status:Int, content:Bytes, ?error:String) {

    _request = request;
    _time = time;

    _url = url;
    _status = status;
    _isOK = (_status >= 200 && _status < 400);
    _headers = headers;
    _error = error;
    if (!_isOK && _status != 0) {
      _error = _httpStatus.get(_status);
    }

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
    } else if (content != null) {
      _contentLength = _content.length; //works on Bytes and String
    }

  }

  /**
   * @returns   Debug representation of the HttpResponse instance
   **/
  public function toString():String {
    return '[HttpResponse <${_request.fingerprint}> (isOK=$_isOK, status=$_status, length=$_contentLength bytes in $_time sec), error=$_error]';
  }

  // ==========================================================================================
  // PARSING

  /**
   * Tells if the content is Binary data (based on contentType)
   **/
  public var isBinary(get, never):Bool;
  private function get_isBinary():Bool {
    return _contentIsBinary;
  }
  /**
   * Tells if the content is Text data (based on contentType)
   **/
  public var isText(get, never):Bool;
  private function get_isText():Bool {
    return !_contentIsBinary;
  }

  /**
   * Tells if the content is Xml data (based on contentType)
   **/
  public var isXml(get, never):Bool;
  private function get_isXml():Bool {
    return (_contentKind == ContentKind.XML);
  }

  /**
   * Tells if the content is Json data (based on contentType)
   **/
  public var isJson(get, never):Bool;
  private function get_isJson():Bool {
    return (_contentKind == ContentKind.JSON);
  }

  /**
   * Tells if the content is Image data (based on contentType)
   **/
  public var isImage(get, never):Bool;
  private function get_isImage():Bool {
    return (_contentKind == ContentKind.IMAGE);
  }

  // ------------------------------------------------------------------------------------------

  /**
   * Parse the content as XML
   *
   * @returns an Xml instance
   **/
  public function toXml():Xml {
    var _contentXml:Dynamic = null;
    try {
      _contentXml = Xml.parse(toText());
    } catch (msg:Dynamic) {
      AsyncHttp.error('HttpResponse.toXml() -> $msg', _request.fingerprint);
    }
    return _contentXml;
  }

  /**
   * Parse the content as Json
   *
   * @returns an Anonymous Structure
   **/
  public function toJson():Dynamic {
    var _contentJson:Dynamic = null;
    try {
      _contentJson = haxe.Json.parse(toText());
    } catch (msg:Dynamic) {
      AsyncHttp.error('HttpResponse.toJson() -> $msg', _request.fingerprint);
    }
    return _contentJson;
  }

  /**
   * Gives the content in String format
   *
   * @returns a String
   **/
  public function toText():String {
    var _contentText:String = null;
    try {
      _contentText = Std.string(_contentRaw);
    } catch (msg:Dynamic) {
      AsyncHttp.error('HttpResponse.toText() -> $msg', _request.fingerprint);
    }
    return _contentText;
  }

#if (openfl && !flash && !js) //TODO support for flash and js

  @:dox(hide)
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
      #if (openfl_legacy || v2)
        _contentBitmapData = openfl.display.BitmapData.loadFromBytes(bytearray);
      #else
        _contentBitmapData = openfl.display.BitmapData.fromBytes(bytearray);
      #end
    } catch (msg:Dynamic) {
      AsyncHttp.error('HttpResponse.toBitmapData() -> $msg', _request.fingerprint);
    }
    return _contentBitmapData;
  }

#end

  // ==========================================================================================

  private var _contentKind:ContentKind;

  /**
   * The request
   *
   * **NOTE:** This gives access to the original request (immutable because already sent)
   **/
  public var request(get, never):HttpRequest;
  private var _request:HttpRequest;
  private function get_request():HttpRequest {
    return _request;
  }

  /**
   * Fingerprint
   *
   * **NOTE:** Same as `instance.request.fingerprint`
   **/
  public var fingerprint(get, never):String;
  private function get_fingerprint():String {
    return _request.fingerprint;
  }

  /**
   * Final URL retrived
   **/
  public var url(get, never):URL;
  private var _url:URL;
  private function get_url():URL {
    return _url;
  }

  /**
   * Final URL retrived (string format)
   *
   * **DEPRECATED**:This is deprecated, use `instance.url.toString()` instead
   **/
  public var urlString(get, never):String;
  private function get_urlString():String {
    return _url.toString();
  }

  /**
   * Response HTTP headers
   **/
  public var headers(get, never):HttpHeaders;
  private var _headers:HttpHeaders;
  private function get_headers():HttpHeaders {
    return _headers;
  }

  /**
   * Response HTTP status
   *
   * **NOTE:** set to 0 if connection error occurs
   **/
  public var status(get, never):Int;
  private var _status:Int;
  private function get_status():Int {
    return _status;
  }

  /**
   * Response content (Bytes or String based on the mime-type)
   **/
  public var content(get, never):Dynamic;
  private var _content:Dynamic;
  private function get_content():Dynamic {
    return _content;
  }

  /**
   * Response content (Bytes)
   **/
  public var contentRaw(get, never):Bytes;
  private var _contentRaw:Bytes;
  private function get_contentRaw():Bytes {
    return _contentRaw;
  }

  /**
   * Response content mime-type
   *
   * **NOTE:** Always `application/octet-stream` in FLASH
   *
   * **NOTE:** Always `text/plain` in JAVASCRIPT
   **/
  public var contentType(get, never):String;
  private var _contentType:String;
  private function get_contentType():String {
    return _contentType;
  }

  /**
   * Response content binary flag (based on the contentType)
   **/
  public var contentIsBinary(get, never):Bool;
  private var _contentIsBinary:Bool;
  private function get_contentIsBinary():Bool {
    return _contentIsBinary;
  }

  /**
   * Response content length
   **/
  public var contentLength(get, never):Int;
  private var _contentLength:Int;
  private function get_contentLength():Int {
    return _contentLength;
  }

  /**
   * Time elapsed from the request start to the end of the response (in seconds)
   **/
  public var time(get, never):Float;
  private var _time:Float;
  private function get_time():Float {
    return _time;
  }

  /**
   * The resource filename (default:"unknown")
   *
   * **NOTE:** This is a guessed resource filename based on the final retrived url
   *
   * *Example*:
   *
   * URL:`http://example.com/download/filename.zip?dl=1`
   *
   * Filename:`filename.zip`
   **/
  public var filename(get, never):String;
  private var _filename:String = null;
  private function get_filename():String {
    if (_filename == null) {
      var filename:String = "";
      var rx = ~/([^?\/]*)($|\?.*)/;
      if (rx.match(_url.toString())) {
        filename = rx.matched(1);
      }
      if (filename == "") filename = AsyncHttp.DEFAULT_FILENAME;
      _filename = filename;
    }
    return _filename;
  }

  /**
   * A good response
   *
   * `true` if the status is >=200 and <400
   **/
  public var isOK(get, never):Bool;
  private var _isOK:Bool;
  private function get_isOK():Bool {
    return _isOK;
  }

  /**
   * Error message
   **/
  private var _error:String = null;
  public var error(get, never):String;
  private function get_error():String {
    return _error;
  }

  // ==========================================================================================


  private static
  var _httpStatus:Map <Int,String> = [100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    306 => 'Switch Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Long',
    415 => 'Unsupported Media Type',
    416 => 'Requested Range Not Satisfiable',
    417 => 'Expectation Failed',
    418 => 'I\'m a teapot',
    422 => 'Unprocessable Entity',
    423 => 'Locked',
    424 => 'Failed Dependency',
    425 => 'Unordered Collection',
    426 => 'Upgrade Required',
    449 => 'Retry With',
    450 => 'Blocked by Windows Parental Controls',
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',
    507 => 'Insufficient Storage',
    509 => 'Bandwidth Limit Exceeded',
    510 => 'Not Extended'
  ];
}
