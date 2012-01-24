package format.swf;


import format.swf.Character;
import format.swf.DepthSlot;
import format.swf.DisplayAttributes;
import flash.geom.Matrix;
import flash.geom.ColorTransform;


class Frame {
	
	
	public var frame:Int;
	
	private var objects:IntHash <DepthSlot>;
	
	
	public function new (previous:Frame = null) {
		
		objects = new IntHash <DepthSlot> ();
		
		if (previous != null) {
			
			var previousObjects = previous.objects;
			
			for (depth in previousObjects.keys ()) {
				
				objects.set (depth, previousObjects.get (depth));
				
			}
			
			frame = previous.frame + 1;
			
		} else {
			
			frame = 1;
			
		}
		
	}
	
	
	public function copyObjectSet ():IntHash <DepthSlot> {
		
		var copy = new IntHash <DepthSlot> ();
		
		for (depth in objects.keys ()) {
			
			copy.set (depth, objects.get (depth));
			
		}
		
		return copy;
		
	}
	
	
	public function move (depth:Int, matrix:Matrix, colorTransform:ColorTransform, ratio:Null<Int>):Void {
		
		var object = objects.get (depth);
		
		if (object == null) {
			
			throw ("Depth has no object");
			
		}
		
		object.move (frame, matrix, colorTransform, ratio);
		
	}
	
	
	public function place (characterID:Int, character:Character, depth:Int, matrix:Matrix, colorTransform:ColorTransform, ratio:Null<Int>, name:Null<String>):Void {
		
		var previousObject = objects.get (depth);
		
		if (previousObject != null) {
			
			throw("Overwriting non-empty depth");
			
		}
		
		var attributes = new DisplayAttributes ();
		attributes.frame = frame;
		attributes.matrix = matrix;
		attributes.colorTransform = colorTransform;
		attributes.ratio = ratio;
		
		if (name == null) {
			
			attributes.name = "";
			
		} else {
			
			attributes.name = name;
			
		}
		
		attributes.characterID = characterID;
		
		var object = new DepthSlot (character, characterID, attributes);
		objects.set (depth, object);
		
	}
	
	
	public function remove (depth:Int):Void {
		
		objects.remove (depth);
		
	}
	
	
}