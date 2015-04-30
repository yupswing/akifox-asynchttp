package com.akifox.asynchttp;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class HttpMethod {
  // TODO bad implementation should be done with enums
  public static inline var GET = "GET";
  public static inline var POST = "POST";
  public static inline var PUT = "PUT";
  public static inline var DELETE = "DELETE";
  private static var METHODS = ["GET","POST","PUT","DELETE"];
  public static inline var DEFAULT_METHOD = GET;

  public static function validate(value:String) {
  	if (value==null || HttpMethod.METHODS.indexOf(value)==-1) value = DEFAULT_METHOD;
  	return value;
  }
}
