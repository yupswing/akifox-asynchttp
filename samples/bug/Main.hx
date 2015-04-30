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
		var request = new AsyncHttpRequest("http://en.wikipedia.org/wiki/Wikipedia",
								function(response:AsyncHttpResponse) {
									if (response.isOK) {
										trace('DONE (HTTP STATUS ${response.status})');
									} else {
										trace('ERROR (HTTP STATUS ${response.status})');
									}
								}
					      );
		//request.timeout = 2;
		request.autoParse = false; // set autoParse to false (it is already the default)
		request.send();
		//request.autoParse = false; // can't modify a property after sending! (it will throw an error)


		// --------------------------------------------------------------------------------------------------
}
}
