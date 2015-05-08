
# Changelog

## What's new 0.4.1

- Added optional callbackError (to avoid the IF in the callback function)
- Better internal content handling

````haxe

// These two requests are equivalent (you choose which way you prefer)

// One single callback
var request = new HttpRequest({
         url : "http://www.google.com",
    callback : function(response:HttpResponse):Void {
                if (response.isOK) {
                  trace(response.content);
                  trace('DONE (HTTP STATUS ${response.status})');
                } else {
                  trace('ERROR (HTTP STATUS ${response.status})');
                }
              }  
});


// One callback for success and one for failure
var request = new HttpRequest({
             url : "http://www.google.com",
        callback : function(response:HttpResponse):Void {
                    // response.isOK is True
                    trace(response.content);
                    trace('DONE (HTTP STATUS ${response.status})');
                  },
   callbackError : function(response:HttpResponse):Void {
                    // response.isOK is False
                    trace('ERROR (HTTP STATUS ${response.status})');
                  }
});
````

---

## What's new 0.4.0 *[breaking API]*

- SSL support! (cpp+neko using [hxssl](https://github.com/tong/hxssl), java+js+flash using standard haxe)
- Easier instances (options instead of arguments for *new* Request objects)
- Better redirect handling (default max redirection set to 10 + relative redirection URLs support)
- Custom headers on Request (cpp+neko only)
- Removed autoparse option
- User-agent option
- HTTP version option (1.0 or 1.1)
- Synchronous/Asynchronous option
- Request cloning (to perform a request more than once)

The API change is breaking:
Instead of making an AsyncHttpRequest object with 2 parameters
````haxe
// version <= 3.x
new AsyncHttpRequest('urlString',function(response:AsyncHttpResponse) { ... });
````
you can pass *every* setting as options (new classes' names: HttpRequest and HttpResponse)
````haxe
// version >= 4.x
new HttpRequest({url:'urlString',callback:function(response:HttpResponse) { ... }});
````

Fix your code! This edit was necessary to make future improvements easier with less future API changes.

## What's new 0.3.1 (fixed issue #1)

- Timeout option (request)
- Handling unexpected connection termination

## What's new 0.3 *[breaking API]*

- The library doesn't rely on OpenFL anymore and it is a pure Haxe library!
- Flash target use the default URLLoader (async)
- Javascript target use the default Haxe.Http (async XmlHttpRequest)
- The content (both on request and response) is now fully functional.
- The library is now thread-safe (major problems in 0.2)
- Support for redirection (HTTP STATUS 30x)
- Using sockets make requests around 50% faster than OpenFL URLLoader

## What's new 0.2

- First public release (relying on OpenFL)
