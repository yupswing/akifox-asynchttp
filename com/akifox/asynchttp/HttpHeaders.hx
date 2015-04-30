package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class HttpHeaders {

  private static var FORBIDDEN_ON_REQUEST = ["user-agent","host","content-type","content-length"];

  private var _headers:Map<String,String> = new Map<String,String>();
  private var _finalised:Bool = false;

  public function new(headers:Dynamic=null) {
    if (headers==null) return;

    trace(Type.getClassName(Type.getClass(headers)));
    switch(Type.getClassName(Type.getClass(headers))) {
      case 'com.akifox.asynchttp.HttpHeaders' | 'HttpHeaders':
        for (key in cast(headers,HttpHeaders).keys()) {
          add(key,cast(headers,HttpHeaders).get(key));
        }
      default:
        for (key in Reflect.fields(headers)) {
          var value = Reflect.getProperty(headers,key);
          add(key,value);
        }
    }
  }

	public function finalise() {
		_finalised = true; // it will not change
	}

  public function clone():HttpHeaders {
    return new HttpHeaders(this);
  }

  // used when sending a request to exclude already managed headers
  public static function validateRequest(header:String):Bool {
  	if (header==null) return false;
    if (FORBIDDEN_ON_REQUEST.indexOf(header.toLowerCase())>=0) return false;
  	return true;
  }

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
  	if (_finalised) {
			AsyncHttp.error('HttpHeaders ERROR: [.add()] Can\'t add an header. This HttpHeaders object is immutable');
      return this;
    }
    _headers[key] = value;
		return this;
	}

	public function remove(key:String):HttpHeaders {
    if (key==null) return this;
  	if (_finalised) {
			AsyncHttp.error('HttpHeaders ERROR: [.remove()] Can\'t remove an header. This HttpHeaders object is immutable');
      return this;
    }
    _headers.remove(key);
		return this;
	}
}
