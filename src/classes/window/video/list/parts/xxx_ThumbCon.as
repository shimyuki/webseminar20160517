﻿package window.video.list.parts {	import flash.display.*;	import flash.geom.*;	import common.*;	import window.*;	import flash.text.*;	import flash.events.*;	import fl.controls.CheckBox;	import flash.net.*;	import flash.media.*;	import flash.filters.*;	import caurina.transitions.*;	import window.video.VoiceMeter;	import window.video.VolumeCtl;	// 受講生一覧のメンバー表示コンテナのサムネイル表示のコンテナ	public class ThumbCon extends Sprite {				private const PAD = 8;		private const INNER_PAD = 4;		private const HEADER_H = 25;		private const FOOTER_H = 23;		private const LABEL_CHAT = Main.LANG.getParam( "チャット");		private var m_nameTxt:TextField;			private var m_base:Shape;		private var m_footerBase:Shape;		private var m_headerBase:Shape;		private var m_volumeMeter:VoiceMeter;		private var m_btnChat:DynamicTextBtn;		protected var m_video:Video;		private var m_bitmap:Bitmap;		protected var m_uid:String;		private var m_mask:Shape;		private var m_volumeCtl:VolumeCtl;		private var m_flagHere;		private var m_absence:Sprite;		private var m_mobileIcon:IconMobile;				protected var m_nc:NetConnection;		protected var m_receive_ns:MyNetStream = null;		//private var m_fpsStatus:TextField;		private var m_fpsMeter:FpsMeter = null;		private var m_1st:Boolean = true;		private var m_prevFps:Number = 0;		private var m_rcvStarted:Boolean = false;				private var m_liveDelayText:TextField = null;				private var so:SharedObject = null;		private var so_here:SharedObject = null; // 挙手関係（挙手してる人に対して、講師が指名（クリック）したら変更する用）		public function ThumbCon( uid:String) {			m_uid = uid;						m_mask = Shape( addChild( new Shape()));			m_mask.graphics.beginFill( 0);			m_mask.graphics.drawRect( 0, 0, 1, 1);			m_mask.graphics.endFill();			mask = m_mask;						m_base = Shape( addChild( new Shape()));			m_base.graphics.lineStyle( 1, 0xd9d9d9, 1, false, "none");			m_base.graphics.beginFill( 0xffffff);			m_base.graphics.drawRect( 0, 0, 1, 1);			m_base.graphics.endFill();									// 名前のタイトルバー（グラデーション）			var fillType:String = GradientType.LINEAR;			var colors:Array = [0xf0f0f0, 0xcccccc];			var alphas:Array = [1, 1];			var ratios:Array = [0x00, 0xFF];			var matr:Matrix = new Matrix();			matr.createGradientBox( 1, HEADER_H , Math.PI/2, 0, 0);			m_headerBase = Shape( addChild( new Shape()));			m_headerBase.graphics.beginGradientFill( fillType, colors, alphas, ratios, matr, SpreadMethod.PAD);			m_headerBase.graphics.drawRect( 0, 0, 1, HEADER_H);			m_headerBase.graphics.endFill();			m_headerBase.x = 1.5;			m_headerBase.y = 1.5;						m_footerBase = Shape( addChild( new Shape()));			m_footerBase.graphics.beginFill( 0xf0f0f0);			m_footerBase.graphics.drawRect( 0, 0, 1, FOOTER_H);			m_footerBase.graphics.endFill();			m_footerBase.x = 1.5;									var fmt:TextFormat = new TextFormat( Main.CONF.getMainFont(), 11, 0x333333, null, null, false);			var fmt_hover:TextFormat = new TextFormat( Main.CONF.getMainFont(), 11, 0x000000, null, null, true);			m_nameTxt = TextField( addChild( getText( Main.CONF.getName( m_uid))));			m_nameTxt.x = Main.CONF.UID == m_uid ? PAD : 25;			m_nameTxt.y = ( HEADER_H - m_nameTxt.textHeight) / 2;			m_nameTxt.selectable = false;			m_nameTxt.defaultTextFormat = fmt;			if( Main.CONF.isPro( Main.CONF.UID)) {				m_nameTxt.addEventListener( MouseEvent.CLICK, onClick_mada);				m_nameTxt.addEventListener( MouseEvent.ROLL_OVER, function( e:*) {										   m_nameTxt.defaultTextFormat = fmt_hover;										   m_nameTxt.text = m_nameTxt.text;										   });				m_nameTxt.addEventListener( MouseEvent.ROLL_OUT, function( e:*) {										   m_nameTxt.defaultTextFormat = fmt;										   m_nameTxt.text = m_nameTxt.text;										   });			}															m_btnChat = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_CHAT, 9, 0, 2, 3)));			m_btnChat.setEnabled( true);			m_btnChat.addEventListener( MouseEvent.CLICK, onClick_mada);//m_btnChat.visible = false;//m_btnChat.width = 0;			m_volumeMeter = VoiceMeter( addChild( new VoiceMeter( 125, 15)));						m_volumeCtl = VolumeCtl( addChild( new VolumeCtl( 0, 100, Main.CONF.isPro( m_uid) ? false : true)));			m_volumeCtl.x = 0.5;									// 遅延秒数			if( m_uid != Main.CONF.UID && Main.SHOW_LIVE_DELAY_TEXT) {				m_liveDelayText = TextField( addChild( new TextField()));				m_liveDelayText.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 11, 0x999999);				m_liveDelayText.text = "0.00";				m_liveDelayText.width = m_liveDelayText.textWidth + 4;				m_liveDelayText.text = "";			}									// サムネイルとなる画像			m_bitmap = new Bitmap( null);			addChild( m_bitmap);			/*m_loader = new Loader();			m_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onComplete);			m_loader.contentLoaderInfo.addEventListener( IOErrorEvent.IO_ERROR, function(e:*){});			var imgpath:String = Main.CONF.getImgpath( m_uid);			if( imgpath != LoadConf.NOTFOUND) m_loader.load( new URLRequest( imgpath));			addChild( m_loader);*/						// ビデオ			m_video = Video( addChild( new Video()));			m_video.smoothing = true;			m_video.x = 1.5;			m_video.y = m_headerBase.y + m_headerBase.height + 1;			if(! Main.CONF.isPro( Main.CONF.UID) || Main.CONF.isPro( m_uid)) {				// 自分自身が受講生の場合、若しくはこのサムネイルが講師のものの場合				// 詳細ボタンは非表示に。				m_btnChat.visible = false;				m_btnChat.width = 0;				if( contains( m_btnChat)) removeChild( m_btnChat);			}						if( ! Main.CONF.isPro( Main.CONF.UID)) {				m_volumeCtl.visible = false;				if( contains( m_volumeCtl)) removeChild( m_volumeCtl);			} else {				m_volumeCtl.addEventListener( Event.CHANGE, changeSoGain);				m_volumeCtl.addEventListener( VolumeCtl.MUTE_OFF, changeSoMicOn);				m_volumeCtl.addEventListener( VolumeCtl.MUTE_ON, changeSoMicOff);			}						// ハイ フラグ（クリックすると消えて、音声ON）			m_flagHere = addChild( Main.LANG.getFlagHere());			m_flagHere.y = - m_flagHere.height;			if( Main.CONF.isPro( Main.CONF.UID)) {				m_flagHere.buttonMode = true;				m_flagHere.addEventListener( MouseEvent.CLICK, onHereClick);			}						// fps割合メーター			m_fpsMeter = new FpsMeter();			m_fpsMeter.x = m_video.x + 5;			m_fpsMeter.y = 5;//m_video.y + 3;			if( m_uid != Main.CONF.UID) addChild( m_fpsMeter);						// モバイルマーク			m_mobileIcon = IconMobile( addChild( new IconMobile()));			m_mobileIcon.x = m_video.x + 5;			m_mobileIcon.y = m_video.y + 5;			m_mobileIcon.visible = false;			m_mobileIcon.filter = [ getBitmapFilter()];									// 欠席用半透明四角			m_absence = Sprite( addChild( new Sprite()));			m_absence.x = m_video.x;			m_absence.y = m_video.y;			var iconNetworkOff = m_absence.addChild( new IconNetworkOff());			iconNetworkOff.x = m_fpsMeter.x - m_video.x;			iconNetworkOff.y = m_fpsMeter.y - m_video.y;						addEventListener( Event.ADDED_TO_STAGE, onAddedToStage);					}		function onAddedToStage( e:Event) {			var memberData = Main.CONF.getMemberDataHash( m_uid);			m_bitmap.bitmapData = Main.CONF.getMemberImgBmpdata( memberData.img);						setLoaderSizePosi();		}				// 講師用関数		public function blinkChatBtn() {			m_btnChat.blink();		}				// 講師用関数		function onHereClick( e:MouseEvent) {			if ( so_here==null) {				alertDialog( Main.LANG.getParam( "通信エラーにより、指名を他の参加者と共有できませんでした"));				return;			}			so_here.setProperty( "named_uid", m_uid); // 指名						// 音声ON			var hash:Object = Main.CONF.getMemberDataHash( m_uid);			if( hash.mic != 1) {				hash.mic = 1;				Main.CONF.resetSo_member( m_uid, hash);			}		}				// LiveStatusManager経由で呼ばれる		public function setTerminalStatus( terminalType:String) {			switch( terminalType) {				case Main.TERMINAL_PC:					m_mobileIcon.visible = false;					break;				case Main.TERMINAL_ANDROID:					m_mobileIcon.visible = true;					break;			}		}				// ハイ		public function here() {			Tweener.addTween( m_flagHere, { y: 0, transition:"liner", time:0.5});		}		// 挙手取りやめ		public function hereOff() {			Tweener.addTween( m_flagHere, { y: - m_flagHere.height, transition:"liner", time:0.5});		}		// 欠席		public function absence() {			m_absence.visible = true;			m_absence.alpha = 0;			Tweener.removeTweens( m_absence);			Tweener.addTween( m_absence,{ alpha:1, time:3, transition:"linear", onComplete:onCompleteAbsence});		}		function onCompleteAbsence() {			m_video.clear();		}		// 出席		public function attend() {			Tweener.removeTweens( m_absence);			m_absence.visible = false;		}				public function setCamera( camera) {			m_video.attachCamera( camera);			if( camera == null) {				m_video.clear();			}		}		function onComplete ( e:Event):void {			setLoaderSizePosi();		}		function setLoaderSizePosi() {			if( m_bitmap.bitmapData != null) {				var scale_x:Number = m_video.width / m_bitmap.bitmapData.width < 1 ? m_video.width / m_bitmap.bitmapData.width : 1;				var scale_y:Number = m_video.height / m_bitmap.bitmapData.height < 1 ? m_video.height / m_bitmap.bitmapData.height : 1;				m_bitmap.scaleX = m_bitmap.scaleY = scale_x < scale_y ? scale_x : scale_y;			} else {				m_bitmap.width = m_video.width;				m_bitmap.height = m_video.height;			}						var x0:Number = 2;			var y0:Number = 2 + HEADER_H + 1;			m_bitmap.x = x0 + ( m_video.width - m_bitmap.width) / 2;			m_bitmap.y = y0 + ( m_video.height - m_bitmap.height) / 2;					}		// 受信開始		protected function startReceive():void {			if( m_rcvStarted) return;			//m_video.attachNetStream( null);			//Main.addDebugMsg( "ThumbCon(" + m_uid + ") のstartReceive");						m_receive_ns.play( m_uid);						//m_video.visible = true;			//m_video.attachNetStream( m_receive_ns);			if( stage != null) startVideo();			m_rcvStarted = true;		}		// 映像の受信開始		protected function startVideo( e:* = null):void {			if( !m_rcvStarted) return;			//if( stage == null) return;			m_receive_ns.receiveVideo( true);			m_video.attachNetStream( m_receive_ns);		}		// 映像の受信停止		function stopVideo( e:* = null):void {			if( !m_rcvStarted) return;			m_receive_ns.receiveVideo( false);			m_video.attachNetStream( null);			m_video.attachNetStream( m_receive_ns);// 音声は受信しなくちゃかもだから。			m_video.clear();		}				public function getNetStream() : MyNetStream {			return m_receive_ns;		}		public function resetNetStream() {//Main.addDebugMsg( "ThumbCon(" + m_uid + ") resetNetStream");			// 次にinitSoが再度呼ばれたときのための準備。			if( m_receive_ns != null) {				m_rcvStarted = false;				m_video.attachNetStream( null);			}		}		public function initSo( nc:NetConnection, so_here:SharedObject) : void {			m_nc = nc;						// この人の動画配信設定の変更を監視する			if( so == null) so = Main.CONF.getSo( m_uid);			if( so != null) {				so.addEventListener( SyncEvent.SYNC, onSoChanged);				//if( m_uid != Main.CONF.UID) addEventListener( Event.ENTER_FRAME, onEnterFrame);			} else {				alertDialog( Main.LANG.getParam( "通信エラー"));			}						// このコンテナが自分自身でないなら、ストリームを受信。			if( m_uid != Main.CONF.UID && m_receive_ns == null) {				m_receive_ns = new MyNetStream( m_nc, m_uid);				startReceive();			}												// 挙手関係の共有オブジェクト			this.so_here = so_here;								}		public function setVolume( volume:Number) {			m_volumeMeter.setLevel( volume);		}				function onSoChanged( e:SyncEvent) :void {			if( so.data.hash != undefined) {//alertDialog(String( m_uid) + "の動画配信設定が変更された");				if( Main.CONF.isPro( Main.CONF.UID) && m_1st) {//alertDialog(String( m_uid) + "の動画配信設定が変更された m_1st");					// 最初の一回					m_btnChat.removeEventListener( MouseEvent.CLICK, onClick_mada);					m_btnChat.addEventListener( MouseEvent.CLICK, onClick_chat);					m_nameTxt.removeEventListener( MouseEvent.CLICK, onClick_mada);					m_nameTxt.addEventListener( MouseEvent.CLICK, onClick_detail);										m_1st = false;							 				}								m_volumeCtl.setMute( so.data.hash.mic == 1 ? false : true);				if( so.data.hash.gain != m_volumeCtl.getVolume()) m_volumeCtl.setVolume( so.data.hash.gain);										//if( m_uid == "student02") alertDialog(String( m_uid) + "のhash.video:" + String( so.data.hash.video));								m_fpsMeter.setDenominator( so.data.hash.fps);				// 映像を配信しないことになってたら、Videoを非表示に				if( m_uid != Main.CONF.UID) {					if( so.data.hash.video == 0) {						stopVideo();					} else {						startVideo();					}				}							}		}		public function setFpsMeter() {			if( m_receive_ns != null) {				m_fpsMeter.setNumerator( m_receive_ns.currentFPS);								if( m_liveDelayText) {					var delay:Number = m_receive_ns.liveDelay + m_receive_ns.bufferLength;					if( delay == 0) m_liveDelayText.text = "0.00";					else m_liveDelayText.text = String( Number( Math.floor( delay * 100)) / 100);				}							if( Main.USE_RECEIVE_IDLE_CHECK_BY_LEC) {					if( m_receive_ns.currentFPS == 0 && m_prevFps != 0) {						dispatchEvent( new MemberEvent( MemberEvent.SOMETHING_WRONG_WITH_FPSMETER, m_uid));					}					m_prevFps = m_receive_ns.currentFPS;				}			}		}		/*		function onClosed(e:NetStatusEvent):void {			//alertDialog( e.info.code);			switch( e.info.code) {				case "NetConnection.Connect.Closed":					m_rcvStarted = false;					so.removeEventListener( SyncEvent.SYNC, onSoChanged);					so = null;					break;			}		}*/						// この人のm_volumeCtl（ゲイン）変更時		// 講師の場合だけ呼ばれる		function changeSoGain( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( m_uid);			hash.gain = m_volumeCtl.getVolume();			Main.CONF.resetSo_member( m_uid, hash);		}				// この人の音声権限変更時		// 講師の場合だけ呼ばれる		function changeSoMicOn( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( m_uid);			hash.mic = 1;			Main.CONF.resetSo_member( m_uid, hash);		}				// この人の音声権限変更時		// 講師の場合だけ呼ばれる		function changeSoMicOff( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( m_uid);			hash.mic = 0;			Main.CONF.resetSo_member( m_uid, hash);		}				// 詳細ボタンクリック（SO接続前）		function onClick_mada( e:MouseEvent) {			alertDialog( Main.LANG.getParam( "通信エラー"));		}		// 名前（詳細）クリック		function onClick_detail( e:MouseEvent) {			dispatchEvent( new MemberEvent( MemberEvent.POPUP_SETTING, m_uid));		}		// チャットボタンクリック		function onClick_chat( e:MouseEvent) {			dispatchEvent( new MemberEvent( MemberEvent.POPUP_SETTING_CHAT, m_uid));		}				function getText( str:String) : TextField {			var txt = new TextField();			txt.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 11);			txt.text = str;			txt.width = txt.textWidth + 4;			txt.height = txt.textHeight + 4;			return txt;		}								public function setViewWidth( w:Number):void {						var inner_w = w - 3;						m_headerBase.scaleX = inner_w;						m_nameTxt.width = inner_w - PAD;						m_video.width = inner_w;			m_video.height = inner_w / 4 * 3;			setLoaderSizePosi();						m_footerBase.y = m_video.y + m_video.height + 1;			m_footerBase.scaleX = inner_w;			m_volumeCtl.y = m_footerBase.y;			m_btnChat.y = m_footerBase.y + ( m_footerBase.height - m_btnChat.height) / 2;			m_volumeMeter.y = m_footerBase.y + ( m_footerBase.height - m_volumeMeter.height) / 2;						if( m_liveDelayText) m_liveDelayText.y = m_volumeMeter.y;						if( m_volumeCtl.visible) {				if( m_btnChat.visible) {					// 講師が受講生のコンテナを表示している状態					m_volumeMeter.x = m_volumeCtl.x + VolumeCtl.W + INNER_PAD;					m_btnChat.x = inner_w - m_btnChat.width - INNER_PAD;					m_volumeMeter.width = inner_w - ( VolumeCtl.W + m_btnChat.width + INNER_PAD * 3) - ( m_liveDelayText!=null ? ( m_liveDelayText.width - 3) : 0);					m_volumeCtl.setViewWidth( inner_w - ( m_btnChat.width + INNER_PAD * 2) - ( m_liveDelayText!=null ? ( m_liveDelayText.width - 3) : 0));					if( m_liveDelayText) m_liveDelayText.x = m_volumeMeter.x + m_volumeMeter.width + 1;				} else {					// 講師が自分自身を表示（カメラ映像を表示している）					m_volumeMeter.x = m_volumeCtl.x + VolumeCtl.W + PAD;					m_volumeMeter.width = inner_w - ( VolumeCtl.W + PAD* 2);					m_volumeCtl.setViewWidth( inner_w);				}			} else {				// 受講生が自分自身（カメラ映像）若しくは他の受講生のコンテナを表示している状態				m_volumeMeter.x = PAD + 1.5;				m_volumeMeter.width = ( inner_w - PAD * 2) - ( m_liveDelayText!=null ? ( m_liveDelayText.width - 3) : 0);								if( m_liveDelayText) m_liveDelayText.x = m_volumeMeter.x + m_volumeMeter.width + 3;			}						// ハイ フラグのX位置			m_flagHere.x = w - m_flagHere.width;						// 欠席用の半透明			m_absence.graphics.clear();			m_absence.graphics.beginFill( 0, 0.5);			m_absence.graphics.drawRect( 0, 0, m_video.width, m_video.height);			m_absence.graphics.endFill();			/*			var absenceTxt = m_absence.getChildAt( 0) as TextField;			if( absenceTxt != null) {				absenceTxt.width = m_absence.width - 10;			}*/			var h = m_footerBase.y + m_footerBase.height + 1;			m_mask.graphics.clear();			m_mask.graphics.beginFill( 0);			m_mask.graphics.drawRect( -0.75, -0.75, w+1.5, h+1.5);			m_mask.graphics.endFill();						m_base.graphics.clear();			m_base.graphics.lineStyle( 1, 0xd9d9d9, 1, false, "none");			m_base.graphics.beginFill( 0xffffff);			m_base.graphics.drawRect( 0, 0, w, h);			m_base.graphics.endFill();/*			graphics.clear();			graphics.beginFill( 0xcc0000);			graphics.drawRect( 0, 0, width, height);			graphics.endFill();*/		}		function getBitmapFilter():BitmapFilter {            var color:Number = 0xffffff;            var alpha:Number = 1;            var blurX:Number = 5;            var blurY:Number = 5;            var strength:Number = 3;            var inner:Boolean = false;            var knockout:Boolean = false;            var quality:Number = BitmapFilterQuality.HIGH;            return new GlowFilter(color,                                  alpha,                                  blurX,                                  blurY,                                  strength,                                  quality,                                  inner,                                  knockout);        }		public function getViewWidth():Number {			return m_base.width - 1;		}		public function getViewHeight():Number {			return m_base.height - 1;		}		protected function alertDialog( str:String) {			Main.addErrMsg(  "ThumbCon:" + str);		}	}}