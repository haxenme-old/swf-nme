package format.swf;

import format.swf.Character;
import format.swf.DisplayAttributes;
import flash.geom.ColorTransform;
import flash.geom.Matrix;


class DepthSlot {
	
	
	public var id:Int;
	public var attributes:Array <DisplayAttributes>;
	public var character:Character;
	
	private var cacheAttributes:DisplayAttributes;


	public function new (character:Character, characterID:Int, attributes:DisplayAttributes) {
		
		this.character = character;
		id = characterID;
		
		this.attributes = [];
		this.attributes.push (attributes);
		
		cacheAttributes = attributes;
		
	}
	
	
	public function findClosestFrame (hintFrame:Int, frame:Int):Int {
		
		var last = hintFrame;
		
		if (last >= attributes.length) {
			
			last = 0;
			
		} else if (last > 0) {
			
			if (attributes[last - 1].frame > frame) {
				
				last = 0;
				
			}
			
		}
		
		for (i in last...attributes.length) {
			
			if (attributes[i].frame > frame) {
				
				return last;
				
			}
			
			last = i;
			
		}
		
		return last;
		
	}
	
	
	public function move (frame:Int, matrix:Matrix, colorTransform:ColorTransform, ratio:Null <Int>):Void {
		
		cacheAttributes = cacheAttributes.clone ();
		cacheAttributes.frame = frame;
		
		if (matrix != null) {
			
			cacheAttributes.matrix = matrix;
			
		}
		
		if (colorTransform != null) {
			
			cacheAttributes.colorTransform = colorTransform;
			
		}
		
		if (ratio != null) {
			
			cacheAttributes.ratio = ratio;
			
		}
		
		attributes.push (cacheAttributes);
		
	}
	
	
}