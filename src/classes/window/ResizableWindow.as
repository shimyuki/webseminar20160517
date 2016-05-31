﻿package window {	import flash.display.*;	import flash.geom.*;	import flash.events.*;	import flash.net.*;	import partition.*;	import common.AlertManager;		// サイズ変更可能ウィンドウ	public class ResizableWindow extends ResizableContainer {		static public const POPUP:String = "ResizableWindow POPUP";		static public const POPUP_END:String = "ResizableWindow POPUP_END";		static public const POPUP_CLOSE:String = "ResizableWindow POPUP_CLOSE";				protected const PAD = 1;		protected var m_titlebar:TitleBar = null;		protected var m_contents = null;		private var m_parent = null; // ポップアップした後戻すとき用の親				private var m_diffX:Number; // ポップアップ中のドラッグ開始マウス位置		private var m_diffY:Number; // ポップアップ中のドラッグ開始マウス位置				protected  var m_sizeHandle:SizeHandle = null;		//private var m_popupByBtn:Boolean = false;		public var popupWidth = 900;		public var popupHeight = 700;				public function ResizableWindow( w:Number, h:Number, min_w:Number = 0, min_h:Number = 0, baseColor:uint = 0xffffff) {			super( w, h, min_w, min_h, baseColor);						m_sizeHandle = new SizeHandle();			m_sizeHandle.setEnable( false);			addEventListener( Event.ADDED_TO_STAGE, onAdded);		}				// popupReq：ポップアップボタンクリック時に、別ウィンドウを開きたい場合は設定する		// usePopup：ポップアップボタンを表示するか否か		// leftContents_2nd : 第二のleftContents。権限を持たない場合などの。		public function setTitleBar( titleLeft, titleRight = null,									popupReq:URLRequest = null, usePopup:Boolean = false,									titleLeft_2nd = null) {			m_titlebar = TitleBar( addChild( new TitleBar( titleLeft, titleRight, getViewWidth(), popupReq, usePopup, titleLeft_2nd)));			m_titlebar.addEventListener( POPUP, reDispatch);			m_titlebar.addEventListener( POPUP_END, reDispatch);			m_titlebar.addEventListener( POPUP_CLOSE, reDispatch);			resetMin();		}		public function changeTitleText( str:String) {			m_titlebar.changeTitleText( str);		}				// Mainからレイアウト変更時に呼ばれる。		// TitleBarのポップアップアイコンの一時的非表示の設定。		// 引数：ポップアップ禁止レイアウトの場合はfalse、通常レイアウトの場合はtrue		public function setTitleBarPopup( b:Boolean) {			if( m_titlebar) m_titlebar.setPopupTemporary( b);		}				// Mainで生成した環境設定ウィンドウなど、ボタンからポップアップさせるウィンドウの場合、ボタンクリック時に呼ばれる。		public function callDispachPopup() {			m_titlebar.useCloseBtn();			m_titlebar.dispatchEvent( new Event( POPUP));		}				public function setContents( resizableContents/*:ResizableContainer*/) {			m_contents = resizableContents;			addChild( m_contents);						if( m_titlebar != null) {				//m_contents.y = m_titlebar.height + PAD;				m_contents.y = TitleBar.H + PAD;			}			resetMin();						return m_contents;		}				public function getContents() {			return m_contents;		}		protected function resetMin() {			if( m_titlebar != null && m_contents != null) {				MIN_W = MIN_W > m_titlebar.MIN_W ? MIN_W : m_titlebar.MIN_W;				MIN_W = MIN_W > m_contents.MIN_W ? MIN_W : m_contents.MIN_W;				MIN_H = MIN_H > ( m_titlebar.MIN_H + m_contents.MIN_H + 1)				? MIN_H : ( m_titlebar.MIN_H + m_contents.MIN_H + 1);			}		}				// ポップアップした後戻すとき用の親を取得		function onAdded( e:Event) {			if( parent != null && parent.name == PartitionContainer.CONTAINER_NAME) {				m_parent = parent;				removeEventListener( Event.ADDED, onAdded);			}					}		// ポップアップした後戻す		function reAdd() {			if( m_parent != null) {				m_parent.addChild( this);				x = y = 0;			}		}				function setDrag( b:Boolean):void {			m_titlebar.buttonMode = b;			if( b){				m_titlebar.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown_titlebar);			} else {				m_titlebar.removeEventListener( MouseEvent.MOUSE_DOWN, onMouseDown_titlebar);				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_titlebar);				stage.removeEventListener( MouseEvent.MOUSE_UP, onMouseUp_titlebar);			}		}		function setResize( b:Boolean):void {						var min_h = TitleBar.H + m_sizeHandle.height + 10; // 適当			min_h = MIN_H < min_h ? min_h : MIN_H;			if( getViewHeight() < min_h) {				setViewHeight( min_h);			}			replaceSizeHandle();			m_sizeHandle.setEnable( b);			if( b){				addChild( m_sizeHandle);				m_sizeHandle.addEventListener( "change", onSizeChange);			} else {				m_sizeHandle.removeEventListener( "change", onSizeChange);			}		}		protected function replaceSizeHandle() {			m_sizeHandle.x = getViewWidth() - m_sizeHandle.width;			m_sizeHandle.y = getViewHeight() - m_sizeHandle.height;		}		protected function onSizeChange( e:SizeHandleEvent) {//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "ResizableWindow:onSizeChange " + Math.random());			var min_h = TitleBar.H + m_sizeHandle.height + 10; // 適当			min_h = MIN_H < min_h ? min_h : MIN_H;						if( getViewWidth() - e.diffX < MIN_W) setViewWidth( MIN_W);			else setViewWidth( getViewWidth() - e.diffX);						if( getViewHeight() - e.diffY < min_h) setViewHeight( min_h);			else setViewHeight( getViewHeight() - e.diffY);						replaceSizeHandle();		}				override public function setEnabled( b:Boolean):void {			if( m_titlebar != null) m_titlebar.setEnabled( b);			if( m_contents != null) m_contents.setEnabled( b);		}		override public function setViewWidth( w:Number, debug:String = ""):void {//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "ResizableWindow:setViewWidth " + Math.random());			super.setViewWidth( w);			if( m_titlebar != null) m_titlebar.setViewWidth( w, debug);			if( m_contents != null) m_contents.setViewWidth( w, debug);			replaceSizeHandle();		}		override public function setViewHeight( h:Number):void {			super.setViewHeight( h);			if( m_titlebar != null && m_contents != null) {				m_contents.setViewHeight( h - TitleBar.H - PAD);			} else if( m_contents != null) {				m_contents.setViewHeight( h);			}			replaceSizeHandle();		}		override public function getViewWidth():Number { return super.getViewWidth();}		override public function getViewHeight():Number { return super.getViewHeight();}				function onMouseDown_titlebar( e:MouseEvent) {			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_titlebar);			stage.addEventListener( MouseEvent.MOUSE_UP, onMouseUp_titlebar);			m_titlebar.removeEventListener( MouseEvent.MOUSE_DOWN, onMouseDown_titlebar);			var g_point = m_titlebar.localToGlobal( new Point());						m_diffX = g_point.x - stage.mouseX;			m_diffY = g_point.y - stage.mouseY;		}		function onMouseUp_titlebar( e:MouseEvent) {			stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_titlebar);			m_titlebar.addEventListener( MouseEvent.MOUSE_DOWN, onMouseDown_titlebar);		}				// タイトルバーを持ってドラッグされる処理		function onMouseMove_titlebar( e:MouseEvent) {			if( ! m_titlebar.isDraggable()) return;						x = stage.mouseX + m_diffX;			y = stage.mouseY + m_diffY;			//if( y < m_popup_minY) y = m_popup_minY;			//if( y > m_popup_maxY) y = m_popup_maxY;						// サイズ変更可能幅の再設定			//m_maxH = m_popup_minY + MAX_H_DEFAULT - y;		}				// 受講生の場合、Mainから画面モード変更時に呼ばれる。		// ポップアップ中だったらポップアップは終了する		public function onChangeStuLayout() {			if( parent === Main.POPUP_CONTAINER) {				m_titlebar.stopPopup();			}		}				protected function reDispatch( e:Event) {			switch( e.type) {				case POPUP: 					setDrag( true);					setResize( true);					break;				//case POPUP_END:				default: 					setDrag( false);					setResize( false);					reAdd();					break;				//default: break;			}			dispatchEvent( e);		}	}}