package format.swf;


import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.events.Event;
import flash.text.TextField;
import format.display.FrameLabel;
import format.swf.data.Frame;
import format.SWF;

#if haxe3
import haxe.ds.IntMap;
#else
typedef IntMap<T> = IntHash<T>;
#end


class MovieClip extends format.display.MovieClip {
	
	
	private var activeObjects:Array <ActiveObject>;
	private var frames:Array <Frame>;
	private var objectPool:IntMap <List <DisplayObject>>;
	private var playing:Bool;
	private var swf:SWF;
	
	
	public function new (data:format.swf.symbol.Sprite = null) {
		
		super ();
		
		objectPool = new IntMap <List <DisplayObject>> ();
		
		enabled = true;
		playing = false;
		
		#if (!openfl || !flash)
		currentFrameLabel = null;
		currentLabel = null;
		currentLabels = new Array <FrameLabel> ();
		#end
		
		if (data != null) {
			
			#if openfl __totalFrames #else totalFrames #end = data.frameCount;
			#if openfl __currentFrame #else currentFrame #end = #if openfl __totalFrames #else totalFrames #end;
			#if (!openfl || !flash)
			framesLoaded = #if openfl __totalFrames #else totalFrames #end;
			#end
			
			swf = data.swf;
			frames = data.frames;
			
			#if (!openfl || !flash)
			for (label in data.frameLabels.keys ()) {
				
				var frameLabel = new FrameLabel (data.frameLabels.get (label), label);
				currentLabels.push (frameLabel);
				
			}
			#end
			
			activeObjects = new Array <ActiveObject> ();
			
			//gotoAndPlay (1);
			#if openfl __currentFrame #else currentFrame #end = 1;
			updateObjects ();
			play ();
			
		} else {
			
			#if openfl __currentFrame #else currentFrame #end = 1;
			#if openfl __totalFrames #else totalFrames #end = 1;
			#if (!openfl || !flash)
			framesLoaded = 1;
			#end
			
		}
		
	}
	
	
	public override function flatten ():Void {
		
		// Should we support flatten + playing multiple frames?
		
		//if (#if flash #if openfl __totalFrames #else totalFrames #end #else m#if openfl __totalFrames #else totalFrames #end #end == 1) {
			
			var bounds = getBounds (this);
			var bitmapData = new BitmapData (Std.int (bounds.right), Std.int (bounds.bottom), true, #if (neko && !haxe3) { a: 0, rgb: 0x000000 } #else 0x00000000 #end);
			bitmapData.draw (this);
			
			for (activeObject in activeObjects) {
				
				removeChild (activeObject.object);
				
			}
			
			var bitmap = new Bitmap (bitmapData);
			bitmap.smoothing = true;
			addChild (bitmap);
			
			var object:ActiveObject = { object: cast (bitmap, DisplayObject), depth: 0, symbolID: -1, index: 0, waitingLoader: false };
			
			activeObjects = [ object ];
			
		//} else {
			
			//trace ("Warning: Cannot flatten MovieClips with multiple frames (yet)");
			
		//}
		
	}
	
	
	public override function gotoAndPlay (frame:#if openfl flash.utils.Object #else Dynamic #end, scene:String = null):Void {
		
		if (frame != #if openfl __currentFrame #else currentFrame #end) {
			
			if (Std.is (frame, String)) {
				
				for (frameLabel in currentLabels) {
					
					if (frameLabel.name == frame) {
						
						#if openfl __currentFrame #else currentFrame #end = frameLabel.frame;
						break;
						
					}
					
				}
				
			} else {
				
				#if openfl __currentFrame #else currentFrame #end = frame;
				
			}
			
			updateObjects ();
			
		}
		
		play ();
		
	}
	
	
	public override function gotoAndStop (frame:#if openfl flash.utils.Object #else Dynamic #end, scene:String = null):Void {
		
		if (frame != #if openfl __currentFrame #else currentFrame #end) {
			
			if (Std.is (frame, String)) {
				
				for (frameLabel in currentLabels) {
					
					if (frameLabel.name == frame) {
						
						#if openfl __currentFrame #else currentFrame #end = frameLabel.frame;
						break;
						
					}
					
				}
				
			} else {
				
				#if openfl __currentFrame #else currentFrame #end = frame;
				
			}
			
			updateObjects ();
			
		}
		
		stop ();
		
	}
	
	
	public override function nextFrame ():Void {
		
		var next = #if openfl __currentFrame #else currentFrame #end + 1;
		
		if (next > #if openfl __totalFrames #else totalFrames #end) {
			
			next = #if openfl __totalFrames #else totalFrames #end;
			
		}
		
		gotoAndStop (next);
		
	}
	
	
	/*public function nextScene ():Void {
		
		
		
	}*/
	
	
	public override function play ():Void {
		
		if (#if openfl __totalFrames #else totalFrames #end > 1) {
			
			playing = true;
			removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			
		} else {
			
			stop ();
			
		}
		
	}
	
	
	public override function prevFrame ():Void {
		
		var previous = #if openfl __currentFrame #else currentFrame #end - 1;
		
		if (previous < 1) {
			
			previous = 1;
			
		}
		
		gotoAndStop (previous);
		
	}
	
	
	public override function stop ():Void {
		
		playing = false;
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	public override function unflatten ():Void {
		
		updateObjects ();
		
	}
	
	
	private function updateObjects ():Void {
		
		if (frames != null) {
			
			var frame = frames[#if openfl __currentFrame #else currentFrame #end];
			var depthChanged = false;
			var waitingLoader = false;
			
			if (frame != null) {
				
				var frameObjects = frame.copyObjectSet ();
				var newActiveObjects = new Array <ActiveObject> ();
				
				for (activeObject in activeObjects) {
					
					var depthSlot = frameObjects.get (activeObject.depth);
					
					if (depthSlot == null || depthSlot.symbolID != activeObject.symbolID || activeObject.waitingLoader) {
						
						// Add object to pool - if it's complete.
						
						if (!activeObject.waitingLoader) {
							
							var pool = objectPool.get (activeObject.symbolID);
							
							if (pool == null) {
								
								pool = new List <DisplayObject> ();
								objectPool.set (activeObject.symbolID, pool);
								
							}
							
							pool.push (activeObject.object);
							
						}
						
						// todo - disconnect event handlers ?
						removeChild (activeObject.object);
						
					} else {
						
						// remove from our "todo" list
						frameObjects.remove (activeObject.depth);
						
						activeObject.index = depthSlot.findClosestFrame (activeObject.index, #if openfl __currentFrame #else currentFrame #end);
						var attributes = depthSlot.attributes[activeObject.index];
						attributes.apply (activeObject.object);
						
						newActiveObjects.push (activeObject);
						
					}
					
				}
				
				// Now add missing characters in unfilled depth slots
				for (depth in frameObjects.keys ()) {
					
					var slot = frameObjects.get (depth);
					var displayObject:DisplayObject = null;
					var pool = objectPool.get (slot.symbolID);
					
					if (pool != null && pool.length > 0) {
						
						displayObject = pool.pop ();
						
						switch (slot.symbol) {
							
							case spriteSymbol (_):
								
								var clip:MovieClip = cast displayObject;
								clip.gotoAndPlay (1);
							
							default:
								
							
						}
						
					} else {               
						
						switch (slot.symbol) {
							
							case spriteSymbol (sprite):
								
								var movie = new MovieClip (sprite);
								displayObject = movie;
							
							case shapeSymbol (shape):
								
								var s = new Shape ();
								
								if (shape.hasBitmapRepeat || shape.hasCurves || shape.hasGradientFill) {
									
									s.cacheAsBitmap = true; // temp fix
									
								}
								
								//shape.Render(new nme.display.DebugGfx());
								waitingLoader = shape.render (s.graphics);
								displayObject = s;
							
							case morphShapeSymbol (morphData):
								
								var morph = new MorphObject (morphData);
								//morph_data.Render(new nme.display.DebugGfx(),0.5);
								displayObject = morph;
							
							case staticTextSymbol (text):
								
								var s = new Shape();
								s.cacheAsBitmap = true; // temp fix
								text.render (s.graphics);
								displayObject = s;
							
							case editTextSymbol (text):
								
								var t = new TextField ();
								text.apply (t);
								displayObject = t;
							
							case bitmapSymbol (_):
								
								throw("Adding bitmap?");
							
							case fontSymbol (_):
								
								throw("Adding font?");
							
							case buttonSymbol (button):
								
								var b = new SimpleButton ();
								button.apply (b);
								displayObject = b;
							
						}
						
					}
					
					#if have_swf_depth
					// On neko, we can z-sort by using our special field ...
					displayObject.__swf_depth = depth;
					#end
					
					var added = false;
					
					// todo : binary converge ?
					
					for (cid in 0...numChildren) {
						
						#if have_swf_depth
						
						var childDepth = getChildAt (cid).__swf_depth;
						
						#else
						
						var childDepth = -1;
						var sought = getChildAt (cid);
						
						for (child in newActiveObjects) {
							
							if (child.object == sought) {
								
								childDepth = child.depth;
								break;
								
							}
							
						}
						
						#end
						
						if (childDepth > depth) {
							
							addChildAt (displayObject, cid);
							added = true;
							break;
							
						}
						
					}
					
					if (!added) {
						
						addChild (displayObject);
						
					}
					
					var idx = slot.findClosestFrame (0, #if openfl __currentFrame #else currentFrame #end);
					slot.attributes[idx].apply (displayObject);
					
					var act = { object: displayObject, depth: depth, index: idx, symbolID: slot.symbolID, waitingLoader: waitingLoader };
					
					newActiveObjects.push (act);
					depthChanged = true;
					
				}
				
				activeObjects = newActiveObjects;
				
				#if (!openfl || !flash)
				
				currentFrameLabel = null;
				
				for (frameLabel in currentLabels) {
					
					if (frameLabel.frame < frame.frame) {
						
						currentLabel = frameLabel.name;
						
					} else if (frameLabel.frame == frame.frame) {
						
						currentFrameLabel = frameLabel.name;
						currentLabel = currentFrameLabel;
						
						break;
						
					} else {
						
						break;
						
					}
					
				}
				
				#end
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (playing) {
			
			#if openfl __currentFrame #else currentFrame #end ++;
			
			if (#if openfl __currentFrame #else currentFrame #end > #if openfl __totalFrames #else totalFrames #end) {
				
				#if openfl __currentFrame #else currentFrame #end = 1;
				
			}
			
			updateObjects ();
			
		}
		
	}
	
	
}


typedef ActiveObject = {
	
	var object:DisplayObject;
	var depth:Int;
	var symbolID:Int;
	var index:Int;
	var waitingLoader:Bool;
	
}