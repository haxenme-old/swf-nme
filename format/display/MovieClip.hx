package format.display;
#if !openfl


import flash.display.Sprite;

/**
 * Base class for MovieClip-related format libraries
 * 
 * Cannot use flash.display.MovieClip, because it does
 * not allow the addition for frames or frame labels at
 * runtime, asynchronously
 */
class MovieClip extends Sprite {
	
	
	public var currentFrame (default, null):Int;
	public var currentFrameLabel (default, null):String;
	public var currentLabel (default, null):String;
	public var currentLabels (default, null):Array <FrameLabel>;
	//public var currentScene (default, null):Scene;
	public var enabled:Bool;
	public var framesLoaded (default, null):Int;
	//public var scenes (default, null):Array <Scene>;
	public var totalFrames (default, null):Int;
	public var trackAsMenu:Bool;
	
	
	function new () {
		
		super ();
		
	}
	
	
	public function flatten ():Void {
		
		
		
	}
	
	
	public function gotoAndPlay (frame:Dynamic, scene:String = null):Void {
		
		
		
	}
	
	
	public function gotoAndStop (frame:Dynamic, scene:String = null):Void {
		
		
		
	}
	
	
	public function nextFrame ():Void {
		
		
		
	}
	
	
	/*public function nextScene ():Void {
		
		
		
	}*/
	
	
	public function play ():Void {
		
		
		
	}
	
	
	public function prevFrame ():Void {
		
		
		
	}
	
	
	public function stop ():Void {
		
		
		
	}
	
	
	public function unflatten ():Void {
		
		
		
	}
	
	
}


#else


class MovieClip extends flash.display.MovieClip {
	
	
	#if !flash
	public var currentFrameLabel (default, null):String;
	public var currentLabel (default, null):String;
	public var currentLabels (default, null):Array <FrameLabel>;
	#else
	private var __currentFrame:Int;
	private var __totalFrames:Int;
	#end
	
	
	function new () {
		
		super ();
		
	}
	
	
	public function flatten ():Void {
		
		
		
	}
	
	
	public function unflatten ():Void {
		
		
		
	}
	
	
	#if flash
	@:getter public function get_currentFrame():Int {
		
		return __currentFrame;
		
	}
	
	
	@:getter public function get___framesLoaded():Int {
		
		return __totalFrames;
		
	}
	
	
	@:getter public function get___totalFrames():Int {
		
		return __totalFrames;
		
	}
	#end
	
	
}


#end