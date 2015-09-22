package ;
import com.akifox.asynchttp.*;

class AsyncHttpExample {

	static function main() {

		runRequests();

	}

	static function runRequests() {


		// --------------------------------------------------------------------------------------------------

   	// Force log to console (default enabled on -debug)
		AsyncHttp.logEnabled = true;

		// --------------------------------------------------------------------------------------------------

		// STANDARD HTTP REQUEST
		trace('--------- HTTP REQUEST -----------');

		var request = new HttpRequest({
				   url : "test.xml",
			callback : function(response:HttpResponse) {
										if (response.isOK) {
											trace('DONE (HTTP STATUS ${response.status})');
											trace(response.content);
										} else {
											trace('ERROR (HTTP STATUS ${response.status})');
										}
								 }
			});

		request.send();

		// --------------------------------------------------------------------------------------------------
	}
}
