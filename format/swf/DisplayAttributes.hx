package format.swf;


import flash.display.DisplayObject;
import flash.geom.ColorTransform;
import flash.geom.Matrix;


class DisplayAttributes {
	
	
	public var characterID:Int;
	public var colorTransform:ColorTransform;
	public var frame:Int;
	public var matrix:Matrix;
	public var name:String;
	public var ratio:Null<Int>;
	
	
	public function new () {
		
		
		
	}
	
	
	public function apply (object:DisplayObject) {
		
		if (matrix != null) {
			
			object.transform.matrix = matrix.clone ();
			
		}
		
		object.name = name;
		
		if (ratio != null && Std.is (object, MorphObject)) {
			
			var morph:MorphObject = untyped object;
			return morph.SetRatio (ratio);
			
		}
		
		return false;
		
	}
	
	
	public function clone ():DisplayAttributes {
		
		var copy = new DisplayAttributes ();
		
		copy.frame = frame;
		copy.matrix = matrix;
		copy.colorTransform = colorTransform;
		copy.ratio = ratio;
		copy.name = name;
		copy.characterID = characterID;
		
		return copy;
		
	}
	
	
}