package format.swf.data;


import flash.filters.BitmapFilter;
import flash.geom.ColorTransform;
import flash.geom.Matrix;
import format.swf.symbol.Symbol;

#if haxe3
import haxe.ds.IntMap;
#else
typedef IntMap<T> = IntHash<T>;
#end


class Frame {
	
	
	public var frame:Int;
	
	private var objects:IntMap <DepthSlot>;
	
	
	public function new (previous:Frame = null) {
		
		objects = new IntMap <DepthSlot> ();
		
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
	
	
	public function copyObjectSet ():IntMap <DepthSlot> {
		
		var copy = new IntMap <DepthSlot> ();
		
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
	
	
	public function place (symbolID:Int, symbol:Symbol, depth:Int, matrix:Matrix, colorTransform:ColorTransform, ratio:Null<Int>, name:Null<String>, filters:Null<Array<BitmapFilter>>):Void {
		
		var previousObject = objects.get (depth);
		
		if (previousObject != null) {
			
			if (matrix == null) {
				
				matrix = previousObject.attributes[0].matrix;
				
			}
			
			//throw("Overwriting non-empty depth");
			
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
		
		attributes.filters = filters;
		attributes.symbolID = symbolID;
		
		var object = new DepthSlot (symbolID, symbol, attributes);
		objects.set (depth, object);
		
	}
	
	
	public function remove (depth:Int):Void {
		
		objects.remove (depth);
		
	}
	
	
}