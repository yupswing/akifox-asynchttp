package com.akifox.asynchttp;
using StringTools;

/**

@author Simone Cingano (yupswing) [Akifox Studio](http://akifox.com)

@licence MIT Licence
**/


class URL {

  public var regexURL = ~/^([a-z]+:|)(\/\/[^\/\?:]+|)(:\d+|)([^\?]*|)(\?.*|)/i;

  var _urlString:String;

  var _protocol:String = "";
  var _host:String = "";
  var _port:String = "";
  var _resource:String = "";
  var _querystring:String = "";

  public function new(urlString:String) {
    _urlString = urlString;

    if (regexURL.match(urlString)) {
      _protocol = regexURL.matched(1).substr(0,-1);
      if (_protocol==null) _protocol = "";
      _host = regexURL.matched(2).substr(2);
      if (_host==null) _host = "";
      _port = regexURL.matched(3);
      if (_port==null) _port = "";
      _resource = regexURL.matched(4);
      if (_resource==null) _resource = "";
      _querystring = regexURL.matched(5);
      if (_querystring==null) _querystring = "";
    }
  }

  public function toString():String {
    return '$protocol$_host$_port$_resource$_querystring';
  }

  public function clone():URL {
    return new URL(this.toString());
  }

  public function merge(url:URL) {
    if (_protocol=="") _protocol = url._protocol;
    if (_host=="") _host = url._host;
    if (_port=="") _port = url._port;
    _resource = mergeResources(_resource,url._resource);
    // no querystring merging
  }

  private function mergeResources(resNew:String,resOriginal:String="") {

    //TODO could be better performances

    // purpose of this method:
    // - resolve all '../'
    // - merge absolute and relative paths

    var result:String;
    var levels:Array<String>;
    if (resNew.substr(0,1)=="/") {
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
        while(true) {
            if (levels[i]=='..') {
               if (i>0) levels.splice(i-1,2);
               else levels.shift();
               break;
            }
            i++;
            if (i>=loop){
                finish = true;
                break;
            }
        }
    } while(!finish);
    result = levels.join('/');
    if (result.substr(0,1)!='/') result = '/$result';
    return result;

  }

  //============================================================================

  public var ssl(get,never):Bool;
  private function get_ssl():Bool {
    return (_protocol == "https");
  }

  public var http(get,never):Bool;
  private function get_http():Bool {
    return (_protocol.substr(0,4) == "http"); //http or https
  }

  public var relative(get,never):Bool;
  private function get_relative():Bool {
    return (_protocol == "" || _host == "");
  }

  //============================================================================

  public var protocol(get,never):String;
  private function get_protocol():String {
    if (_protocol!="") return '$_protocol://';
    return '';
  }

  public var port(get,never):Int;
  private function get_port():Int {
    if (_port=="") {
      if (http&&!ssl) {
        return 80;
      } else if (http&&ssl) {
        return 443;
      } else {
        // need to be expanded to support more protocols default ports
        return 0;
      }
    } else {
      return Std.parseInt(_port.substr(1));
    }
  }

  public var host(get,never):String;
  private function get_host():String {
    return _host;
  }

  public var resource(get,never):String;
  private function get_resource():String {
    if (_resource == "") return "/";
    return _resource;
  }

  public var querystring(get,never):String;
  private function get_querystring():String {
    return _querystring;
  }

}
