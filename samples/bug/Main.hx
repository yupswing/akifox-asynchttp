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
		// An HttpRequest is mutable until sent
		// An HttpResponse is immutable

		// // This is a basic GET example that shows all the exposed variables
		// var request = new HttpRequest({url:"http://en.wikipedia.org/wiki/Wikipedia",
		// 						callback:function(response:HttpResponse) {
		// 							if (response.isOK) {
		// 								trace('DONE (HTTP STATUS ${response.status})');
		// 							} else {
		// 								trace('ERROR (HTTP STATUS ${response.status})');
		// 							}
		// 						}
		// 					});
		// //request.timeout = 2;
		// request.send();

		var request = new HttpRequest({url:"http://en.wikipedia.org/wiki/Wikipedia",
								callback:function(response:HttpResponse) {
									trace('DONE (HTTP STATUS ${response.status})');
								},
								callbackError:function(response:HttpResponse) {
									trace('${response.error})');
								}
							});
		//request.timeout = 2;
		request.send();


		// --------------------------------------------------------------------------------------------------
	}
}
