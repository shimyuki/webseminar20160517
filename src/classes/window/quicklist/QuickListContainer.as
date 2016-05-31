﻿package window.quicklist {	import flash.display.*;	import flash.geom.*;	import flash.utils.*;	import common.*;	import window.*;	import window.video.list.parts.MemberContainer;	import flash.text.*;	import flash.events.*;	import flash.net.*;	import fl.controls.CheckBox;	import caurina.transitions.*;	import com.adobe.crypto.SHA1;	// 受講生クイック一覧	public class QuickListContainer extends ResizableContainer {		private var _MIN_W = 180;		private var _MIN_H = 100;		private const INIT_Y = 21;		static public const LINE_COLOR:uint = 0xcccccc;		private const PAD = 0;		private const FOOTER_H = 15;		private var m_container:Sprite;		private var m_containerMask:Sprite;		private var m_scroll:SimpleScrollBar;		private var m_preW:Number = 0;		private var m_preH:Number = 0;		private var m_micAllChk:CheckBox;		private var m_iconMic;		private var m_iconChat;		private var m_line:Shape;		private var m_memberConArr:Array;				// 予約済みかチェックする用		private const INTERVAL:uint = 10000;								public function QuickListContainer( w:Number, h:Number) {			super( w, h, _MIN_W, _MIN_H); // min_w は後で設定し直すのでとりあえずゼロ						// 一覧表示コンテナ			m_container = Sprite( addChild( new Sprite()));			m_container.y = INIT_Y;						// 一覧表示コンテナのマスク			m_containerMask = Sprite( addChild( new Sprite()));			m_containerMask.graphics.beginFill(0);			m_containerMask.graphics.drawRect( 0, 0, 1, 1);			m_containerMask.y = m_container.y;			m_container.mask = m_containerMask;						// 一覧表示コンテナのスクロールバー			m_scroll = addChild( new SimpleScrollBar()) as SimpleScrollBar;			m_scroll.y = INIT_Y;			m_scroll.setSize( m_scroll.width, 200);						m_scroll.setScrollTarget( m_container);			m_scroll.scrollMask = m_containerMask;						m_iconMic = addChild( new IconSmallMic());			m_iconMic.y = 5;						m_micAllChk = CheckBox( addChild( new CheckBox()));			m_micAllChk.label = "";			m_micAllChk.textField.width = 0;			m_micAllChk.setSize( 23, 20);			m_micAllChk.y = 0;			m_micAllChk.enabled = false;						//m_iconChat = addChild( new IconSmallChat());			m_iconChat = addChild( new TextField());			m_iconChat.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 9, 0x555555);			m_iconChat.autoSize = TextFieldAutoSize.LEFT;			m_iconChat.text = Main.LANG.getParam( "チャット");			m_iconChat.y = m_iconMic.y + ( m_iconMic.height - m_iconChat.height) / 2;						m_line = Shape( addChild( new Shape()));			m_line.graphics.lineStyle( 1, 0xcccccc);			m_line.graphics.moveTo( 0, INIT_Y + 0.5);			m_line.graphics.lineTo( 1, INIT_Y + 0.5);						if( ! Main.CONF.isPro( Main.CONF.UID)) {				m_iconChat.visible = false;			}						addEventListener( Event.ADDED_TO_STAGE,				function( e:Event) {					// ポップアップとの切り替え時など。					// スクロールバーを一番上の状態に。					m_container.y = INIT_Y;					m_scroll.setBarYMin();					m_scroll.update();									});						// 人数分のメンバーコンテナ格納配列			m_memberConArr = new Array();			var arr:Array = Main.CONF.getMemberArr();			for each( var member:Member in arr) {								// 講師は除く				if( Main.CONF.isPro( member.uid)) continue;								var con:MemberCon = new MemberCon( member.uid);				con.available = false;				m_memberConArr.push( con);				con.addEventListener( MemberEvent.POPUP_SETTING, reDispatchMemberEvent);				con.addEventListener( MemberEvent.POPUP_SETTING_CHAT, reDispatchMemberEvent);			}						if( Main.CONF.isPro( Main.CONF.UID)) {				applyReservedStatus();								var timer:Timer = new Timer( INTERVAL);				timer.addEventListener( TimerEvent.TIMER, applyReservedStatus);				timer.start();			}					}				// 講師用		function applyReservedStatus( e:TimerEvent = null) {						var dateObj:Date = new Date();			var cacheClear = "?dummy=" + dateObj.getMonth() + dateObj.getDate() + dateObj.getHours() + dateObj.getMinutes() + dateObj.getSeconds(); // 一秒ごとにキャッシュクリア						var req:URLRequest = new URLRequest( Main.CONF.getParam( 'RESERVED_UIDLIST_URL') + cacheClear);						req.method = URLRequestMethod.POST;			var variables:URLVariables = new URLVariables();			variables.class_id = Main.CONF.CLASS_ID;			req.data = variables;						var loader:URLLoader = new URLLoader();			loader.load( req);			loader.addEventListener( Event.COMPLETE, onComplete);			loader.addEventListener( IOErrorEvent.IO_ERROR, onError);			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onError);		}				function onComplete( e:Event) {			var loader:URLLoader = e.target as URLLoader;			var xml:XML = XML( loader.data);						var change_cnt = 0;			// ---------------			// 予約済みuidの取得			if( xml.hasOwnProperty("uid")) {				for each( var con:MemberCon in m_memberConArr) {					var reserved:Boolean = false;					for each ( var uid:String in xml.uid) {						if( con.uid == uid) {							reserved = true;							break;						}					}					var old_status = con.available;					con.available = reserved;					if( old_status != reserved) change_cnt++;				}			}			if( change_cnt) {				replace();				m_scroll.update();			}		}				// LiveStatusManagerから呼ばれる		public function setTerminalStatus( uid:String, terminalType:String) {			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) {					con.setTerminalStatus( terminalType);					break;				}			}					}		// 授業終了時に呼ばれる		public function setStatusDisconnect() {			for each( var con:MemberCon in m_memberConArr) {				con.setVolume( 0);			}		}		public function initSo( objname:String, nc:NetConnection, so_here:SharedObject) : void {			for each( var con:MemberCon in m_memberConArr) {				con.initSo( nc, so_here);			}			m_micAllChk.enabled = true;			m_micAllChk.addEventListener( Event.CHANGE, onChangeAllMic);		}		public function setVolume( uid:String, volume:Number) {			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) {					con.setVolume( volume);					return;				}			}		}				function onChangeAllMic( e:Event) {			for each( var con:MemberCon in m_memberConArr) {				con.changeMic( m_micAllChk.selected);				//wait( 250);			}		}		function wait( count:uint ):void{			var start:uint = getTimer();			while( getTimer() - start < count){			}		}				public function startBlinkChatBtn( uid:String){			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) con.startBlinkChatBtn();			}		}		public function stopBlinkChatBtn( uid:String){			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) con.stopBlinkChatBtn();			}		}				// 挙手状況の変更。Main:onSyncHere()からLiveStatusManager経由で呼ばれる		public function changeHereStatus( uid:String, hereFlag:Boolean, nowTime:Number) {			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) con.changeHereStatus( hereFlag, nowTime);			}						// ソートしてreplace			m_memberConArr.sortOn([ "lastHereTime", "firstAttendTime"], [ Array.NUMERIC, Array.NUMERIC]);			//m_memberConArr.sortOn([ "status", "lastHereTime", "firstAttendTime"], 					//  [ Array.NUMERIC | Array.DESCENDING, Array.NUMERIC, Array.NUMERIC]);			replace();		}				// 参加不参加状況の変更。Main:onSyncJoin()からLiveStatusManager経由で呼ばれる		public function changeJoinStatus( uid:String, joinFlag:Boolean, nowTime:Number) {			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid) con.changeJoinStatus( joinFlag, nowTime);			}						// ソートしてreplace			m_memberConArr.sortOn([ "lastHereTime", "firstAttendTime"], [ Array.NUMERIC, Array.NUMERIC]);			replace();		}		// 最初の参加時間の変更。Main:onSyncSo1stJoinTime()から呼ばれる		public function set1stAttendTime( uid:String, time:Number) {			var changed = false;			for each( var con:MemberCon in m_memberConArr) {				if( con.uid == uid && con.firstAttendTime != time) {					con.firstAttendTime = time;					changed = true;				}			}			if( !changed) return;						// ソートしてreplace			m_memberConArr.sortOn([ "lastHereTime", "firstAttendTime"], [ Array.NUMERIC, Array.NUMERIC]);			replace();		}						function replace() {//alertDialog( "replace");			var posi_y:Number = 0;			for each( var con:MemberCon in m_memberConArr) {				if( ! con.available) {					if( m_container.contains( con)) m_container.removeChild( con);					continue;				}								m_container.addChild( con);				con.y = posi_y;				posi_y += MemberCon.H + 1;			}		}				override public function setEnabled( b:Boolean):void {		}		override public function setViewWidth( w:Number, debug:String = ""):void {			if( w < MIN_W) w = MIN_W;			super.setViewWidth( w);						m_containerMask.width = w - m_scroll.width;			m_scroll.x = w - m_scroll.width;						var inner_w = w - m_scroll.width;			m_line.graphics.clear();			m_line.graphics.lineStyle( 1, 0xcccccc);			m_line.graphics.moveTo( 0, INIT_Y + 0.5);			m_line.graphics.lineTo( inner_w, INIT_Y + 0.5);									if( Main.CONF.isPro( Main.CONF.UID)) {				m_micAllChk.x = inner_w - 86;				m_iconMic.x = m_micAllChk.x - 15;				m_iconChat.x = inner_w - 35;			} else {				m_iconMic.x = inner_w - 44;			}			for each( var con:MemberCon in m_memberConArr) {				con.setViewWidth( inner_w);			}						// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、			// サイズがかわらないのであればここでリターン			if( w != m_preW ) {				m_preW = w;				m_scroll.update();			}					}				override public function setViewHeight( h:Number):void {			super.setViewHeight( h);			m_containerMask.height = h - INIT_Y - FOOTER_H - PAD * 2;			// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、			// サイズがかわらないのであればここでリターン			if( h != m_preH ) {				m_preH = h;				m_scroll.setSize( m_scroll.width, h - INIT_Y - FOOTER_H);				m_scroll.update();			}		}		function reDispatchMemberEvent( e:MemberEvent) {			dispatchEvent( new MemberEvent( e.type, e.uid));		}				function onError( e:*) {			alertDialog( e);		}				function alertDialog( str) {			Main.addErrMsg( "QuickListContainer:" + str);		}	}}