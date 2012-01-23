package format.swf;

import format.swf.SWFStream;
import format.SWF;
import nme.display.Graphics;

import nme.geom.Rectangle;
import nme.geom.Matrix;

typedef TextRecord =
{
   var mSWFFont:Font;

   var mOffsetX:Int;
   var mOffsetY:Int;
   var mHeight:Float;

   var mColour:Int;
   var mAlpha:Float;

   var mGlyphs:Array<Int>;
   var mAdvances:Array<Int>;
}

typedef TextRecords = Array<TextRecord>;

class StaticText
{
   var mBounds:Rectangle;
   var mTextMatrix:Matrix;
   var mRecords:TextRecords;


   public function new(inSWF:SWF, inStream:SWFStream, inVersion:Int)
   {
      inStream.alignBits();

      mRecords = new TextRecords();
      mBounds = inStream.readRect();
      //trace("StaticText " + mBounds);

      mTextMatrix = inStream.readMatrix();

      var glyph_bits = inStream.readByte();
      var advance_bits = inStream.readByte();
      var font:Font = null;
      var height = 32.0;
      var colour = 0;
      var alpha = 1.0;

      inStream.alignBits();
      while(inStream.readBool())
      {
         inStream.readBits(3);
         var has_font = inStream.readBool();
         var has_colour = inStream.readBool();
         var has_y = inStream.readBool();
         var has_x = inStream.readBool();
         if (has_font)
         {
            var font_id = inStream.readID();
            var ch = inSWF.getCharacter(font_id);
            switch(ch)
            {
               case charFont(f):
                  font = f;
               default:
                  throw "Not font character";
            }
         }
         else if (font==null)
            throw "No font - not implemented";

         if (has_colour)
         {
            colour = inStream.readRGB();
            if (inVersion>=2)
               alpha = inStream.readByte()/255.0;
         }

         var x_off = has_x ? inStream.readSInt16() : 0;
         var y_off = has_y ? inStream.readSInt16() : 0;
         if (has_font)
            height = inStream.readUInt16() * 0.05;
         var count = inStream.readByte();

         //trace("Glyphs : " + count);

         var glyphs = new Array<Int>();
         var advances = new Array<Int>();

         for(i in 0...count)
         {
            glyphs.push( inStream.readBits(glyph_bits) );
            advances.push( inStream.readBits(advance_bits,true) );
         }

         mRecords.push( {  mSWFFont:font,
                           mOffsetX : x_off,
                           mOffsetY : y_off,
                           mGlyphs : glyphs,
                           mColour : colour,
                           mAlpha : alpha,
                           mHeight : height,
                           mAdvances : advances } );


         inStream.alignBits();
      }
   }

   public function Render(inGfx:Graphics)
   {
      for(rec in mRecords)
      {
         var scale = rec.mHeight/1024;
         var m = mTextMatrix.clone();
         m.scale(scale,scale);
         m.tx += rec.mOffsetX * 0.05;
         m.ty +=  rec.mOffsetY * 0.05;
         inGfx.lineStyle();
         for(i in 0...rec.mGlyphs.length)
         {
            var tx = m.tx;
            inGfx.beginFill(rec.mColour,rec.mAlpha);
            rec.mSWFFont.renderGlyph(inGfx,rec.mGlyphs[i], m );
            inGfx.endFill();
            m.tx += rec.mAdvances[i] * 0.05;
         }
      }
   }

}
