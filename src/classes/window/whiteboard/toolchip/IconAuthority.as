﻿package window.whiteboard.toolchip {	import flash.display.*;	import flash.text.*;	import flash.events.*;	import flash.geom.*;	import common.*;	import caurina.transitions.*;	import window.TitleBar;		public class IconAuthority extends Sprite {		private const STR_OFF:String = Main.LANG.getParam( "共有モード") + ": OFF";		private const STR_ON:String = Main.LANG.getParam( "共有モード") + ": ON ";		private var m_on:Sprite;		private var m_off:Sprite;		private const FONT_SIZE:Number = 11;		private const FONT_COLOR:uint = 0xffffff;		private const BASE_COLOR_01:uint = 0xa0b7ce;		private const BASE_COLOR_02:uint = 0x7f9bb9;		private const ELLIPSE_W:Number = 10;				public function IconAuthority() {						// OFFベース			m_off = Sprite( addChild( new Sprite()));			var offTxt:TextField = TextField( m_off.addChild( new TextField()));			offTxt.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), FONT_SIZE, FONT_COLOR, true);			offTxt.autoSize = TextFieldAutoSize.LEFT;			offTxt.text = STR_OFF;			offTxt.selectable = offTxt.mouseEnabled = false;			var w = offTxt.width + 16;			var h = offTxt.height + 8;			offTxt.x = ( w - offTxt.width) / 2;			offTxt.y = ( h - offTxt.height) / 2;						var matrix:Matrix = new Matrix();			matrix.createGradientBox( w, h, - Math.PI / 2);			m_off.graphics.beginGradientFill( GradientType.LINEAR,											[BASE_COLOR_02, BASE_COLOR_01],											[1, 1],											[0x00, 0xFF],											matrix, SpreadMethod.PAD);			m_off.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);			m_off.graphics.endFill();															// ONベース			m_on = Sprite( addChild( getOnBase( w, h, matrix)));			m_on.visible = false;											var onTxt:TextField = TextField( m_on.addChild( new TextField()));			onTxt.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), FONT_SIZE, FONT_COLOR, true);			onTxt.autoSize = TextFieldAutoSize.LEFT;			onTxt.text = STR_ON;			onTxt.selectable = onTxt.mouseEnabled = false;			onTxt.x = offTxt.x;			onTxt.y = offTxt.y;						y = ( TitleBar.H - h) / 2;		}						public function on() {			m_on.visible = true;		}		public function off() {			m_on.visible = false;		}				function getOnBase( w:Number, h:Number, matrix:Matrix) : Sprite {			var onBase:Sprite = new Sprite();			onBase.graphics.beginFill( 0xffffff);			onBase.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);			onBase.graphics.endFill();			var onBaseRed:Sprite = Sprite( onBase.addChild( new Sprite()));			onBaseRed.graphics.beginGradientFill( GradientType.LINEAR,											[0xb50000, 0xcc0000],											[1, 1],											[0x00, 0xFF],											matrix, SpreadMethod.PAD);			onBaseRed.graphics.drawRoundRect( 0, 0, w, h, ELLIPSE_W);			onBaseRed.graphics.endFill();						return onBase;		}	}}