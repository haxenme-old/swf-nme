package format.swf;

import nme.geom.Rectangle;
import nme.text.TextField;
import nme.text.TextFieldType;
import nme.text.TextFormat;
import nme.text.TextFieldAutoSize;

import format.SWF;
import format.swf.SWFStream;

class EditText
{
   var mRect:Rectangle;
   var mWordWrap:Bool;
   var mMultiLine:Bool;
   var mPassword:Bool;
   var mReadOnly:Bool;
   var mAutoSize:Bool;
   var mNoSelect:Bool;
   var mBorder:Bool;
   var mWasStatic:Bool;
   var mHTML:Bool;
   var mUseOutlines:Bool;
   var mAlpha:Float;
   var mMaxLen:Int;
   var mInitialText:String;
   var mTextFormat:TextFormat;

   public function new(inSWF:SWF,inStream:SWFStream, inVersion:Int)
   {
      mRect = inStream.readRect();
      mTextFormat = new TextFormat();
      inStream.alignBits();
      //trace(mRect);
      var has_text = inStream.readBool();
      mWordWrap = inStream.readBool();
      mMultiLine = inStream.readBool();
      //trace(mMultiLine);
      mPassword = inStream.readBool();
      mReadOnly = inStream.readBool();
      var has_colour = inStream.readBool();
      //trace(has_colour);
      var has_max_len = inStream.readBool();
      //trace(has_max_len);
      var has_font = inStream.readBool();
      //trace("has font:" + has_font);
      var has_font_class = inStream.readBool();
      //trace("has font class:" + has_font_class);
      mAutoSize = inStream.readBool();
      var has_layout = inStream.readBool();
      mNoSelect = inStream.readBool();
      mBorder = inStream.readBool();
      mWasStatic = inStream.readBool();
      mHTML = inStream.readBool();
      mUseOutlines = inStream.readBool();
      //trace("Use outlines:" + mUseOutlines);

      if (has_font)
      {
         var font_id = inStream.readID();
         switch(inSWF.getCharacter(font_id))
         {
            case charFont(font):
               mTextFormat.font = font.GetName();

               //trace("Font :" + mFont.GetName());
            default:
               throw("Specified font is incorrect type");
         }
         mTextFormat.size = inStream.readUTwips();
      }
      else if (has_font_class)
      {
         var font_name = inStream.readString();
         throw("Can't reference external font :" + font_name);
      }
      
      if (has_colour)
      {
         mTextFormat.color = inStream.readRGB();
         mAlpha = inStream.readByte() / 255.0;
      }

      mMaxLen = has_max_len ? inStream.readUInt16() : 0;
      //trace("MaxLen : " + mMaxLen );
      if (has_layout)
      {
         mTextFormat.align = inStream.readAlign();
         mTextFormat.leftMargin = inStream.readUTwips();
         mTextFormat.rightMargin = inStream.readUTwips();
         mTextFormat.indent = inStream.readUTwips();
         mTextFormat.leading = inStream.readSTwips();
      }

      var var_name = inStream.readString();
      mInitialText = has_text ? inStream.readString() : "";
      //trace(mInitialText);
      
   }
   
   public function Apply(inText:TextField)
   {
      inText.wordWrap = mWordWrap;
      inText.multiline = mMultiLine;
      inText.width = mRect.width;
      inText.height = mRect.height;
      inText.displayAsPassword = mPassword;
      if (mMaxLen > 0)
         inText.maxChars = mMaxLen;
      inText.border = mBorder;
      inText.borderColor = 0x000000;
      inText.type = mReadOnly ? TextFieldType.DYNAMIC : TextFieldType.INPUT;
      inText.autoSize = mAutoSize ? TextFieldAutoSize.CENTER : TextFieldAutoSize.NONE;
      inText.setTextFormat(mTextFormat);

      
      //inText.embedFonts = mUseOutlines;

      
      if (mHTML)
         inText.htmlText = mInitialText;
      else
         inText.text = mInitialText;

      // if (!mReadOnly) inText.stage.focus = inText;
   }
   
   

}
