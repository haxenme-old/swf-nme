package format.swf;


import format.SWF;
import format.swf.Sprite;
import format.swf.Frame;
import flash.display.DisplayObject;
import flash.display.Shape;
import flash.events.Event;
import flash.text.TextField;


#if flash
typedef MovieClipBase = flash.display.Sprite;
#else
typedef MovieClipBase = flash.display.MovieClip;
#end


class MovieClip extends MovieClipBase {
	
	
	private static var movieID = 0;
	private static var previousMovieID = 1;
	
	private var activeObjects:Array <ActiveObject>;
	private var frames:Array <Frame>;
	private var objectPool:IntHash <List <DisplayObject>>;
	private var playing:Bool;
	private var swf:SWF;

	#if flash
	private var mCurrentFrame:Int;
	private var mTotalFrames:Int;
	#end
	
	
	public function new (data:Sprite = null) {
		
		super ();
		
		#if flash
		mCurrentFrame = 1;
		mTotalFrames = 1;
		#end
		
		objectPool = new IntHash <List <DisplayObject>> ();
		
		movieID = previousMovieID ++;
		playing = false;
		
		if (data != null) {
			
			mTotalFrames = data.frameCount;
			mCurrentFrame = mTotalFrames;
			
			swf = data.swf;
			frames = data.frames;
			activeObjects = new Array <ActiveObject> ();
			
			gotoAndPlay (1);
			
		}
		
	}
	
	
	#if !flash override #end
	public function gotoAndPlay (frame:Dynamic, ?scene:String):Void {
		
		mCurrentFrame = frame;
		
		updateObjects ();
		play ();
		
	}
	
	
	#if !flash override #end
	public function gotoAndStop (frame:Dynamic, ?scene:String):Void {
		
		mCurrentFrame = frame;
		
		updateObjects ();
		stop ();
		
	}
	
	
	#if !flash override #end
	public function play ():Void {
		
		if (mTotalFrames > 1) {
			
			playing = true;
			addEventListener (Event.ENTER_FRAME, this_onEnterFrame);
			
		} else {
			
			stop ();
			
		}
		
	}
	
	
	#if !flash override #end
	public function stop ():Void {
		
		playing = false;
		removeEventListener (Event.ENTER_FRAME, this_onEnterFrame);
		
	}
	
	
	private function updateObjects ():Void {
		
		if (frames != null) {
			
			var frame = frames[mCurrentFrame];
			var depthChanged = false;
			var waitingLoader = false;
			
			if (frame != null) {
				
				var frameObjects = frame.copyObjectSet ();
				var newActiveObjects = new Array <ActiveObject> ();
				
				for (activeObject in activeObjects) {
					
					var depthSlot = frameObjects.get (activeObject.depth);
					
					if (depthSlot == null || depthSlot.id != activeObject.id || activeObject.waitingLoader) {
						
						// Add object to pool - if it's complete.
						
						if (!activeObject.waitingLoader) {
							
							var pool = objectPool.get (activeObject.id);
							
							if (pool == null) {
								
								pool = new List <DisplayObject> ();
								objectPool.set (activeObject.id, pool);
								
							}
							
							pool.push (activeObject.object);
							
						}
						
						// todo - disconnect event handlers ?
						removeChild (activeObject.object);
						
					} else {
						
						// remove from our "todo" list
						frameObjects.remove (activeObject.depth);
						
						activeObject.index = depthSlot.findClosestFrame (activeObject.index, mCurrentFrame);
						var attributes = depthSlot.attributes[activeObject.index];
						attributes.apply (activeObject.object);
						
						newActiveObjects.push (activeObject);
						
					}
					
				}
				
				// Now add missing characters in unfilled depth slots
				for (depth in frameObjects.keys ()) {
					
					var slot = frameObjects.get (depth);
					var displayObject:DisplayObject = null;
					var pool = objectPool.get (slot.id);
					
					if (pool != null && pool.length > 0) {
						
						displayObject = pool.pop ();
						
						switch (slot.character) {
							
							case charSprite (data):
								
								var clip:MovieClip = cast displayObject;
								clip.gotoAndPlay (1);
							
							default:
								
							
						}
						
					} else {               
						
						switch (slot.character) {
							
							case charSprite(sprite):
								
								var movie = new MovieClip (sprite);
								displayObject = movie;
							
							case charShape(shape):
								
								var s = new Shape ();
								s.cacheAsBitmap = true; // temp fix
								//shape.Render(new nme.display.DebugGfx());
								waitingLoader = shape.render (s.graphics);
								displayObject = s;
							
							case charMorphShape (morphData):
								
								var morph = new MorphObject (morphData);
								//morph_data.Render(new nme.display.DebugGfx(),0.5);
								displayObject = morph;
							
							case charStaticText (text):
								
								var s = new Shape();
								s.cacheAsBitmap = true; // temp fix
								text.render (s.graphics);
								displayObject = s;
							
							case charEditText (text):
								
								var t = new TextField ();
								text.apply (t);
								displayObject = t;
							
							case charBitmap (shape):
								
								throw("Adding bitmap?");
							
							case charFont(font):
								
								throw("Adding font?");
							
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
					
					var idx = slot.findClosestFrame (0, mCurrentFrame);
					slot.attributes[idx].apply (displayObject);
					
					var act = { object: displayObject, depth: depth, index: idx, id: slot.id, waitingLoader: waitingLoader };
					
					newActiveObjects.push (act);
					depthChanged = true;
					
				}
				
				activeObjects = newActiveObjects;
				
			}
			
		}
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private function this_onEnterFrame (event:Event):Void {
		
		if (playing) {
			
			mCurrentFrame ++;
			
			if (mCurrentFrame > mTotalFrames) {
				
				mCurrentFrame = 1;
				
			}
			
			updateObjects ();
			
		}
		
	}
	
	
}


typedef ActiveObject =
{
	var object:DisplayObject;
	var depth:Int;
	var id:Int;
	var index:Int;
	var waitingLoader:Bool;
}