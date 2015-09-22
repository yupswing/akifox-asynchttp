package ;
import com.akifox.asynchttp.*;

class Main {

	static function main() {

		// The output log is going to be pretty chaotic because of multi-threading
		// At the beginning of every line there will be an 8 char string that identify
		// the request (and so the thread)

		runRequests();

		#if sys
		var input = Sys.stdin().readLine();
		trace('Goodbye!');
		#end

	}

	static function runRequests() {


		// --------------------------------------------------------------------------------------------------


   		// Force log to console (default enabled on -debug)
		AsyncHttp.logEnabled = true;


		// --------------------------------------------------------------------------------------------------


		// NOTE:
		// An HttpRequest is mutable until sent
		// An HttpResponse is immutable

		// This is a basic GET example that shows all the exposed variables
		var request = new HttpRequest({
					   url : "http://www.apple.com",
				callback : function(response:HttpResponse) {
										if (response.isOK) {
											trace('DONE (HTTP STATUS ${response.status})');
										} else {
											trace('ERROR (HTTP STATUS ${response.status})');
										}
									}
			});
		request.send();


		// --------------------------------------------------------------------------------------------------


		// This is a more complex example
		// it is specified an host + a port + a path + a querystring
		// but the host does not exists, so it will get a status 0
		// (the handler is anonymous)
		new HttpRequest({
					 url : "http://thishostdoesnotexists.com:8080/mypage?field=test&field2=test",
			callback : function(response:HttpResponse){
									// anonymous response handler
									trace(response.fingerprint + " EXAMPLE > Failed request because of host (status: " + response.status + " time: " + response.time + "s)");
								 }
			}).send();


		// --------------------------------------------------------------------------------------------------


		// This is an example of multiple requests with same response handler
		// The order of the responses could be not the same as the order of the requests

		// Prepare and send (saving the fingerprint)
		var request = new HttpRequest({url:"http://en.wikipedia.org/wiki/Haxe",callback:wikipediaPage});
		wikipediaHaxeFingerprint = request.fingerprint;
		request.send();

		// Send directly
		new HttpRequest({url:"http://en.wikipedia.org/wiki/OpenFL",callback:wikipediaPage}).send(); 		// good
		new HttpRequest({url:"http://en.wikipedia.org/wiki/Akifox",callback:wikipediaPage}).send(); 		// no page (yet)
		new HttpRequest({url:"http://en.wiKKipedia.org/wiki/Wikipedia",callback:wikipediaPage}).send(); // wrong host

	}

	static var wikipediaHaxeFingerprint:String = null;

	static function wikipediaPage(response:HttpResponse) {
		// check the fingerprint to identify a specific request for this handler
		if (wikipediaHaxeFingerprint == response.fingerprint) {
			trace(response.fingerprint + ' EXAMPLE > HEY, this was the Haxe Wikipedia page request!');
		}

		trace(response.fingerprint + " EXAMPLE > function wikipediaPage: " + response.fingerprint + " status: " + response.status + " time: " + response.time);
		if(response.isOK) {
			trace(response.fingerprint + ' EXAMPLE > Wikipedia: done');
		} else {
			trace(response.fingerprint + ' EXAMPLE > Wikipedia: error');
		}
	}
}
