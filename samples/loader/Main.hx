package ;
import com.akifox.asynchttp.*;
import Sys;

class Main {

	static function main() {

		// The output log is going to be pretty chaotic because of multi-threading
		// At the beginning of every line there will be an 8 char string that identify
		// the request (and so the thread)

		runRequests();

		#if sys
		var input = Sys.stdin().readLine();
		Sys.println('\nGoodbye!');
		#end

	}

	static function runRequests() {

		// --------------------------------------------------------------------------------------------------


   		// Force log to console (default enabled on -debug)
		AsyncHttp.logEnabled = false;
		Sys.println('Getting large file!');

		// --------------------------------------------------------------------------------------------------

		var request = new HttpRequest({url:"http://ipv4.download.thinkbroadband.com/100MB.zip",
								callback:function(response:HttpResponse) {
									Sys.println('\nDONE (HTTP STATUS ${response.status})');
								},
								callbackError:function(response:HttpResponse) {
									Sys.println('ERROR ${response.error}');
								},
								callbackProgress : function(loaded:Int,total:Int):Void {
								var loaded_mb:Float = Math.round(loaded / 10000) / 100;

									if (total>=0) {
										var percent:Int = Std.int(Math.round(loaded / total * 1000) / 10);
										var quarter:Int = Std.int(percent/4);
										var total_mb:Float = Math.round(total / 10000) / 100;
										var output = "[";
										for (x in 0...quarter-1) { output+="#"; }
										for (x in quarter...25) { output+="."; }
										output+="]";
										Sys.print('${output} ${loaded_mb} MB / ${total_mb} MB (${percent}%)   \r');
									} else {
										Sys.print('${loaded_mb} MB / ??? MB\r');
									}

								},
							});
		request.send();


		// --------------------------------------------------------------------------------------------------
	}
}
