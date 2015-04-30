package ;
import com.akifox.asynchttp.*;
import StringTools;

class AsyncHttpExample {

	static function setContent(id,content) {
		var d = js.Browser.document.getElementById(id);
		if( d == null )
		js.Lib.alert("Unknown element : "+id);
		d.innerHTML = content;
	}

	static function main() {

		// Force log to console (usually enabled only on -debug)
		AsyncHttp.logEnabled = true;

   		// Force not throwing errors but trace (default disabled on -debug)
		AsyncHttp.errorSafe = true;

		new AsyncHttpRequest({
			url : "test.html",
			callback : function (response:AsyncHttpResponse) {
									if (response.isOK) {
										setContent("asynchttp-text",response.content);
									} else {
										setContent("asynchttp-text",'ERROR -> ${response.status}');
									}
								 }
		}).send();

		new AsyncHttpRequest({
			url : "test.xml",
			callback : function (response:AsyncHttpResponse) {
										if (response.isOK) {
											setContent("asynchttp-xml-print",StringTools.htmlEscape(response.content));
											setContent("asynchttp-xml-code",response.content);
										} else {
											setContent("asynchttp-xml",'ERROR -> ${response.status}');
										}
									}
		}).send();

		new AsyncHttpRequest({
			url : "test.js",
			callback : function (response:AsyncHttpResponse) {
										if (response.isOK) {
											setContent("asynchttp-js-print",response.content);
											setContent("asynchttp-js-code",response.content);
										} else {
											setContent("asynchttp-js-print",'ERROR -> ${response.status}');
										}
									}
		}).send();

	}
}
