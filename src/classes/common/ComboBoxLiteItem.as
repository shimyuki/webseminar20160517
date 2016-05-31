﻿package common {	import flash.display.*;	import flash.geom.*;	import flash.text.*;	import flash.events.*;	// ComboBoxLiteのアイテム（ドロップダウンの部分）	public class ComboBoxLiteItem extends Sprite {		static public const H = 22;		private const BG_COLOR:uint = 0xffffff;		private const LINE_COLOR:uint =0xb0b0b0;		private const BG_COLOR_UNABLED:uint = 0xd9d9d9;		private const BG_COLOR_OVER:uint = 0xdaf1ff;		private const LINE_COLOR_OVER:uint =0x0089e0;		private const TEXT_COLOR:uint =0x000000;		private const TEXT_COLOR_UNABLED:uint =0x999999;		static public const SELECTED:String = "ComboBoxLiteItem SELECTED";				private var m_text:TextField;		private var m_bgUp;		private var m_bgOver;		private var m_bgUnable;		private var m_clickArea:Sprite;		public var item = null;				public function ComboBoxLiteItem( obj) {			item = obj;					m_bgUp = addChild( new Shape());			m_bgUnable = addChild( new Shape());			m_bgOver = addChild( new Shape());			m_text = TextField( addChild( new TextField()));			m_text.defaultTextFormat = new TextFormat( "_ゴシック", 11, TEXT_COLOR);			m_text.x = 4;			m_text.y = 4;			m_text.text = item.label;			m_text.width = m_text.textWidth + 4;			m_text.height = m_text.textHeight + 4;			m_bgOver.visible = m_bgUnable.visible = false;							m_clickArea = Sprite( addChild( new Sprite()));						setEnabled( true);			width = m_text.width + 8;					}		public function setEnabled( b:Boolean) {			if( b) {				m_bgUnable.visible = false;				m_bgUp.visible = true;				m_clickArea.buttonMode = true;				m_clickArea.addEventListener( MouseEvent.ROLL_OVER, onRollOVER);				m_clickArea.addEventListener( MouseEvent.MOUSE_UP, onMouseUP);				m_text.defaultTextFormat = new TextFormat( "_ゴシック", 11, TEXT_COLOR);				m_text.text = m_text.text;			} else {				m_bgUnable.visible = true;				m_bgUp.visible = false;				m_clickArea.buttonMode = false;				m_clickArea.removeEventListener( MouseEvent.ROLL_OVER, onRollOVER);				m_clickArea.removeEventListener( MouseEvent.MOUSE_UP, onMouseUP);				m_text.defaultTextFormat = new TextFormat( "_ゴシック", 11, TEXT_COLOR_UNABLED);				m_text.text = m_text.text;			}		}		function onMouseUP( e:MouseEvent) {			if( !m_bgUnable.visible) dispatchEvent( new Event( SELECTED));		}		function onRollOVER( e:MouseEvent) {			m_clickArea.removeEventListener( MouseEvent.ROLL_OVER, onRollOVER);			m_clickArea.addEventListener( MouseEvent.ROLL_OUT, onRollOUT);			m_bgUp.visible = false;			m_bgOver.visible = true;		}		function onRollOUT( e:MouseEvent) {			m_clickArea.addEventListener( MouseEvent.ROLL_OVER, onRollOVER);			m_clickArea.removeEventListener( MouseEvent.ROLL_OUT, onRollOUT);			m_bgOver.visible = false;			m_bgUp.visible = true;		}				public function resetWidth() {			width = m_text.width + 8;		}		override public function set width( w:Number):void{			var h = m_text.height + 8;						m_bgUp.graphics.clear();			m_bgUp.graphics.lineStyle( 1, LINE_COLOR);			m_bgUp.graphics.beginFill( BG_COLOR);			m_bgUp.graphics.drawRect( 0, 0, w, h);			m_bgUp.graphics.endFill();			m_bgOver.graphics.clear();			m_bgOver.graphics.lineStyle( 1, LINE_COLOR_OVER);			m_bgOver.graphics.beginFill( BG_COLOR_OVER);			m_bgOver.graphics.drawRect( 0, 0, w, h);			m_bgOver.graphics.endFill();			m_bgUnable.graphics.lineStyle( 1, LINE_COLOR);			m_bgUnable.graphics.beginFill( BG_COLOR_UNABLED);			m_bgUnable.graphics.drawRect( 0, 0, w, h);			m_bgUnable.graphics.endFill();			m_clickArea.graphics.clear();			m_clickArea.graphics.beginFill( 0xcc0000, 0);			m_clickArea.graphics.drawRect( 0, 0, w, h);			m_clickArea.graphics.endFill();        }						override public function set height( h:Number):void{        }	}}