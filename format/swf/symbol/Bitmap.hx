package format.swf.symbol;


import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Rectangle;
import flash.utils.ByteArray;
import format.swf.data.SWFStream;

#if flash
import flash.display.Loader;
#end


class Bitmap {
	
	
	public var bitmapData:BitmapData;
	
	#if flash
	private var alpha:ByteArray;
	private var loader:Loader;
	#end
	
	
	public function new (stream:SWFStream, lossless:Bool, version:Int) {
		
		if (lossless) {
			
			var format = stream.readByte ();
			
			/*
				Formats:
				
				1 = RGBA index
				2 = 32-bit RGB
				3 = RGB index
				4 = 15-bit RGB
				5 = 24-bit RGB
			*/
			
			var width = stream.readUInt16 ();
			var height = stream.readUInt16 ();
			var tableSize = 0;
			
			if (format == 3) {
				
				tableSize = stream.readByte () + 1;
				
			}
			
			var buffer:ByteArray = stream.readFlashBytes (stream.getBytesLeft ());
			buffer.uncompress ();
			
			if (version == 2) {
				
				if (format == 4) {
					
					throw ("No 15-bit format in DefineBitsLossless2");
					
				} else {
					
					if (format == 3) {
						
						format = 1;
						
					} else {
						
						format = 2;
						
					}
					
				}
				
			}
			
			var transparent = false;
			
			if (format < 3) {
				
				transparent = true;
				
			}
			
			bitmapData = new BitmapData (width, height, transparent);
			bitmapData.setPixels (new Rectangle (0, 0, width, height), buffer);
			
		} else {
			
			var buffer:ByteArray = null;
			var alpha:ByteArray = null;
			
			if (version == 2) {
				
				var size = stream.getBytesLeft ();
				buffer = stream.readBytes (size);
				
			} else if (version == 3) {
				
				var size = stream.readInt ();
				buffer = stream.readBytes (size);
				
				alpha = stream.readFlashBytes (stream.getBytesLeft ());
				alpha.uncompress ();
				
			}
			
			#if flash
			
			loader = new Loader ();
			this.alpha = alpha;
			
			loader.contentLoaderInfo.addEventListener (Event.COMPLETE, loader_onComplete);
			loader.loadBytes (buffer);
			
			#else
			
			bitmapData = BitmapData.loadFromHaxeBytes (buffer, alpha);
			
			#end
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	#if flash
	
	private function loader_onComplete (event:Event):Void {
		
		bitmapData = event.currentTarget.content.bitmapData;
		
		if (alpha != null && bitmapData != null) {
			
			var width = bitmapData.width;
			var height = bitmapData.height;
			
			if (Std.int (alpha.length) != Std.int (width * height)) {
				
				throw ("Alpha size mismatch");
				
			}
			
			var index = 0;
			
			for (y in 0...height) {
				
				for (x in 0...width) {
					
					bitmapData.setPixel32 (x, y, bitmapData.getPixel (x, y) | (alpha[index ++] << 24));
					
				}
				
			}
			
		}
		
		loader.removeEventListener (Event.COMPLETE, loader_onComplete);
		loader = null;
		alpha = null;
		
	}
	
	#end
	
	
}