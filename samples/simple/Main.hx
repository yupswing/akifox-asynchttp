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

   		// Force not throwing errors but trace (default disabled on -debug)
		AsyncHttp.errorSafe = true;


		// --------------------------------------------------------------------------------------------------


		// NOTE:
		// An AsyncHttpRequest is mutable until sent
		// An AsyncHttpResponse is immutable

		// This is a basic GET example that shows all the exposed variables
		var request = new AsyncHttpRequest("http://www.apple.com",
								function(response:AsyncHttpResponse) {
									if (response.isOK) {
										trace('DONE (HTTP STATUS ${response.status})');
									} else {
										trace('ERROR (HTTP STATUS ${response.status})');
									}
								}  
					      );
		request.autoParse = false; // set autoParse to false (it is already the default)
		request.send();
		request.autoParse = false; // can't modify a property after sending! (it will throw an error)


		// --------------------------------------------------------------------------------------------------


		// This is a more complex example
		// it is specified an host + a port + a path + a querystring
		// but the host does not exists, so it will get a status 0
		// (the handler is anonymous)
		new AsyncHttpRequest("http://thishostdoesnotexists.com:8080/mypage?field=test&field2=test",
							 function(response:AsyncHttpResponse){
								// anonymous response handler
						 		trace(response.fingerprint + " EXAMPLE > Failed request because of host (status: " + response.status + " time: " + response.time + "s)");
							 }).send();


		// --------------------------------------------------------------------------------------------------


		// This is an example of multiple requests with same response handler
		// The order of the responses could be not the same as the order of the requests

		// Prepare and send (saving the fingerprint)
		var request = new AsyncHttpRequest("http://en.wikipedia.org/wiki/Haxe",wikipediaPage);
		wikipediaHaxeFingerprint = request.fingerprint;
		request.send();

		// Send directly
		new AsyncHttpRequest("http://en.wikipedia.org/wiki/OpenFL",wikipediaPage).send(); 		// good
		new AsyncHttpRequest("http://en.wikipedia.org/wiki/Akifox",wikipediaPage).send(); 		// no page (yet)
		new AsyncHttpRequest("http://en.wiKKipedia.org/wiki/Wikipedia",wikipediaPage).send(); // wrong host

	}

	static var wikipediaHaxeFingerprint:String = null;

	static function wikipediaPage(response:AsyncHttpResponse) {
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
