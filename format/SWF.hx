package format;


import format.swf.Bitmap;
import format.swf.Character;
import format.swf.EditText;
import format.swf.Font;
import format.swf.Frame;
import format.swf.MorphShape;
import format.swf.MovieClip;
import format.swf.Shape;
import format.swf.Sprite;
import format.swf.StaticText;
import format.swf.SWFStream;
import format.swf.Tags;
import nme.display.BitmapData;
import nme.display.Loader;
import nme.events.Event;
import nme.events.EventDispatcher;
import nme.geom.Rectangle;
import nme.utils.ByteArray;


class SWF {
	
	
	public var backgroundColor (default, null):Int;
	public var classNames (default, null):Array <Dynamic>;
	public var frameRate (default, null):Float;
	public var height (default, null):Int;
	public var width (default, null):Int;
	
	private var characterData:IntHash <Character>;
	private var stream:SWFStream;
	private var streamPositions:IntHash <Int>;
	private var symbols:Hash <Int>;
	private var version:Int;
	
	
	public function new (data:ByteArray) {
		
		stream = new SWFStream (data);
		
		characterData = new IntHash <Character> ();
		classNames = new Array <String> ();
		streamPositions = new IntHash <Int> ();
		symbols = new Hash <Int> ();
		
		var dimensions = stream.readRect ();
		width = Std.int (dimensions.width);
		height = Std.int (dimensions.height);
		frameRate = stream.readFrameRate ();
		
		streamPositions.set (0, stream.position);
		var numFrames = stream.readFrames ();
		
		var tag = 0;
		var position = stream.position;
		
		while ((tag = stream.beginTag ()) != 0) {
			
			switch (tag) {
				
				case Tags.SetBackgroundColor:
					
					backgroundColor = stream.readRGB ();
				
				case Tags.DefineShape, Tags.DefineShape2, Tags.DefineShape3, Tags.DefineShape4, Tags.DefineMorphShape, Tags.DefineMorphShape2, Tags.DefineSprite, Tags.DefineBitsJPEG2, Tags.DefineBitsJPEG3, Tags.DefineBitsLossless, Tags.DefineBitsLossless2, Tags.DefineFont, Tags.DefineFont2, Tags.DefineFont3, Tags.DefineText, Tags.DefineEditText:
					
					var id = stream.readID ();
					
					streamPositions.set (id, position);
				
				case Tags.SymbolClass:
					
					readSymbolClass ();
				
			}
			
			stream.endTag();
			position = stream.position;
			
		}
		
		for (className in symbols.keys ()) {
			
			classNames.push (className);
			
		}
		
	}
	
	
	public function createInstance (className:String = ""):MovieClip {
		
		var id = 0;
		
		if (className != "") {
			
			if (!symbols.exists (className)) {
				
				return null;
				
			}
			
			id = symbols.get (className);
			
		}
		
		switch (getCharacter (id)) {
			
			case charSprite (data):
				
				return new MovieClip (data);
			
			default:
				
				return null;
			
		}
		
		return null;
		
	}
	
	
	public function getBitmapData (className:String):BitmapData {
		
		if (!symbols.exists (className)) {
			
			return null;
			
		}
		
		switch (getCharacter (symbols.get (className))) {
			
			case charBitmap (data):
				
				return data.GetBitmap ();
			
			default:
				
				return null;
			
		}
		
		return null;
		
	}
	
	
	public function getBitmapDataID (id:Int):BitmapData {
		
		if (id == 0xffff) {
			
			return null;
			
		}
		
		if (!streamPositions.exists (id)) {
			
			throw("Bitmap not defined: " + id);
			
		}
		
		switch (getCharacter(id)) {
			
			case charBitmap(data) : return data.GetBitmap();
			default: throw "Non-bitmap character";
			
		}
		
		return null;
		
	}
	
	
	public function getCharacter (id:Int) {
		
		if (!streamPositions.exists (id)) {
			
			throw "Invalid character ID (" + id + ")";
			
		}
		
		if (!characterData.exists (id)) {
			
			var cachePosition = stream.position;
			stream.pushTag ();
			
			stream.position = streamPositions.get (id);
			
			if (id == 0) {
				
				readSprite (true);
				
			} else {
				
				switch (stream.beginTag ()) {
					
					case Tags.DefineShape: readShape (1);
					case Tags.DefineShape2: readShape (2);
					case Tags.DefineShape3: readShape (3);
					case Tags.DefineShape4: readShape (4);
					
					case Tags.DefineMorphShape: readMorphShape (1);			
					case Tags.DefineMorphShape2: readMorphShape (2);	
					
					case Tags.DefineSprite: readSprite (false);
					
					case Tags.DefineBitsJPEG2: readBitmap (false, 2);
					case Tags.DefineBitsJPEG3: readBitmap (false, 3);
					case Tags.DefineBitsLossless: readBitmap (true, 1);
					case Tags.DefineBitsLossless2: readBitmap (true, 2);
					
					case Tags.DefineFont: readFont (1);
					case Tags.DefineFont2: readFont (2);
					case Tags.DefineFont3: readFont (3);
					
					case Tags.DefineText: readText (1);
					case Tags.DefineEditText: readEditText (1);
					
				}
				
			}
			
			stream.position = cachePosition;
			stream.popTag ();
			
		}
		
		return characterData.get (id);
		
	}
	
	
	private inline function readBitmap (lossless:Bool, version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charBitmap (new Bitmap (stream, lossless, version)));
		
	}
	
	
	private inline function readEditText (version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charEditText (new EditText (this, stream, version)));
		
	}
	
	
	private function readFileAttributes ():Void {
		
		var flags = stream.readByte ();
		var zero = stream.readByte ();
		zero = stream.readByte ();
		zero = stream.readByte ();
		
	}
	
	
	private inline function readFont (version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charFont (new Font (stream, version)));
		
	}
	
	
	private inline function readMorphShape (version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charMorphShape (new MorphShape (this, stream, version)));
		
	}
	
	
	private inline function readShape (version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charShape (new Shape (this, stream, version)));
		
	}
	
	
	private function readSprite (isStage:Bool):Void {
		
		var id:Int;
		
		if (isStage) {
			
			id = 0;
			
		} else {
			
			id = stream.readID ();
			
		}
		
		var sprite = new Sprite (this, id, stream.readFrames ());
		var tag = 0;
		
		while ((tag = stream.beginTag ()) != 0) {
			
			switch (tag) {
				
				case Tags.FrameLabel:
					
					sprite.LabelFrame (stream.readString ());
				
				case Tags.ShowFrame:
					
					sprite.ShowFrame ();
				
				case Tags.PlaceObject:
					
					sprite.PlaceObject (stream, 1);
				
				case Tags.PlaceObject2:
					
					sprite.PlaceObject (stream, 2);
				
				case Tags.PlaceObject3:
					
					sprite.PlaceObject(stream, 3);
				
				case Tags.RemoveObject:
					
					sprite.RemoveObject (stream, 1);
				
				case Tags.RemoveObject2:
					
					sprite.RemoveObject (stream, 2);
				
				case Tags.DoAction:
					
					// not implemented
				
				default:
					
					if (!isStage) {
						
						trace ("Unknown sub tag: " +  Tags.string (tag));
						
					}
				
			}
			
			stream.endTag ();
			
		}
		
		characterData.set (id, charSprite (sprite));
		
	}
	
	
	private inline function readText (version:Int):Void {
		
		var id = stream.readID ();
		characterData.set (id, charStaticText (new StaticText (this, stream, version)));
		
	}
	
	
	private inline function readSymbolClass () {
		
		var numberOfSymbols = stream.readUInt16 ();
		
		for (i in 0...numberOfSymbols) {
			
			var symbolID = stream.readUInt16 ();
			var className = stream.readString ();
			symbols.set (className, symbolID);
			
		}
		
	}
	
	
}