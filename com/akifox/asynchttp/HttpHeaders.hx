package com.akifox.asynchttp;

/**
##HttpHeaders

This class represents an Http header collection and it is used by the library to handle HTTP Headers

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class HttpHeaders {

  private static var FORBIDDEN_ON_REQUEST = ["user-agent", "host", "content-type", "content-length"];

  private var _headers:Map<String,String> = new Map<String,String>();

  /**
   * Tell if the instance is immutable
   *
   * **NOTE:** The only way to change an immutable instance is copying it (`instance.clone()`) and change the copy
   **/
  public var finalised(get, never):Bool;
  private var _finalised:Bool = false; // (no edit allowed)
  private function get_finalised():Bool {
    return _finalised;
  }

  // ==========================================================================================

  /**
   * Class instance
   *
   * @param headers  Accept an Anonymous Structure (ie:{'Pragma':'no-cache'}) or an HttpHeaders instance
   **/
  public function new(headers:Dynamic = null) {
    if (headers == null) return;

    switch (Type.getClassName(Type.getClass(headers))) {
      case 'com.akifox.asynchttp.HttpHeaders' | 'HttpHeaders':
        for (key in cast(headers, HttpHeaders).keys()) {
          add(key, cast(headers, HttpHeaders).get(key));
        }
      default:
        for (key in Reflect.fields(headers)) {
          var value = Reflect.getProperty(headers, key);
          add(key, value);
        }
    }
  }

  /**
   * @returns   Debug representation of the HttpHeaders instance
   **/
  public function toString():String {
    return '[HttpHeaders <$_headers>]';
  }

  /**
   * Deep copy of the HttpHeaders
   *
   * @returns   A new HttpHeaders
   **/
  public function clone():HttpHeaders {
    return new HttpHeaders(this);
  }

  /**
   * Make this instance immutable
   *
   * **NOTE:** This method is called automatically once the HttpRequest instance, which handle this HttpHeaders instance, is sent
   **/
  public function finalise() {
    _finalised = true; // it will not change
  }

  // ==========================================================================================

  // used when sending a request to exclude already managed headers
  @:dox(hide)
  public static function validateRequest(header:String):Bool {
    if (header == null) return false;
    if (FORBIDDEN_ON_REQUEST.indexOf(header.toLowerCase()) >= 0) return false;
    return true;
  }

  // ==========================================================================================

  /**
   * Iterator on headers
   *
   * **Use example:** `for (key in instance.keys)`
   **/
  public function keys():Iterator<String> {
    return _headers.keys();
  }

  /**
   * Check if an header exists
   **/
  public function exists(key:String):Bool {
    return _headers.exists(key);
  }

  /**
   * Get an header value from its key (or "" if no header)
   **/
  public function get(key:String):String {
    if (_headers.exists(key)) {
      return _headers[key];
    }
    return "";
  }

  /**
   * Add an header and its value to the instance
   *
   * **NOTE:** If already present the header will be overwritten
   **/
  public function add(key:String, value:String):HttpHeaders {
    if (_finalised) {
      AsyncHttp.error('HttpHeaders.add() -> Can\'t add an header. This HttpHeaders object is immutable');
      return this;
    }
    _headers[key] = value;
    return this;
  }

  /**
   * Remove an header and its value from the instance
   **/
  public function remove(key:String):HttpHeaders {
    if (key == null) return this;
    if (_finalised) {
      AsyncHttp.error('HttpHeaders.remove() -> Can\'t remove an header. This HttpHeaders object is immutable');
      return this;
    }
    _headers.remove(key);
    return this;
  }
}
