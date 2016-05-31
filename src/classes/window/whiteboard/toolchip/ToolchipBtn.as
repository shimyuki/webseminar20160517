﻿package window.whiteboard.toolchip {	import flash.display.*;	import flash.events.*;	import flash.geom.*;	import flash.utils.*;	import common.*;		public class ToolchipBtn extends IconPartsBtn {				private var m_timer:Timer = null;		private var m_panelArr:Array;		private var m_panelCon:Sprite = null;		private var m_mainIcon:Sprite;						public function ToolchipBtn( _btnIcon:DisplayObject, _panelIcon:DisplayObject, dispatchText:String, _w:Number = 27, _h:Number = 27) {			m_mainIcon = new Sprite();			m_mainIcon.addChild( _btnIcon);			super( m_mainIcon, _w, _h);						m_panelArr = new Array();			addIcon( _btnIcon, _panelIcon, dispatchText, true);						m_clickObj.name = dispatchText;		}		public function addIcon( _btnIcon:DisplayObject, _panelIcon:DisplayObject, dispatchText:String, b_1stIcon:Boolean = false) {			if( ! b_1stIcon && m_timer == null) {				m_panelCon = new Sprite();								m_timer = new Timer( 300, 1);				m_timer.addEventListener( TimerEvent.TIMER, onTimer);				m_clickObj.addEventListener( MouseEvent.MOUSE_DOWN, onStartTimer);								var kado_x = m_clickObj.width - 3;				var kado_y = m_clickObj.height - 3;				m_clickObj.graphics.beginFill( 0x1a328c);				m_clickObj.graphics.moveTo( kado_x, kado_y);				m_clickObj.graphics.lineTo( kado_x, kado_y - 4);				m_clickObj.graphics.lineTo( kado_x - 4, kado_y);				m_clickObj.graphics.lineTo( kado_x, kado_y);			}						var panel:Panel = new Panel( _btnIcon, _panelIcon, dispatchText);			panel.name = dispatchText;			panel.addEventListener( MouseEvent.MOUSE_UP, onSelected);			m_panelArr.push( panel);		}		function onTimer( e:TimerEvent) {			if( m_panelCon == null) return;						var posi_y:Number = 0;			var max_w:Number = 0;			var panel:Panel;			for each( panel in m_panelArr) {　				m_panelCon.addChild( panel);				panel.y = posi_y;				posi_y += panel.height;				max_w = ( max_w < panel.width + 5) ? panel.width + 5 : max_w;			}			for each( panel in m_panelArr) {				panel.setWidth( max_w);			}						dispatchEvent( new ToolchipEvent( ToolchipEvent.SHOW_PANEL, "", m_panelCon, x, y));						//stage.removeEventListener( MouseEvent.MOUSE_UP, onReset);		}		function onStartTimer( e:MouseEvent) {			m_timer.start();			if( stage) stage.addEventListener( MouseEvent.MOUSE_UP, onReset);		}		function onReset( e:MouseEvent = null) {			if( m_timer != null) m_timer.reset();			if( m_panelCon != null) dispatchEvent( new ToolchipEvent( ToolchipEvent.HIDE_PANEL, "", m_panelCon));		}		override public function setEnabled( b:Boolean):void {			super.setEnabled( b);			if( b) {				m_clickObj.addEventListener( MouseEvent.MOUSE_UP, onSelected);			} else {				m_clickObj.removeEventListener( MouseEvent.MOUSE_UP, onSelected);			}		}		function onSelected( e:MouseEvent) {			if( e.target == m_clickObj) {				dispatchEvent( new ToolchipEvent( ToolchipEvent.SELECTED, m_clickObj.name));			} else {				var panel:Panel = e.target as Panel;				if( panel == null) panel = e.target.parent;				if( panel == null) panel = e.target.parent.parent;				var dispatchText:String = panel.name;								if( dispatchText) {					m_clickObj.name = dispatchText;					dispatchEvent( new ToolchipEvent( ToolchipEvent.SELECTED, dispatchText));					while( m_mainIcon.numChildren) m_mainIcon.removeChildAt( 0);					m_mainIcon.addChild( panel.getBtnIcon());					onReset();				} else {//trace("だめぽ");				}			}		}				// このボタンがTOOL_ARROWの場合にToolchipBtns:setEnabled( true)で呼ばれる。		// 若しくは、テキストペイントパーツのダブルクリック時に、		// WhiteboardContainer経由でToolchipBtns:setTextOn()から呼ばれる		public function setOn() {			//m_clickObj.dispatchEvent( new MouseEvent( MouseEvent.MOUSE_UP));			dispatchEvent( new ToolchipEvent( ToolchipEvent.SELECTED, m_clickObj.name));		}	}}import flash.display.*;import flash.text.*;import flash.events.*;class Panel extends Sprite {	private const BASE_COLOR = 0xf0f0f0;	private const BASE_ON_COLOR = 0xcccccc;	static public const H = 25;	private var m_baseOn:Shape;	private var m_clickObj:Sprite;	private var m_btnIcon;	public function Panel( _btnIcon, _panelIcon, str:String) {		m_btnIcon = _btnIcon;				m_baseOn = Shape( addChild( new Shape()));		m_baseOn.graphics.beginFill( BASE_ON_COLOR);		m_baseOn.graphics.drawRect( 0, 0, H, H);		m_baseOn.graphics.endFill();		m_baseOn.visible = false;				addChild( _panelIcon);		_panelIcon.x = 5;		_panelIcon.y = ( H - _panelIcon.height) / 2;				var txt:TextField = TextField( addChild( new TextField()));		txt.autoSize = TextFieldAutoSize.LEFT;		txt.defaultTextFormat = new TextFormat( null, 10, 0x000000);		txt.text = str;		txt.x = 30; // 適当		txt.y = ( H - txt.height) / 2;				m_clickObj = Sprite( addChild( new Sprite()));		m_clickObj.graphics.beginFill( 0, 0);		m_clickObj.graphics.drawRect( 0, 0, H, H);		m_clickObj.graphics.endFill();		m_clickObj.addEventListener( MouseEvent.ROLL_OVER, function( e:*){ m_baseOn.visible = true;});		m_clickObj.addEventListener( MouseEvent.ROLL_OUT, function( e:*){ m_baseOn.visible = false;});		m_clickObj.addEventListener( MouseEvent.MOUSE_UP, function( e:*){ m_baseOn.visible = false;});	}	public function setWidth( w:Number) {		m_baseOn.width = m_clickObj.width = w;		graphics.beginFill( BASE_COLOR);		graphics.drawRect( 0, 0, w, H);		graphics.endFill();	}	public function getBtnIcon() { return m_btnIcon;}}