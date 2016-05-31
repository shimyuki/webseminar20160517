﻿package window.video.list {	import flash.display.*;	import flash.geom.*;	import common.*;	import window.*;	import flash.text.*;	import flash.events.*;	import flash.net.*;	import caurina.transitions.*;	import window.video.list.parts.*;	import flash.media.Camera;	// 受講生一覧のピックアップリスト	public class PickupList extends ResizableContainer {		protected const PAD = 15;		private const THU_PAD = 2; // サムネイル同士の隙間		private const BASE_COLOR:uint = 0xfaf5e2;		protected var m_memberUids:Array = null;		protected var m_col:int = -1; // サムネイル表示の場合の分割数		protected var H:Number = 0;		protected var m_myCamera:Camera = null;				private var m_preW:Number = 0;				protected var so_pickup:SharedObject = null;		protected var m_nc:NetConnection = null;				protected var m_joinStatus:Object;				public function PickupList( w:Number, h:Number) {			super( w, 1, 0, 0, BASE_COLOR); // min_w は後で設定し直すのでとりあえず						m_joinStatus = new Object();		}		public function setCamera( camera) {			m_myCamera = camera;			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con == null) continue;				if( con.getCurrentUid() == Main.CONF.UID) con.setCamera( m_myCamera);			}		}		// 画面モード変更時にMainからListContainer経由で呼ばれる		public function resetLayout( memberCol:int, memberUids:Array) {									m_col = memberCol;			m_memberUids = memberUids;			if( m_memberUids == null) m_memberUids = [];			resetMember();			replace();		}		protected function resetMember() {			// サムネイル一覧を生成しなおす。		}						function replace() {			// サムネイル一覧を並べ直す			var posi_y = PAD;			var posi_x = PAD;			var col:int = 0;			var padding = 2;			var num = 0;			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con == null) continue;								// 左上から番号をふっておく。				con.resetNum( num);				num++;								// 列数と全体幅に応じて、サムネイルの横幅を変更				con.setViewWidth( getThuWidth());				con.x = posi_x;				con.y = posi_y;								posi_x += con.getViewWidth() + THU_PAD;				col++;								H = posi_y + con.getViewHeight() + PAD;				setViewHeight( H);				if( col == m_col) {					col = 0;					posi_x = PAD;					posi_y += con.getViewHeight() + THU_PAD;				}			}		}		public function resetNetStream() {			// 次にinitSoが再度呼ばれたときのための準備。			// とりあえず今addChildされているもの			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con != null) {					con.resetNetStream();				}			}		}		public function initSo( objname:String, nc:NetConnection) : void {			m_nc = nc;									// 受講生全員分の動画配信設定の変更を監視する			var arr:Array = Main.CONF.getMemberArr();			for each( var member:Member in arr) {				var so:SharedObject = Main.CONF.getSo( member.uid);				if( so != null) {					so.addEventListener( SyncEvent.SYNC, onSoChanged);				}			}						// 受信開始（とりあえず今addChildされているものは受信開始			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con != null) {					con.setNc( m_nc);					if( con.getCurrentUid() != Main.CONF.UID) con.startReceive();				}			}					}		public function setVolume( _uid:String, volume:Number) {			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con != null) {					if( con.getCurrentUid() == _uid) {						con.setVolumeMeterLevel( volume);						return;					}				}			}		}		public function setFpsMeter() {			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con == null) continue;				if( con.getCurrentUid() != Main.CONF.UID) con.setFpsMeter();			}		}				/*function onSuncVolume( e:SyncEvent) {			for each( var obj in e.changeList) {				for( var i = 0; i < numChildren; i++) {					var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;					if( con != null && con.getCurrentUid() == obj.name) {						con.setVolumeMeterLevel( so_volume.data[ obj.name]);					}				}			}		}*/		// 参加不参加状況の変更。Main:onSyncJoin()からLiveStatusManager経由で呼ばれる		public function changeJoinStatus( uid:String, joinFlag:Boolean) {			m_joinStatus[ uid] = joinFlag;			for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				if( con != null && con.getCurrentUid() == uid) {					con.changeJoinStatus( joinFlag);					if( joinFlag) {						con.setNc( m_nc);						con.startReceive();					}				}			}		}		function onSoChanged( e:SyncEvent) :void {			var so:SharedObject = e.target as SharedObject;						if( so.data.hash != undefined) {//alertDialog( String( so.data.hash.uid));				// 表示中のピックアップサムネイルに配信設定を反映する				for( var i = 0; i < numChildren; i++) {					var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;					if( con != null && con.getCurrentUid() == String( so.data.hash.uid)) {												applySo( con, so.data.hash);					}				}			}		}		protected function applySo( con:PickupMemberContainer, hash:Object) {												con.setFpsMeterDenominator( hash.fps);						// 映像を配信しないことになってたら、Videoを非表示に			if( hash.uid != Main.CONF.UID){				if( hash.video == 0) {					con.stopVideo();				} else {					con.startVideo();				}			}		}				function isSameArr( a_arr:Array, b_arr:Array) :Boolean {			if( a_arr == null || b_arr == null) return false;			if( a_arr.length != b_arr.length) return false;			for( var i = 0; i < a_arr.length; i++) {				if( a_arr[i] != b_arr[i]) return false;			}			return true;		}		function getThuWidth() : Number {			// 列数と全体幅に応じて、サムネイルの横幅を取得			return ( getViewWidth() - PAD * 2 - ( m_col - 1) * THU_PAD) / m_col;		}								override public function setViewWidth( w:Number, debug:String = ""):void {			if( w < MIN_W) w = MIN_W;			super.setViewWidth( w);						if( m_preW == w) return;			m_preW = w;						for( var i = 0; i < numChildren; i++) {				var con:PickupMemberContainer = getChildAt( i) as PickupMemberContainer;				// 列数と全体幅に応じて、サムネイルの横幅を変更				if( con != null) con.setViewWidth( getThuWidth());			}			// サムネイルの高さも変わっただろうから、並べ直し			replace();		}				override public function setViewHeight( h:Number):void {			super.setViewHeight( h);		}		override public function getViewHeight():Number{			//return super.getViewHeight();			return H;		}		function reDispatchMemberEvent( e:MemberEvent) {			dispatchEvent( new MemberEvent( e.type, e.uid));		}				function alertDialog( str) {			Main.addErrMsg("PickupList:" + str);		}	}}