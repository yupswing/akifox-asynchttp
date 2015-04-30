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

		// STANDARD HTTP REQUEST
		trace('--------- HTTP REQUEST -----------');

		var request = new AsyncHttpRequest({
			   async : false, // force SYNCHRONOUS REQUEST to make the output more readable
				 url : "http://en.wikipedia.org/wiki/Haxe",
			callback : function(response:AsyncHttpResponse) {
										if (response.isOK) {
											trace('DONE (HTTP STATUS ${response.status})');
										} else {
											trace('ERROR (HTTP STATUS ${response.status})');
										}
								 }
			});
		request.send();

		// --------------------------------------------------------------------------------------------------

		// HTTP+SSL REQUEST
		trace('--------- HTTPS REQUEST -----------');

		var request = new AsyncHttpRequest({
			   async : false, // force SYNCHRONOUS REQUEST to make the output more readable
				   url : "https://en.wikipedia.org/wiki/Haxe",
			callback : function(response:AsyncHttpResponse) {
										if (response.isOK) {
											trace('DONE (HTTP STATUS ${response.status})');
										} else {
											trace('ERROR (HTTP STATUS ${response.status})');
										}
								 }
			});
		request.send();


		// --------------------------------------------------------------------------------------------------
	}
}
