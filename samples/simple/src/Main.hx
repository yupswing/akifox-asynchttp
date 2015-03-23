package ;
import com.akifox.asynchttp.*;

class Main {

	var wikipediaHaxeFingerprint:String = null;

    function new() {

   		// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! //
   		//     THERE WILL BE A BLANK WINDOW	     //
   		// LOOK AT THE CONSOLE TO SEE THE OUTPUT //
   		// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! //

   		// The output log is going to be pretty chaotic because of multi-threading
   		// At the beginning of every line there will be an 8 char string that identify
   		// the request (and so the thread)


		// --------------------------------------------------------------------------------------------------


   		// Force log to console (usually enabled only on -debug)
		AsyncHttp.logEnabled = true;


		// --------------------------------------------------------------------------------------------------


		// This is a basic POST example with no handler and no content
		// not very useful since there is no handler to get the response but it works getting a status 200
		// (if the connection is available, otherwise status 0)
		var url = "http://www.google.com";
		var request = new AsyncHttpRequest(
						url, 		// URL:String				"http://host:port/path?querystring"
						"GET",		// METHOD:String			GET, POST, PUT, DELETE
						null,		// CONTENT:Dynamic			the request content		
						null,		// CONTENT_TYPE:String		default is "application/x-www-form-urlencoded"
						null        // HANDLER:AsynchHttpResponse->Void (the function that will handle the response)
					  );
		request.send();


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

   function wikipediaPage(response:AsyncHttpResponse) {
   		// check the fingerprint to identify a specific request for this handler
   		if (wikipediaHaxeFingerprint == response.fingerprint) {
   			trace(response.fingerprint + ' EXAMPLE > hey, this was the Haxe Wikipedia page request!');
   		}


		trace(response.fingerprint + " EXAMPLE > function wikipediaPage: " + response.fingerprint + " status: " + response.status + " time: " + response.time);
		if(response.status == 0 || response.content==null) {
			// there were no response
			trace(response.fingerprint + ' EXAMPLE > Wikipedia: error');
		} else {
			trace(response.fingerprint + ' EXAMPLE > Wikidedia: done');
		}
   }
}