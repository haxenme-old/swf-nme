package format.swf.lite;


import flash.display.Bitmap;
import flash.display.SimpleButton;
import format.swf.lite.MovieClip;


class SWFLite {
	
	
	public var symbols:IntHash <SWFSymbol>;
	
	
	public function new () {
		
		symbols = new IntHash <SWFSymbol> ();
		
		// distinction of symbol by class name ad characters by ID somewhere?
		
		
	}
	
	
	public function createButton (className:String):SimpleButton {
		
		return null;
		
	}
	
	
	public function createMovieClip (className:String = ""):MovieClip {
		
		return null;
		
	}
	
	
	public function getBitmap (className:String):Bitmap {
		
		return null;
		
	}
	
	
}