package format.swf;


import flash.display.BlendMode;
import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import format.swf.SWFStream;
import format.swf.Tags;
import format.swf.Character;
import format.swf.Frame;
import format.SWF;


class Sprite {
	
	
	public var frameCount (default, null):Int;
	public var frames (default, null):Array <Frame>;
	public var swf (default, null):SWF;
	
	private var blendMode:BlendMode;
	private var cacheAsBitmap:Bool;
	private var className:String;
	private var filters:Array <BitmapFilter>;
	private var frame:Frame;
	
	private var frameLabels:Hash<Int>;
	private var name:String;
	
	
	public function new (swf:SWF, id:Int, frameCount:Int) {
		
		this.swf = swf;
		this.frameCount = frameCount;
		frames = [ null ]; // frame 0 is empty
		
		filters = null;
		frame = new Frame ();
		frameLabels = new Hash <Int> ();
		name = "Sprite " + id;
		cacheAsBitmap = false;
		
	}
	
	
	private function createBevelFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateBevelFilter");
		
		return null;
		
	}
	
	
	private function createBlurFilter (stream:SWFStream):BitmapFilter {
		
		var blurX = stream.readFixed ();
		var blurY = stream.readFixed ();
		var passes = stream.readByte ();
		
		trace ("CreateBlurFilter");
		
		return null;
		
	}
	
	
	private function createColorMatrixFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateColorMatrixFilter");
		
		var matrix = new Array <Float> ();
		
		for (i in 0...20) {
			
			matrix.push (stream.readFloat ());
			
		}
		
		return null;
		
	}
	
	
	private function createConvolutionFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateConvolutionFilter");
		
		var width = stream.readByte ();
		var height = stream.readByte ();
		var div = stream.readFloat ();
		var bias = stream.readFloat ();
		var matrix = new Array <Float> ();
		
		for (i in 0...width*height) {
			
			matrix[i] = stream.readFloat ();
			
		}
		
		var flags = stream.readByte ();
		
		return null;
		
	}
	
	
	private function createDropShadowFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateDropShadowFilter");
		
		return null;
		
	}
	
	
	private function createGlowFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateGlowFilter");
		
		return null;
		
	}
	
	
	private function createGradientBevelFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateGradientBevelFilter");
		
		return null;
		
	}
	
	
	private function createGradientGlowFilter (stream:SWFStream):BitmapFilter {
		
		trace ("CreateGradientGlowFilter");
		
		return null;
		
	}
	
	
	public function labelFrame (name:String):Void {
		
		frameLabels.set (name, frame.frame);
		
	}
	
	
	public function placeObject (stream:SWFStream, version:Int) {
		
		if (version == 1) {
			
			var id = stream.readID ();
			var character = swf.getCharacter (id);
			var depth = stream.readDepth ();
			var matrix = stream.readMatrix ();
			
			var colorTransform:ColorTransform = null;
			
			if (stream.getBytesLeft () > 0) {
				
				colorTransform = stream.readColorTransform (false);
				
			}
			
			frame.place (id, character, depth, matrix, colorTransform, null, null);
			
		} else if (version == 2 || version == 3) {
			
			stream.alignBits ();
			
			var hasClipAction = stream.readBool ();
			var hasClipDepth = stream.readBool ();
			var hasName = stream.readBool ();
			var hasRatio = stream.readBool ();
			var hasColorTransform = stream.readBool ();
			var hasMatrix = stream.readBool ();
			var hasCharacter = stream.readBool ();
			var move = stream.readBool ();
			
			var hasImage = false;
			var hasClassName = false;
			var hasCacheAsBitmap = false;
			var hasBlendMode = false;
			var hasFilterList = false;
			
			if (version == 3) {
				
				stream.readBool ();
				stream.readBool ();
				stream.readBool ();
				
				hasImage = stream.readBool ();
				hasClassName = stream.readBool ();
				hasCacheAsBitmap = stream.readBool ();
				hasBlendMode = stream.readBool ();
				hasFilterList = stream.readBool ();
				
			}
			
			var depth = stream.readDepth ();
			
			if (hasClassName) {
				
				className = stream.readString ();
				
			}
			
			var cid = hasCharacter ? stream.readID () : 0;
			var matrix = hasMatrix ? stream.readMatrix () : null;
			var colorTransform = hasColorTransform ? stream.readColorTransform (version > 2) : null;
			var ratio:Null<Int> = hasRatio ? stream.readUInt16 () : null;
			
			if (hasName || (hasImage && hasCharacter)) {
				
				name = stream.readString ();
				
			}
			
			var clipDepth = hasClipDepth ? stream.readDepth () : 0;
			
			if (hasFilterList) {
				
				filters = [];
				
				var count = stream.readByte();
				
				for (i in 0...count) {
					
					var filterID = stream.readByte ();
					
					filters.push (
						switch (filterID)
						{
							case 0 : createDropShadowFilter (stream);
							case 1 : createBlurFilter (stream);
							case 2 : createGlowFilter (stream);
							case 3 : createBevelFilter (stream);
							case 4 : createGradientGlowFilter (stream);
							case 5 : createConvolutionFilter (stream);
							case 6 : createColorMatrixFilter (stream);
							case 7 : createGradientBevelFilter (stream);
							default: throw "Unknown filter : " + filterID + "  " + i + "/" + count; 
						}
					);
					
				}
				
			}
			
			if (hasBlendMode) {
				
				blendMode = switch (stream.readByte ()) {
					case 2 : BlendMode.LAYER;
					case 3 : BlendMode.MULTIPLY;
					case 4 : BlendMode.SCREEN;
					case 5 : BlendMode.LIGHTEN;
					case 6 : BlendMode.DARKEN;
					case 7 : BlendMode.DIFFERENCE;
					case 8 : BlendMode.ADD;
					case 9 : BlendMode.SUBTRACT;
					case 10 : BlendMode.INVERT;
					case 11 : BlendMode.ALPHA;
					case 12 : BlendMode.ERASE;
					case 13 : BlendMode.OVERLAY;
					case 14 : BlendMode.HARDLIGHT;
					default: BlendMode.NORMAL;
				}
				
			}
			
			if (hasBlendMode) {
				
				cacheAsBitmap = stream.readByte () > 0;
				
			}
			
			if (hasClipAction) {
				
				var reserved = stream.readID ();
				var actionFlags = stream.readID ();
				
				throw("clip action not implemented");
				
			}
			
			if (move) {
				
				if (hasCharacter) {
					
					frame.remove (depth);
					frame.place (cid, swf.getCharacter (cid), depth, matrix, colorTransform, ratio, name);
					
				} else {
					
					frame.move (depth, matrix, colorTransform, ratio);
					
				}
				
			} else {
				
				frame.place (cid, swf.getCharacter (cid), depth, matrix, colorTransform, ratio, name);
				
			}
			
		} else {
			
			throw ("Place object not implemented: " + version);
			
		}
		
	}
	
	
	public function removeObject (stream:SWFStream, version:Int):Void {
		
		if (version == 1) {
			
			stream.readID ();
			
		}
		
		var depth = stream.readDepth ();
		frame.remove (depth);
		
	}
	
	
	public function showFrame ():Void {
		
		frames.push (frame);
		frame = new Frame (frame);
		
	}
	
	
}