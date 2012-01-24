package format.swf;

import nme.geom.Matrix;
import nme.geom.ColorTransform;

import format.swf.SWFStream;
import format.swf.Tags;
import format.swf.Character;
import format.swf.Frame;
import format.SWF;
import nme.display.BlendMode;
import nme.filters.BitmapFilter;

typedef FrameLabels = Hash<Int>;


class Sprite
{
   public var mSWF(default,null) : SWF;
   public var mFrames(default,null):Array <Frame>;
   var mFrameCount : Int;
   var mFrame:Frame;
   var mFrameLabels:FrameLabels;
   var mName:String;
   var mClassName:String;
   var mBlendMode:BlendMode;
   var mCacheAsBitmap:Bool;
   var mFilters:Array<BitmapFilter>;

   public function new(inSWF:SWF,inID:Int,inFrameCount:Int)
   {
      mSWF = inSWF;
      mFrameCount = inFrameCount;
      mFrames = [ null ]; // frame 0 is empty

      mFilters = null;
      mFrame = new Frame();
      mFrameLabels = new FrameLabels();
      mName = "Sprite " + inID;
      mCacheAsBitmap = false;
   }

   public function GetFrameCount() { return mFrameCount; }

   public function LabelFrame(inName:String)
   {
      mFrameLabels.set(inName,mFrame.frame);
   }

   public function ShowFrame()
   {
      mFrames.push(mFrame);
      mFrame = new Frame(mFrame);
   }

   public function RemoveObject(inStream:SWFStream,inVersion:Int)
   {
      if (inVersion==1)
        inStream.readID();
      var depth = inStream.readDepth();
      mFrame.remove(depth);
   }

   public function PlaceObject(inStream:SWFStream,inVersion : Int)
   {
      if (inVersion==1)
      {
         var id = inStream.readID();
         var chr = mSWF.getCharacter(id);
         var depth = inStream.readDepth();
         var matrix = inStream.readMatrix();
         var col_tx:ColorTransform = inStream.getBytesLeft()>0 ?
                 inStream.readColorTransform(false) : null;
         mFrame.place(id,chr,depth,matrix,col_tx,null,null);
      }
      else if (inVersion==2 || inVersion==3)
      {
         inStream.alignBits();
         var has_clip_action = inStream.readBool();
         var has_clip_depth = inStream.readBool();
         var has_name = inStream.readBool();
         var has_ratio = inStream.readBool();
         var has_color_tx = inStream.readBool();
         var has_matrix = inStream.readBool();
         var has_character = inStream.readBool();
         var move = inStream.readBool();

         var has_image = false;
         var has_class_name = false;
         var has_cache_as_bmp = false;
         var has_blend_mode = false;
         var has_filter_list = false;
         if (inVersion==3)
         {
            inStream.readBool();
            inStream.readBool();
            inStream.readBool();
            has_image = inStream.readBool();
            has_class_name = inStream.readBool();
            has_cache_as_bmp = inStream.readBool();
            has_blend_mode = inStream.readBool();
            has_filter_list = inStream.readBool();
         }

         var depth = inStream.readDepth();

         if (has_class_name)
            mClassName = inStream.readString();
         var cid = has_character ? inStream.readID() : 0;

         var matrix = has_matrix ? inStream.readMatrix() : null;

         var col_tx = has_color_tx ? inStream.readColorTransform(inVersion>2) : null;

         var ratio:Null<Int> = has_ratio ? inStream.readUInt16() : null;

         if (has_name || (has_image && has_character) )
           mName = inStream.readString();


         var clip_depth = has_clip_depth ? inStream.readDepth() : 0;
         if (has_filter_list)
         {
            mFilters = [];
            var n = inStream.readByte();
            for(i in 0...n)
            {
               var fid = inStream.readByte();
               mFilters.push(
                  switch(fid)
                  {
                     case 0 : CreateDropShadowFilter(inStream);
                     case 1 : CreateBlurFilter(inStream);
                     case 2 : CreateGlowFilter(inStream);
                     case 3 : CreateBevelFilter(inStream);
                     case 4 : CreateGradientGlowFilter(inStream);
                     case 5 : CreateConvolutionFilter(inStream);
                     case 6 : CreateColorMatrixFilter(inStream);
                     case 7 : CreateGradientBevelFilter(inStream);
                     default: throw "Unknown filter : " + fid + "  " + i + "/" +n; 
                  }
               );
            }
         }
         if (has_blend_mode)
         {
            mBlendMode = switch( inStream.readByte() )
            {
               case 2 : BlendMode.LAYER;
               case 3 : BlendMode.MULTIPLY;
               case 4 : BlendMode.SCREEN;
               case 5 : BlendMode.LIGHTEN;
               case 6 : BlendMode.DARKEN;
               case 7 : BlendMode.DIFFERENCE;
               case 8 : BlendMode.ADD;
               case 9 : BlendMode.SUBTRACT;
               case 10 : BlendMode.INVERT;
               case 11 : BlendMode.ALPHA;
               case 12 : BlendMode.ERASE;
               case 13 : BlendMode.OVERLAY;
               case 14 : BlendMode.HARDLIGHT;
               default:
                   BlendMode.NORMAL;
            }
         }
         if (has_blend_mode)
         {
            mCacheAsBitmap = inStream.readByte()>0;
         }


         if (has_clip_action)
         {
            var reserved = inStream.readID();
            var action_flags = inStream.readID();
            throw("clip action not implemented");
         }

         if (move)
         {
            if (has_character)
            {
               mFrame.remove(depth);
               mFrame.place(cid,mSWF.getCharacter(cid),depth,matrix,col_tx,ratio,mName);
            }
            else
            {
               mFrame.move(depth,matrix,col_tx,ratio);
            }
         }
         else
         {
            mFrame.place(cid,mSWF.getCharacter(cid),depth,matrix,col_tx,ratio,mName);
         }
      }
      else
      {
         throw("place object not implemented:" + inVersion);
      }
   }

   function CreateDropShadowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateDropShadowFilter");
      return null;
   }

   function CreateBlurFilter(inStream:SWFStream) : BitmapFilter
   {
      //trace("CreateBlurFilter");
      var blurx = inStream.readFixed();
      var blury = inStream.readFixed();
      var passes = inStream.readByte();
      //trace(blurx + "x" + blury + "  x " + passes);
      return null;
   }

   function CreateGlowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGlowFilter");
      return null;
   }

   function CreateBevelFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateBevelFilter");
      return null;
   }

   function CreateGradientGlowFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGradientGlowFilter");
      return null;
   }

   function CreateConvolutionFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateConvolutionFilter");
      var w = inStream.readByte();
      var h = inStream.readByte();
      var div = inStream.readFloat();
      var bias = inStream.readFloat();
      var mtx = new Array<Float>();
      for(i in 0...w*h)
         mtx[i] = inStream.readFloat();
      var flags = inStream.readByte();
      return null;
   }

   function CreateColorMatrixFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateColorMatrixFilter");
      var mtx = new Array<Float>();
      for(i in 0...20)
         mtx.push( inStream.readFloat() );

      return null;
   }

   function CreateGradientBevelFilter(inStream:SWFStream) : BitmapFilter
   {
      trace("CreateGradientBevelFilter");
      return null;
   }



}
