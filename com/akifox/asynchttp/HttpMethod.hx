package com.akifox.asynchttp;

/**
##HttpMethod

This static class is used to list the available Http Methods

**TODO:** This implementation will probably change in the future in favour of enums

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@licence MIT Licence
**/


class HttpMethod {
  public static inline var GET = "GET";
  public static inline var POST = "POST";
  public static inline var PUT = "PUT";
  public static inline var DELETE = "DELETE";

  public static inline var HEAD = "HEAD";
  public static inline var CONNECT = "CONNECT";
  public static inline var OPTIONS = "OPTIONS";
  public static inline var TRACE = "TRACE";
  public static inline var PATCH = "PATCH";

  @:dox(hide)
  public static inline var DEFAULT_METHOD = GET;

  @:dox(hide)
  public static function validate(value:String) {
    if (value == null) value = DEFAULT_METHOD;
    return value.toUpperCase();
  }
}
