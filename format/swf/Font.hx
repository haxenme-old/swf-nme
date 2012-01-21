package format.swf;

import format.swf.SWFStream;
import nme.display.Graphics;
import nme.geom.Matrix;

typedef FontCommand = Graphics -> Matrix -> Void;
typedef FontCommands = Array<FontCommand>;

typedef Glyph =
{
   var mCommands : FontCommands;
   var mAdvance  : Float;
}

typedef Glyphs = Array<Glyph>;

class Font
{
   var mGlyphs:Glyphs;
   var mCodeToGlyph:Glyphs;
   var mName:String;
   var mAscent:Float;
   var mDescent:Float;
   var mLeading:Float;
   var mAdvance:Array<Float>;


   public function new(inStream:SWFStream, inVersion:Int)
   {
      mGlyphs = [];

      inStream.alignBits();
      var has_layout = (inVersion>1) && inStream.readBool();
      var has_jis = (inVersion>1) && inStream.readBool();
      var small_text = (inVersion>1) && inStream.readBool();
      var is_ansi = (inVersion>1) && inStream.readBool();
      var wide_offsets = (inVersion>1) && inStream.readBool();
      var wide_codes = (inVersion>1) && inStream.readBool();
      var italic = (inVersion>1) && inStream.readBool();
      var bold = (inVersion>1) && inStream.readBool();
      var lang_code = (inVersion>1) ? inStream.readByte() : 0;
      mName = (inVersion>1) ?  inStream.readPascalString() : "font";
      //trace("Font name : " + mName);
      
      var n:Int;
      var s0:Int;
      var offsets = new Array<Int>();
      var code_offset = 0;

      var v3scale = inVersion>2 ?  1.0 : 0.05;

      if (inVersion>1)
      {
         n = inStream.readUInt16();
         s0 = inStream.getBytesLeft();
         for(i in 0...n)
         {
            offsets.push( wide_offsets ? inStream.readInt() :
                                         inStream.readUInt16() );
         }
         code_offset = wide_offsets ? inStream.readInt() : inStream.readUInt16();
         code_offset = s0-code_offset;
      }
      else
      {
         s0 = inStream.getBytesLeft();
         var o0 = inStream.readUInt16();
         // Deduce N from first offset ...
         n = o0 >> 1;

         offsets.push(o0);
         for(i in 1...n)
            offsets.push( inStream.readUInt16() );
      }

      var access_last = mGlyphs[n-1];

      inStream.alignBits();
      // Now read glyphs ...
      for(i in 0...n)
      {
         if (inStream.getBytesLeft() != (s0-offsets[i]))
            throw("bad offset in font stream (" +
                    inStream.getBytesLeft() +"!="+ (s0-offsets[i]) + ")");

         var moved = false;
         var pen_x = 0.0;
         var pen_y = 0.0;
         var commands = new FontCommands();

         inStream.alignBits();
         var fill_bits = inStream.readBits(4);
         var line_bits = inStream.readBits(4);


         while(true)
         {
            var edge = inStream.readBool();
            if (!edge)
            {
                var new_styles = inStream.readBool();
                var new_line_style = inStream.readBool();
                var new_fill_style1 = inStream.readBool();
                var new_fill_style0 = inStream.readBool();
                var move_to = inStream.readBool();

                if (new_styles || new_styles || new_fill_style1)
                   throw("fill style can't be changed here " +
                        new_styles +","+ new_styles +","+ new_fill_style0);

                // Done ?
                if (!move_to)
                   break;

                if (!new_fill_style0 && commands.length==0)
                   throw("fill style should be defined");

                var bits = inStream.readBits(5);
                pen_x = inStream.readTwips(bits)*v3scale;
                pen_y = inStream.readTwips(bits)*v3scale;
                var px = pen_x;
                var py = pen_y;

                //trace("Move : " + pen_x + "," + pen_y);
                commands.push( function(g:Graphics,m:Matrix)
                   { //trace ("moveTo(" + (px * m.a + py * m.c + m.tx) + ", " + (px * m.b + py * m.d + m.ty) + ");");
					   g.moveTo(px*m.a+py*m.c+m.tx, px*m.b+py*m.d+m.ty);} );

                if (new_fill_style0)
                {
                   var fill_style = inStream.readBits(1);
                }

            }
            else
            {
               // Straight
               if (inStream.readBool())
               {
                  var delta_bits = inStream.readBits(4) + 2;
                  if (inStream.readBool())
                  {
                     pen_x += inStream.readTwips(delta_bits)*v3scale;
                     pen_y += inStream.readTwips(delta_bits)*v3scale;
                  }
                  else if (inStream.readBool())
                     pen_y += inStream.readTwips(delta_bits)*v3scale;
                  else
                     pen_x += inStream.readTwips(delta_bits)*v3scale;
      
                  var px = pen_x;
                  var py = pen_y;
                  //trace("Line to : " + px + "," + py );
                  commands.push( function(g:Graphics,m:Matrix)
                     { //trace ("lineTo(" + (px*m.a+py*m.c+m.tx) + ", " + (px*m.b+py*m.d+m.ty) + ");");
						 g.lineTo(px*m.a+py*m.c+m.tx, px*m.b+py*m.d+m.ty);} );
               }
               // Curved ...
               else
               {
                  var delta_bits = inStream.readBits(4) + 2;
                  var cx = pen_x + inStream.readTwips(delta_bits)*v3scale;
                  var cy = pen_y + inStream.readTwips(delta_bits)*v3scale;
                  var px = cx + inStream.readTwips(delta_bits)*v3scale;
                  var py = cy + inStream.readTwips(delta_bits)*v3scale;
                  // Can't push "pen_x/y" in closure because it uses a reference
                  //  to the member variable, not a copy of the current value.
                  pen_x = px;
                  pen_y = py;
                  //trace("Curve to : " + px + "," + py );
                  commands.push( function(g:Graphics,m:Matrix)
                     { //trace ("curveTo(" + (cx*m.a+cy*m.c+m.tx) + ", " + (cx*m.b+cy*m.d+m.ty) + ", " + (px*m.a+py*m.c+m.tx) + ", " + (px*m.b+py*m.d+m.ty) + ");");
						 g.curveTo(cx*m.a+cy*m.c+m.tx, cx*m.b+cy*m.d+m.ty,
                         px*m.a+py*m.c+m.tx, px*m.b+py*m.d+m.ty);} );
               }
            }
         }

         commands.push(  function(g:Graphics, m:Matrix) { g.endFill(); } );

         mGlyphs[i] = { mCommands:commands, mAdvance:1024.0 };
      }



      // And codes ...
      if (code_offset!=0)
      {
         inStream.alignBits();

         if (inStream.getBytesLeft() != code_offset)
            throw("Code offset miscaculation");

         mCodeToGlyph = new Glyphs();

         for(i in 0...n)
         {
            var code = wide_codes ? inStream.readUInt16() : inStream.readByte();
            //trace("Char " + Std.chr(code) + "=" + i);
            mCodeToGlyph[code] = mGlyphs[i];
         }

      }
      else
         mCodeToGlyph = mGlyphs;

      if (has_layout)
      {
         mAscent = inStream.readSTwips();
         mDescent = inStream.readSTwips();
         mLeading = inStream.readSTwips();

         mAdvance = new Array<Float>();
         for(i in 0...n)
            mGlyphs[i].mAdvance = inStream.readSTwips();
      }
      else
      {
         mAscent = 800;
         mDescent = 224;
         mLeading = 0;
      }

      //RenderGlyph( new nme.display.DebugGfx(), 1, new Matrix() );

      // TODO:
      //nme.text.FontManager.RegisterFont(this);
   }

   function RestoreLineStyle(g:Graphics)
   {
      //g.lineStyle(1,0x000000);
   }

   public function Ok() { return true; }


   // GlyphRenderer API
   public function GetName() : String { return mName; }

   public function RenderChar(inGraphics:Graphics,inChar:Int,m:Matrix) : Float
   {
      if (mCodeToGlyph.length>inChar)
      {
         var glyph = mCodeToGlyph[inChar];
         if (glyph!=null)
         {
            for(c in glyph.mCommands)
               c(inGraphics,m);
            return glyph.mAdvance;
         }
      }
      return 0;
   }


   public function RenderGlyph(inGraphics:Graphics,inGlyph:Int,m:Matrix) : Void
   {
      if (mGlyphs.length>inGlyph)
      {
         var commands = mGlyphs[inGlyph].mCommands;
         for(c in commands)
            c(inGraphics,m);
      }
      else
      {
         trace("Unsupported glyph: " + String.fromCharCode(inGlyph) );
      }
   }

   public function GetAdvance(inChar:Int, ?inNext:Null<Int>) : Float
   {
      if (mCodeToGlyph.length>inChar)
      {
         var glyph = mCodeToGlyph[inChar];
         if (glyph!=null)
            return glyph.mAdvance;
      }

      return 1024.0;
   }

   public function GetAscent() : Float { return mAscent; }
   public function GetDescent() : Float { return mDescent; }
   public function GetLeading() : Float { return mLeading; }



}
