package com.akifox.asynchttp;
using StringTools;

/**
##URL

This class represents an URL and it is used by the library to handle URLs

@repo [akifox-asynchttp repository](https://github.com/yupswing/akifox-asynchttp)

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class URL {

  var regexURL = ~/^([a-z]+:|)(\/\/[^\/\?:]+|)(:\d+|)([^\?]*|)(\?.*|)/i;

  var _urlString:String;

  var _protocol:String = "";
  var _host:String = "";
  var _port:String = "";
  var _resource:String = "";
  var _querystring:String = "";

  /**
   * Class instance
   *
   * @param urlString  An URL string in standard format "protocol://host:port/resource?querystring"
   **/
  public function new(urlString:String) {
    _urlString = urlString;

    if (regexURL.match(urlString)) {
      _protocol = regexURL.matched(1).substr(0, -1);
      if (_protocol == null) _protocol = "";
      _host = regexURL.matched(2).substr(2);
      if (_host == null) _host = "";
      _port = regexURL.matched(3);
      if (_port == null) _port = "";
      _resource = regexURL.matched(4);
      if (_resource == null) _resource = "";
      _querystring = regexURL.matched(5);
      if (_querystring == null) _querystring = "";
    }
  }

  /**
   * @returns   A string representation of the URL:"protocol://host:port/resource?querystring"
   **/
  public function toString():String {
    return '$protocol$_host$_port$_resource$_querystring';
  }

  /**
   * Deep copy of the URL
   *
   * @returns   A new URL
   **/
  public function clone():URL {
    return new URL(this.toString());
  }

  /**
   * Merge this URL with another one.
   * If this URL is relative it will copy the missing parts from the given one,
   * otherwise nothing will change.
   * (this method is needed to make a relative URL complete)
   *
   * @param   URL to be merged with
   * @returns This URL
   **/
  public function merge(url:URL):URL {
    if (_protocol == "") _protocol = url._protocol;
    if (_host == "") _host = url._host;
    if (_port == "") _port = url._port;
    _resource = mergeResources(_resource, url._resource);
    // no querystring merging
    return this;
  }

  private function mergeResources(resNew:String, resOriginal:String = "") {

    //TODO could be better performances

    // purpose of this method:
    // - resolve all '../'
    // - merge absolute and relative paths

    var result:String;
    var levels:Array<String>;
    if (resNew.substr(0, 1) == "/") {
      levels = resNew.split('/');
    } else {
      levels = resOriginal.split("/");
      levels.pop();
      levels = levels.concat(resNew.split("/"));
    }
    var finish = false;
    do {
      var loop = levels.length;
      var i = 0;
      while (true) {
        if (levels[i] == '..') {
          if (i > 0) levels.splice(i - 1, 2);
          else levels.shift();
          break;
        }
        i++;
        if (i >= loop) {
          finish = true;
          break;
        }
      }
    } while (!finish);
    result = levels.join('/');
    if (result.substr(0, 1) != '/') result = '/$result';
    return result;

  }

  //============================================================================

  /**
   * Tells if the URL use an SSL protocol
   **/
  public var isSsl(get, never):Bool;
  private function get_isSsl():Bool {
    return (_protocol == "https");
  }

  /**
   * Tells if the URL use an HTTP(S) protocol
   **/
  public var isHttp(get, never):Bool;
  private function get_isHttp():Bool {
    return (_protocol.substr(0, 4) == "http"); //http or https
  }

  /**
   * Tells if the URL is relative
   * (Only absolute URLs are complete. Any relative one needs to be merged with a complete to make it point to a resource)
   **/
  public var isRelative(get, never):Bool;
  private function get_isRelative():Bool {
    return (_protocol == "" || _host == "");
  }

  //============================================================================

  /**
   * The protocol (ie:"http://")
   **/
  public var protocol(get, never):String;
  private function get_protocol():String {
    if (_protocol != "") return '$_protocol://';
    return '';
  }

  /**
   * The port (ie:80)
   **/
  public var port(get, never):Int;
  private function get_port():Int {
    if (_port == "") {
      if (isHttp && !isSsl) {
        return 80;
      } else if (isHttp && isSsl) {
        return 443;
      } else {
        // need to be expanded to support more protocols default ports
        return 0;
      }
    } else {
      return Std.parseInt(_port.substr(1));
    }
  }

  /**
   * The host (ie:google.com)
   **/
  public var host(get, never):String;
  private function get_host():String {
    return _host;
  }

  /**
   * The resource (ie:/search/index.html)
   **/
  public var resource(get, never):String;
  private function get_resource():String {
    if (_resource == "") return "/";
    return _resource;
  }

  /**
   * The querystring (ie:?q=test&s=1)
   **/
  public var querystring(get, never):String;
  private function get_querystring():String {
    return _querystring;
  }

}
