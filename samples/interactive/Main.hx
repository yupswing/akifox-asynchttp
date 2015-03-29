package ;
import com.akifox.asynchttp.*;

class Main {

	var wikipediaHaxeFingerprint:String = null;


    static function main() {

   	// Force log to console (usually enabled only on -debug)
		AsyncHttp.logEnabled = true;

   	// Force not throwing errors but trace (default disabled on -debug)
		AsyncHttp.errorSafe = true;

   	#if sys

		trace('\n>> Enter an URL and press [enter] (also HTTP://):\nexample: http://wikipedia.com/wiki/wikipedia');

   		while (true) {
   			var input = Sys.stdin().readLine();
   			if (input=="") break;
   			new AsyncHttpRequest(input,onResponse).send();
   		}

		trace('>> Goodbye!');

		#else

			new AsyncHttpRequest("http://wikipedia.com/wiki/wikipedia",onResponse).send();

		#end

	}

   static function onResponse(response:AsyncHttpResponse):Void {
   	trace('-------------------------');
		trace(response);
		if (response.isOK) {
			
         /* if (response.isText)
            trace('TEXT\n'+response.toText());
         if (response.isJson)
            trace('JSON\n'+response.toJson());
         if (response.isXml)
            trace('XML\n'+response.toXml());*/

			trace("First 500 chars:");
			trace(response.toText().substr(0,500));

            if (response.isBinary) {
            	//trace(response.content); // BYTES DATA
            	trace('[ Binary file <' + response.contentType + '> "' + response.filename + '" ' + Std.int(response.contentLength/1024*100)/100 + 'kb]');
            } else {
            	//trace(response.content); // STRING DATA
            	trace('[ Text file <' + response.contentType + '> "' + response.filename + '" ' + Std.int(response.contentLength/1024*100)/100 + 'kb]');
            }
		} else {
			trace('Response error status ' + response.status);
		}
   	trace('-------------------------');
	}
}