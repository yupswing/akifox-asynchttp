package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class HttpHeaders {

  private static var FORBIDDEN_ON_REQUEST = ["user-agent","host","content-type","content-length"];

  private var _headers:Map<String,String> = new Map<String,String>();

  public function new(headers:Dynamic=null) {
    if (headers==null) return;
    for (key in Reflect.fields(headers)) {
      var value = Reflect.getProperty(headers,key);
      add(key,value);
    }
  }

  // used when sending a request to exclude already managed headers
  public static function validateRequest(header:String):Bool {
  	if (header==null) return false;
    if (FORBIDDEN_ON_REQUEST.indexOf(header.toLowerCase())>=0) return false;
  	return true;
  }

  // public function toMap():Map<String,String> {
  //   return _headers;
  // }

  public function keys():Iterator<String> {
    return _headers.keys();
  }

  public function exists(key:String):Bool {
    return _headers.exists(key);
  }

  public function get(key:String):String {
    if (_headers.exists(key)) {
      return _headers[key];
    }
    return "";
  }

	public function add(key:String,value:String):HttpHeaders {
    _headers[key] = value;
		return this;
	}

	public function remove(key:String):HttpHeaders {
    if (key==null) return this;
    _headers.remove(key);
		return this;
	}
}
