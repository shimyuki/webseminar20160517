package common {
	import flash.display.*;
	import flash.text.*;
	import flash.events.*;
	import flash.geom.*;
	
	public class DynamicTextBtn_sizefix extends Sprite {
				
		protected var m_on:Shape;
		protected var m_clickObj:Sprite;
		protected var FONT_SIZE:Number;
		protected var FONT_COLOR:uint;
		protected var USE_LINE:Boolean = true;
		protected var LINE_COLOR:uint;
		protected var BASE_COLOR_01:uint;
		protected var BASE_COLOR_02:uint;
		protected const ELLIPSE_W:Number = 10;
		protected var m_text:TextField;
		
		public function DynamicTextBtn_sizefix( str:String, w:Number, h:Number,
											   baseColor01:uint = 0xffffff, baseColor02:uint = 0xe7e7e7,
											   fontColor:uint = 0x333333, fontSize:Number = 13, bold = false,
											   lineColor = null) {
			
			BASE_COLOR_01 = baseColor01;
			BASE_COLOR_02 = baseColor02;
			FONT_COLOR = fontColor;
			FONT_SIZE = fontSize;
			if( lineColor == null) USE_LINE = false;
			else LINE_COLOR = lineColor;
			
			m_text = new TextField();
			m_text.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), FONT_SIZE, FONT_COLOR, true);
			m_text.autoSize = TextFieldAutoSize.LEFT;
			m_text.text = str;
			
			// ベース
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox( w, h, - Math.PI / 2);
			var base:Shape = Shape( addChild( new Shape()));
			if( USE_LINE) base.graphics.lineStyle( 1, LINE_COLOR, 1, true);
			base.graphics.beginGradientFill( GradientType.LINEAR,
											[BASE_COLOR_02, BASE_COLOR_01],
											[1, 1],
											[0x00, 0xFF],
											matrix, SpreadMethod.PAD);
			base.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);
			base.graphics.endFill();
			
			// ONベース
			m_on = Shape( addChild( new Shape()));
			if( USE_LINE) m_on.graphics.lineStyle( 1, LINE_COLOR, 1, true);
			m_on.graphics.beginGradientFill( GradientType.LINEAR,
											[BASE_COLOR_01, BASE_COLOR_02],
											[1, 1],
											[0x00, 0xFF],
											matrix, SpreadMethod.PAD);
			m_on.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);
			m_on.graphics.endFill();
			m_on.visible = false;
		
			// テキスト配置
			m_text.x = ( w - m_text.width) / 2;
			m_text.y = ( h - m_text.height) / 2;
			addChild( m_text);
			
			m_clickObj = Sprite( addChild( new Sprite()));
			m_clickObj.graphics.beginFill( 0, 0);
			m_clickObj.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);
			m_clickObj.graphics.endFill();
			
		}
		
		public function resetText( str:String) {
			m_text.text = str;
		}
		
		public function setEnabled( b:Boolean):void {
			buttonMode = b;
			if( b) {
				m_clickObj.addEventListener( MouseEvent.ROLL_OVER, onRollOVER);
				m_clickObj.addEventListener( MouseEvent.ROLL_OUT, onRollOUT);
			} else {
				m_clickObj.removeEventListener( MouseEvent.ROLL_OVER, onRollOVER);
				m_clickObj.removeEventListener( MouseEvent.ROLL_OUT, onRollOUT);
				onRollOUT();
			}
		}
		protected function onRollOVER( e:MouseEvent) {
			m_on.visible = true;
		}
		protected function onRollOUT( e:MouseEvent = null) {
			m_on.visible = false;
		}
	}
}