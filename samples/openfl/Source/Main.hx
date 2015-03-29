package ;
import com.akifox.asynchttp.*;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.Lib;

class Main extends Sprite {


	var images = ["http://www.openfl.org/images/logo.png",
			  "http://old.haxe.org/file/foundation.jpg",
			  "http://i0.kym-cdn.com/photos/images/list/000/160/616/TROLOLOL.jpg"];
	var index = 0;

	function new() {
		super();
		Lib.current.stage.addChild(this);
		Lib.current.stage.addEventListener(openfl.events.MouseEvent.CLICK,function(e:openfl.events.MouseEvent) { loadNext(); });

		var hint = new openfl.text.TextField();

		var hintFormat = new openfl.text.TextFormat('Arial', 16 , 0);
		hintFormat.align = openfl.text.TextFormatAlign.CENTER;
		hint.autoSize = openfl.text.TextFieldAutoSize.LEFT;
		hint.defaultTextFormat = hintFormat;
		hint.embedFonts = true;
		hint.selectable = false;
		hint.wordWrap = false;
		hint.border = false;
		hint.text = 'Click to load a picture and add it to stage\n'+
					'Click more than once to start multiple concurrent requests\n'+
					'Look at the console to see the requests infos';
		hint.x = Lib.current.stage.stageWidth/2-hint.width/2;
		hint.y = Lib.current.stage.stageHeight/2-hint.height/2;
		addChild(hint);
		// --------------------------------------------------------------------------------------------------

			// Force log to console (default enabled on -debug)
		AsyncHttp.logEnabled = true;

			// Force not throwing errors but trace (default disabled on -debug)
		AsyncHttp.errorSafe = true;

		// --------------------------------------------------------------------------------------------------

	}

	function loadNext() {

		if (index>=images.length) index = 0;
		index++;


		var request = new AsyncHttpRequest(images[index-1],
								function(response:AsyncHttpResponse) {
									if (response.isOK) {
										trace('DONE (HTTP STATUS ${response.status})');
										// HERE IS THE MAGIC!
										var bitmap = new Bitmap(response.toBitmapData());
										// END OF THE MAGIC...
										bitmap.x = Math.random()*(Lib.current.stage.stageWidth-bitmap.width);
										bitmap.y = Math.random()*(Lib.current.stage.stageHeight-bitmap.height);
										addChild(bitmap);
									} else {
										trace('ERROR (HTTP STATUS ${response.status})');
									}
								}
					      );
		request.send();
	}

}
