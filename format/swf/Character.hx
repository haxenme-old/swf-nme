package format.swf;


import format.swf.Bitmap;
import format.swf.EditText;
import format.swf.Font;
import format.swf.MorphShape;
import format.swf.Shape;
import format.swf.Sprite;
import format.swf.StaticText;


enum Character {
	
	charShape (data:Shape);
	charMorphShape (data:MorphShape);
	charSprite (data:Sprite);
	charBitmap (data:Bitmap);
	charFont (data:Font);
	charStaticText (data:StaticText);
	charEditText (data:EditText);
	
}