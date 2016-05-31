﻿package window.video {	import flash.display.*;	import flash.geom.*;	import flash.events.*;	import flash.net.*;	import flash.media.*;	import flash.utils.*;	import fl.controls.ComboBox;	import common.*;	import window.*;	import window.video.list.*;	import window.video.list.parts.*;	import window.header.RecBtn;	import window.setting.SettingContents;	import window.setting.StreamComponents;	import caurina.transitions.*;	import common.AlertManager;	import flash.media.H264Level;	import flash.media.H264Profile;	import flash.media.H264VideoStreamSettings;	import flash.system.Capabilities;	import flash.text.TextField;	import flash.text.TextFormat;	// 講師ビデオ	public class ProVideo extends ResizableContainer {		static public const BEFORE_NS_INIT = "initNetStream() start";		static public const AFTER_NS_INIT = "initNetStream() finish";		static public const BEFORE_NS_PLAY = "initReceiveNetStream() before play";		static public const SOMETHING_WRONG_WITH_LEC = "SOMETHING_WRONG_WITH_LEC";		static public const START_RECORD:String = "START_RECORD";		static public const STOP_RECORD:String = "STOP_RECORD";		private const USE_PUBLISH_IDLE_CHECK:Boolean = false; // 講師が配信のアイドル状態を自分で検知して再配信するか		private var _MIN_W = 100;		private var _MIN_H = 100;		private const INIT_Y = 0;		protected var m_container:Sprite;		protected var m_containerMask:Sprite;						private var m_videoStopFlag:Boolean = false;		protected const FOOTER_COLOR:uint = 0xeeeeee;		private var m_nc:NetConnection = null		private var m_mic:Microphone = null;		private var m_cam:Camera = null;		protected var m_video:Video;		protected var m_footer:Sprite;		protected var m_footerBase:Shape;		protected var m_volumeMeter:VoiceMeter;		private var m_volumeCtl:VolumeCtl;		private var m_camCombo:ComboBox = null;		private const USE_CAM_COMBO = false;		private var m_camBtn:CamBtn = null;		//private var m_micBtn:MicBtn = null;		protected var m_bitmap:Bitmap;		private var publish_ns:NetStream = null; // 自分が講師の場合		public var receive_ns:MyNetStream = null; // 自分が講師以外の場合		//private var m_listCon:ListContainer = null;		private var m_so_lec_oldValue:Object = null;				private var so_lec:SharedObject = null;		protected var so_volume:SharedObject = null;		private var m_prevLevel:int = 0; // 前回の音量		private var m_prevFps:Number = 0; // 前回のFPS				private var m_timer:Timer;				private var m_fpsMeter:FpsMeter;		private var m_iconNetworkOff:IconNetworkOff;				private var m_delayText:TextField = null;				private var m_playing:Boolean = false;				private var m_btnRecLec:RecBtn;		private var m_rec_type:String = "";		private var m_isNormalDelivery:Boolean ;				public function ProVideo( w:Number, h:Number, isNormalDelivery:Boolean /*通常配信かiOS配信か*/) {						super( w, h, _MIN_W, _MIN_H); // min_w は後で設定し直すのでとりあえず						m_isNormalDelivery = isNormalDelivery;						// 表示コンテナ			m_container = Sprite( addChild( new Sprite()));			m_container.y = INIT_Y;						// 表示コンテナのマスク			m_containerMask = Sprite( addChild( new Sprite()));			m_containerMask.graphics.beginFill(0);			m_containerMask.graphics.drawRect( 0, 0, 1, 1);			m_containerMask.y = m_container.y;			m_container.mask = m_containerMask;						// ベースとなる画像			m_bitmap = new Bitmap( null);			m_container.addChild( m_bitmap);			var imgpath:String = Main.CONF.getImgpath( Main.CONF.getProId());			if( imgpath != LoadConf.NOTFOUND) m_bitmap.bitmapData = Main.CONF.getMemberImgBmpdata( imgpath);									m_video = Video( m_container.addChild( new Video()));			m_video.width = 320;			m_video.height = 240;			//m_video.visible = false;			m_video.smoothing = true;						m_footerBase = Shape( m_container.addChild( new Shape()));						m_footer = Sprite( m_container.addChild( new Sprite()));			m_footer.y = m_video.height;						// カメラボタン			m_camBtn = new CamBtn();			m_camBtn.y = 10;						// マイクボタン			//m_micBtn = new MicBtn();			//m_micBtn.y = m_camBtn.y;			// 音量メーター			m_volumeMeter = new VoiceMeter( 125, 15);						// ゲインコントロール			m_volumeCtl = VolumeCtl( addChild( new VolumeCtl( 0, 100)));			m_volumeCtl.setViewWidth( m_volumeMeter.width + VolumeCtl.W);			m_volumeCtl.visible = false;						// 受講者用fps割合メーター			m_fpsMeter = new FpsMeter();			m_iconNetworkOff = new IconNetworkOff();						if( Main.CONF.isPro( Main.CONF.UID)) {				// 講師				m_footer.addChild( m_camBtn);				//m_footer.addChild( m_micBtn);				m_footer.addChild( m_volumeMeter);				m_footer.addChild( m_volumeCtl);				m_camBtn.x = 10;				//m_micBtn.x = m_camBtn.x + m_micBtn.width + 3;				m_volumeMeter.x = m_camBtn.x + m_camBtn.width + 3 + VolumeCtl.W;				m_volumeMeter.y = m_camBtn.y + ( m_camBtn.height - m_volumeMeter.height) / 2;				m_volumeCtl.x = m_volumeMeter.x - VolumeCtl.W;				m_volumeCtl.y = m_volumeMeter.y - ( m_volumeCtl.height - m_volumeMeter.height) / 2;				m_volumeCtl.setViewWidth( m_volumeMeter.width + VolumeCtl.W);								// カメラコンボボックス				m_camCombo = ComboBox( m_footer.addChild( new ComboBox()));				m_camCombo.x = m_camBtn.x;				m_camCombo.y = m_camBtn.y + m_camBtn.height + 5;				m_camCombo.setSize( m_volumeCtl.x + m_volumeCtl.width - m_camCombo.x, m_camCombo.height);				m_camCombo.visible = USE_CAM_COMBO;								// 講師映像のみの録画ボタン				m_btnRecLec = new RecBtn();				m_btnRecLec.initAsNormal( 20);				if( Main.CONF.getParam("REC_LEC_BUTTON") == "1" || Main.CONF.getParam("REC_LEC_BUTTON") == LoadConf.NOTFOUND) {					m_footer.addChild( m_btnRecLec);					m_btnRecLec.x = m_camBtn.x;					m_btnRecLec.y = m_camBtn.y + m_camBtn.height + 5;					m_btnRecLec.addEventListener( MouseEvent.CLICK, onRecLec);				}								function onRecLec( e:MouseEvent) {					if( m_btnRecLec.isOn()) {						Main.addPermanentLog( "講師映像録画：録画終了ボタンクリック", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);						dispatchEvent( new Event( STOP_RECORD));						m_btnRecLec.off();					} else {						Main.addPermanentLog( "講師映像録画：録画開始ボタンクリック", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);						dispatchEvent( new Event( START_RECORD));						m_btnRecLec.on();					}				}								// カメラコンボボックスにカメラリストを入れる				for( var i = 0; i < Camera.names.length; i++) {					var item = { label:Camera.names[ i], data:String( i)};					m_camCombo.addItem( item);					if( m_camCombo.selectedItem == null) m_camCombo.selectedItem = item;				}								// 音量タイマー				m_timer = new Timer( 500); // 0.5秒おき				if( ! Main.DEBUG_CANSEL_TIMER) m_timer.addEventListener( TimerEvent.TIMER, onTimer);							} else {				// 講師以外				// カメラボタン／マイクボタンは非表示				m_footer.addChild( m_volumeMeter);				m_volumeMeter.x = 10;				m_volumeMeter.y = 8;				m_volumeCtl.visible = false;								if( Main.SHOW_LIVE_DELAY_TEXT) {					m_delayText = TextField( m_footer.addChild( new TextField()));					m_delayText.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 11, 0x999999);					m_delayText.x = 10;					m_delayText.y = m_volumeMeter.y + m_volumeMeter.height + 2;										m_delayText.width = 150;					m_delayText.height = 20;				}								if( ! Main.CONF.isView( Main.CONF.UID)) {					// 映像の不具合報告ボタン					var btn:DynamicTextBtn = new DynamicTextBtn( Main.LANG.getParam( "映像不具合を報告"));					m_footer.addChild( btn);					btn.setEnabled( true);					btn.x = m_volumeMeter.x;					btn.y = m_volumeMeter.y + m_volumeMeter.height + 5;					btn.addEventListener( MouseEvent.CLICK, function( e:*) {										 dispatchEvent( new Event( SOMETHING_WRONG_WITH_LEC));										 });					// 不具合報告ボタンは非表示btn.visible = false;				}								/*				// FPSメーター				addChild( m_fpsMeter);				addChild( m_iconNetworkOff);				m_fpsMeter.x = m_video.x + 5;				m_fpsMeter.y = m_video.y + 3;				m_iconNetworkOff.x = m_fpsMeter.x - m_video.x;				m_iconNetworkOff.y = m_fpsMeter.y - m_video.y;				*/			}			setLoaderSizePosi();		}				public function sendMetaData() {			publish_ns.client = this;			var metaData:Object = new Object();			metaData.title = Main.CONF.getParam( 'APP_NAME') +" stream";			metaData.width = m_cam.width;			metaData.height = m_cam.height;			publish_ns.send( "onMetaData", metaData);			//publish_ns.send("@setDataFrame", "onMetaData", metaData);Main.addDebugMsg( "メタデータにサイズ情報送信 width:" + m_cam.width + "/ height:"+ m_cam.height);		}				// Mainから呼ばれ、HEADER_CONにてvisibleのON/OFFを管理される		public function getBtnRecLec() {			return m_btnRecLec;		}				// 講師用関数		// 講師画面にて、WBでカメラ背景が選択されたとき、もし講師カメラがOFFの状態だとWB映像も映らなくなってしまうので、		public function forceCameraOn() {			// 映像OFFになっていた場合、強制的にONにする			if( ! m_camBtn.status) {				onCamBtnClick();			}			/*			var hash:Object = Main.CONF.getMemberDataHash( Main.CONF.getProId());											if( hash != null && hash.video != 1) {				hash.video = 1;				Main.CONF.resetSo_member( Main.CONF.getProId(), hash);			}*/		}		public function getFpsMeter() : Sprite {			var con:Sprite = new Sprite();			con.addChild( m_fpsMeter);			con.addChild( m_iconNetworkOff);			m_fpsMeter.y = m_iconNetworkOff.y = 8;			return con;		}		// 講師用関数		// 環境設定で録画するしないの設定時に呼ばれる		// もしくは最初から録画しない場合（iOS配信）のときのために、このクラスのonSoLecChangedから呼ばれる		public function setRec( rec_type:String) : Boolean {			if( !Main.CONF.isPro( Main.CONF.UID)) return false;			if( m_rec_type == rec_type) return false; // 変更無し						// 録画中だったら録画を止める			if( m_btnRecLec.isOn()) {				dispatchEvent( new Event( STOP_RECORD));				m_btnRecLec.off();			}						m_rec_type = rec_type;			switch( rec_type) {				case StreamComponents.REC_TYPE_0: // 録画しない					m_btnRecLec.visible = false;					break;				default:					m_btnRecLec.visible = true;					break;			}			return true;		}		public function getRecType() : String {			return m_rec_type;		}				// 受講生の場合、Main_testから呼ばれる		public function getFpsRate() : Number {			return m_fpsMeter.getRate();		}				// Main_viewからよばれる。		// 録画画面はタイトルバーが無いので、FPSメーターを左上に表示する		public function setFpsMeterOnVideo() {			m_footer.addChild( m_fpsMeter);			m_footer.addChild( m_iconNetworkOff);			m_fpsMeter.x = m_iconNetworkOff.x = m_volumeMeter.x + m_volumeMeter.width + 5;			m_fpsMeter.y = m_iconNetworkOff.y = m_volumeMeter.y;		}		/*		public function setListContainer( listCon:ListContainer) {			m_listCon = listCon;		}*/		protected function setLoaderSizePosi() {			if( m_bitmap.bitmapData != null) {				var scale_x:Number = m_video.width / m_bitmap.bitmapData.width < 1 ? m_video.width / m_bitmap.bitmapData.width : 1;				var scale_y:Number = m_video.height / m_bitmap.bitmapData.height < 1 ? m_video.height / m_bitmap.bitmapData.height : 1;				m_bitmap.scaleX = m_bitmap.scaleY = scale_x < scale_y ? scale_x : scale_y;			} else {				m_bitmap.width = m_video.width;				m_bitmap.height = m_video.height;			}						var x0:Number = m_video.x;			var y0:Number = m_video.y;			m_bitmap.x = x0 + ( m_video.width - m_bitmap.width) / 2;			m_bitmap.y = y0 + ( m_video.height - m_bitmap.height) / 2;		}				// 自分が講師の場合呼ばれる		// カメラボタンクリックイベント		function onCamBtnClick( e:MouseEvent = null):void {			m_camBtn.status = !m_camBtn.status;						if( ! m_camBtn.status) {					publish_ns.attachCamera( null);					m_video.attachCamera( null);					m_video.clear();					//if( m_listCon != null) m_listCon.setCamera( null);			} else {				//m_video.visible = true;				if( m_cam != null) {					publish_ns.attachCamera( m_cam);					m_video.attachCamera( m_cam);					//if( m_listCon != null) m_listCon.setCamera( m_cam);				}			}						Main.CONF.resetSo_member( Main.CONF.UID, { video:m_camBtn.status?1:0});		}				function onCameraChange( e:Event) {			m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));			startPublish( true, false);		}				// 自分が講師の場合、WBの背景がカメラ映像以外に切り替わった際に		// Main：resetCameraSize()から呼ばれる		// 自分が講師の場合、更新ボタンが押された際にMain：onReload()から呼ばれる		// 配信し直し		public function restartPublish(): Boolean {//Main.addDebugMsg( "ProVideo: restartPublish");			if( Microphone.names.length) m_mic = Microphone.getMicrophone();//Main.addDebugMsg( "ProVideo: getMicrophone");			if( Camera.names.length) m_cam = Camera.getCamera();						if( publish_ns != null) {				startPublish( true, false);				return true;			} else {				return false;			}		}				// Mainから、ネットコネクションが切れたときに呼ばれる。		public function resetNetStream() {			// 次にinitSoが再度呼ばれたときに、NetStreamを新たに生成するために、nullに戻しておく。			if( publish_ns != null) {				publish_ns.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus);				publish_ns.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError);				publish_ns.close();				publish_ns = null;				m_timer.stop();			}			if( receive_ns != null) {				receive_ns.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus_stu);				receive_ns.close();				receive_ns = null;				m_playing = false;			} //Main.addDebugMsg( "ProVideo: resetNetStream");					}				// 自分が講師の場合呼ばれる		// 配信用ストリームの初期化		function startPublish( changeCamSetting:Boolean, changeMicSetting:Boolean):void {			Main.addDebugMsg( "ProVideo: startPublish");			if( publish_ns == null) {				publish_ns = new NetStream( m_nc);								//FlashPlayerのバージョンを調べる				var fp_version = uint(Capabilities.version.split(" ")[1].split(",")[0]);				//alertDialog(fp_version);				if( Main.USE_H264) {//AlertManager.createAlert( this , "パブリッシュの際のFlashPlayerのバージョンを11にし、ここ(ProVideo.as）を修正してください");					trace( "パブリッシュの際のFlashPlayerのバージョンを11にし、ここ(ProVideo.as）を修正してください");					if (fp_version >= 11) {												try {						//FlashPlayerのバージョンが11以上の時						var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();						//h264Settings.setProfileLevel(H264Profile.BASELINE,H264Level.LEVEL_3);						h264Settings.setProfileLevel(H264Profile.BASELINE,H264Level.LEVEL_3_1);						publish_ns.videoStreamSettings = h264Settings;						Main.addErrMsg( "ProVideo: h264Settings:OK");						} catch( e:*) {Main.addErrMsg( "ProVideo: " + e.text);													}											} else {						AlertManager.createAlert( this , "FlashPlayerのバージョンが11未満(" + fp_version + ")のため、iOS向けのHTTP Live Streamingはできません");						//AlertManager.createAlert( this , "FlashPlayerのバージョンが11未満(" + fp_version + ")のため、H.264配信はできません");					}									}				publish_ns.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus);				publish_ns.addEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError);			} else {				publish_ns.close();			}			// ローカルのビデオとマイクに接続			// 講師のストリーム情報（メンバー情報）を取得			var hash:Object = ( so_lec && so_lec.data.hash) ? so_lec.data.hash : Main.CONF.getMemberDataHash( Main.CONF.getProId());						if( m_cam != null && changeCamSetting) {				m_cam.setMode( hash.camerawidth, hash.cameraheight, hash.fps, false); // Width, height, fps				m_cam.setQuality( hash.bandwidth / 8, Main.CONF.CAMERA_QUALITY); // bandwidth, quality				//if( Main.DEBUG_ALERT) alertDialog( "setQuality(" + hash.bandwidth / 8+","+ Main.CONF.CAMERA_QUALITY+")");				m_cam.setMotionLevel( Main.CONF.CAMERA_MOTIONLEVEL, 500); // motionLevel, motionTimeout 				//m_cam.setMotionLevel( 20, 500); // motionLevel, motionTimeout 				m_cam.setKeyFrameInterval( Main.CONF.CAMERA_KEYFRAME);				m_cam.setLoopback( false);			}			if( m_mic != null && changeMicSetting) {				if( m_mic.silenceLevel != hash.silencelevel) m_mic.setSilenceLevel( hash.silencelevel);				if( m_mic.rate != hash.rate) m_mic.rate = hash.rate;				if( m_mic.gain != hash.gain) m_mic.gain = hash.gain;				//m_mic.setLoopBack( false);				if( ! m_mic.useEchoSuppression) m_mic.setUseEchoSuppression( true);				if( m_mic.codec != hash.audio_codec) m_mic.codec = hash.audio_codec;			}			if( m_mic != null) {				m_mic.addEventListener( ActivityEvent.ACTIVITY, onActivity);			}			//if( m_mic.rate == 44) m_mic.codec = SoundCodec.SPEEX;						m_timer.start();						if( m_cam != null && hash.video == 1) {				publish_ns.attachCamera( m_cam);				m_video.attachCamera( m_cam);				//m_listCon.setCamera( m_cam);			} else {				publish_ns.attachCamera( null);				m_video.attachCamera( null);				m_video.clear();				//m_listCon.setCamera( null);			}									if( m_mic != null && hash.mic == 1) publish_ns.attachAudio( m_mic);			else publish_ns.attachAudio( null);			//else publish_ns.attachAudio( null);//if( ! m_publishStarted) alertDialog( "講師映像の配信開始 loopback:" + m_cam.loopback);//else alertDialog( "講師映像の配信そのままに loopback:" + m_cam.loopback);			if( Main.USE_H264 && !m_isNormalDelivery) {				publish_ns.publish( "mp4:" + Main.CONF.UID);Main.addDebugMsg( "ProVideo: publish開始 (mp4配信)"+ " publish_ns.videoCodec:" + publish_ns.videoCodec);			} else {				publish_ns.publish( Main.CONF.UID);Main.addDebugMsg( "ProVideo: publish開始(flv配信)"+ " publish_ns.videoCodec:" + publish_ns.videoCodec);			}			//publish_ns.publish( Main.CONF.UID);												//if( m_mic && changeMicSetting) Main.addDebugMsg( "Microphone.codec:" + m_mic.codec + " / Microphone.rate:" + m_mic.rate + " / Microphone.silenceLevel:" + m_mic.silenceLevel + " / Microphone.gain:" + m_mic.gain);		}		public function setRcvBufferTime( bt:Number) {			if( !receive_ns) return;			receive_ns.bufferTime = bt;			receive_ns.play( Main.CONF.getProId());//Main.addErrMsg( Main.LANG.getParam( "講師映像表示のバッファ時間（再play）") +" : "+ receive_ns.bufferTime + " sec");		}		function onActivity( e:ActivityEvent) {			if( ! e.activating) m_volumeMeter.setLevel( 0);		}						public function initSo( nc:NetConnection, so_volume:SharedObject) : void {			m_nc = nc;			this.so_volume = so_volume;			if( Main.CONF.isPro( Main.CONF.UID)) {				// 自分自身が講師なら								if( Microphone.names.length && m_mic == null) m_mic = Microphone.getMicrophone();//Main.addDebugMsg( "ProVideo: getMicrophone");							if( USE_CAM_COMBO) {					if( Camera.names.length && m_cam == null) m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));					m_camCombo.addEventListener( Event.CHANGE, onCameraChange);				} else {					if( Camera.names.length && m_cam == null) m_cam = Camera.getCamera();				}			}						// 講師の動画配信設定の変更を監視する			so_lec = Main.CONF.getSo( Main.CONF.getProId());//Main.addDebugMsg( "ProVideo:initSo() so_lec:" + so_lec);			if( so_lec != null) {				so_lec.addEventListener( SyncEvent.SYNC, onSoLecChanged);				if( Main.CONF.isPro( Main.CONF.UID)) {					m_volumeCtl.addEventListener( Event.CHANGE, changeSoGain);					m_volumeCtl.addEventListener( VolumeCtl.MUTE_OFF, changeSoMicOn);					m_volumeCtl.addEventListener( VolumeCtl.MUTE_ON, changeSoMicOff);				} else {//trace("-----------------koko");					if( ! Main.DEBUG_CANSEL_ENTERFRAME) addEventListener( Event.ENTER_FRAME, onEnterFrame);				}			} else {				Main.addErrMsg( "ProVideo:initSo() " + Main.LANG.getParam( "通信エラーにより、講師の動画配信設定のSharedObjectを取得できませんでした"));			}		}				public function setVolume( volume:Number) {			m_volumeMeter.setLevel( volume);		}		function onEnterFrame( e:Event) {			if( receive_ns != null) {				m_fpsMeter.setNumerator( receive_ns.currentFPS);				if( m_delayText) {					var delay:Number = receive_ns.liveDelay + receive_ns.bufferLength;					if( delay == 0) m_delayText.text = "delay: 0.00";					else m_delayText.text = "delay: " + String( Number( Math.floor( delay * 100)) / 100) + " (" + String( Number( Math.floor( receive_ns.liveDelay * 100)) / 100)+ "+" + String( Number( Math.floor( receive_ns.bufferLength * 100)) / 100) + ")";				}//trace( "ProVideo currentFPS:"+receive_ns.currentFPS + " liveDelay:" + receive_ns.liveDelay + " bufferLength:" + receive_ns.bufferLength);				if( Main.USE_RECEIVE_IDLE_CHECK_BY_STU) {					if( receive_ns.currentFPS == 0 && m_prevFps != 0) {						dispatchEvent( new Event( SOMETHING_WRONG_WITH_LEC));					}					m_prevFps = receive_ns.currentFPS;				}			}		}		public function getDelivery() : String {			if( so_lec && so_lec.data.hash && so_lec.data.hash.delivery) return so_lec.data.hash.delivery;			return "";		}		function onSoLecChanged( e:SyncEvent):void {//Main.addDebugMsg( "------------- ProVideo:onSoLecChanged");			if( Main.CONF.isPro( Main.CONF.UID)) {				for each( var obj in e.changeList) {					if( obj.name == "hash") {						// 配信タイプのチェック												if( so_lec.data.hash.delivery == Member.DELIVERY_IOS) {							setRec( StreamComponents.REC_TYPE_0);						}												m_camBtn.addEventListener( MouseEvent.CLICK, onCamBtnClick);						//m_micBtn.addEventListener( MouseEvent.CLICK, onMicBtnClick);												m_camBtn.status = so_lec.data.hash.video == 1 ? true : false;						//m_micBtn.status = so_lec.data.hash.mic == 1 ? true : false;						m_volumeCtl.setMute( so_lec.data.hash.mic == 1 ? false : true);						if( so_lec.data.hash.gain != m_volumeCtl.getVolume()) m_volumeCtl.setVolume( so_lec.data.hash.gain);												var member_latest:Member = Main.CONF.getMember( Main.CONF.UID);						var changeCamSetting:Boolean = ! member_latest.isEqualCamSetting( /*obj.oldValue*/ m_so_lec_oldValue);						var changeMicSetting:Boolean = ! member_latest.isEqualMicSetting( /*obj.oldValue*/ m_so_lec_oldValue);						startPublish( changeCamSetting, changeMicSetting);																		m_so_lec_oldValue = so_lec.data.hash;					}				}			} else {				if( so_lec.data.hash != undefined) {					m_fpsMeter.setDenominator( so_lec.data.hash.fps);				}			}			setViewWidth( getViewWidth());			setViewHeight( getViewHeight());		}				/*function onClosed(e:NetStatusEvent):void {			//alertDialog( e.info.code);			switch( e.info.code) {				case "NetConnection.Connect.Closed":					m_publishStarted = false;					publish_ns = null;					receive_ns = null;					so_lec.removeEventListener( SyncEvent.SYNC, onSoLecChanged);					so_lec = null;					break;			}		}*/				// この人のm_volumeCtl（ゲイン）変更時		// 講師の場合だけ呼ばれる		function changeSoGain( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( Main.CONF.getProId());			hash.gain = m_volumeCtl.getVolume();			Main.CONF.resetSo_member( Main.CONF.getProId(), hash);		}				// この人の音声権限変更時		// 講師の場合だけ呼ばれる		function changeSoMicOn( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( Main.CONF.getProId());			hash.mic = 1;			Main.CONF.resetSo_member( Main.CONF.getProId(), hash);		}				// この人の音声権限変更時		// 講師の場合だけ呼ばれる		function changeSoMicOff( e:Event) {			var hash:Object = Main.CONF.getMemberDataHash( Main.CONF.getProId());			hash.mic = 0;			Main.CONF.resetSo_member( Main.CONF.getProId(), hash);		}					// 自分が生徒の場合呼ぶ		// 講師映像の受信開始		public function startReceive() : void {			//m_video.clear();			if( receive_ns == null) receive_ns = new MyNetStream( m_nc, Main.CONF.getProId());			receive_ns.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus_stu);			if( !m_playing) {				receive_ns.play( Main.CONF.getProId());//Main.addDebugMsg("ProVideo startReceive() yes");			} else {//Main.addDebugMsg("ProVideo startReceive() no");			}			m_video.attachNetStream( receive_ns);		}		function setVideoHeight() {			if( so_lec != null && so_lec.data && so_lec.data.hash) {				m_video.height = m_video.width / so_lec.data.hash.camerawidth * so_lec.data.hash.cameraheight;			} else {				m_video.height = m_video.width / 4 * 3;			}			setLoaderSizePosi();		}				// 自分が生徒の場合LiveStatusManagerから呼ぶ		public function changeJoinStatus( b_attend:Boolean) {//trace("ProVideo changeJoinStatus" + String( b_attend));			if( b_attend) attend();			else absence();		}		// 欠席		function absence() {			m_iconNetworkOff.visible = true;			m_iconNetworkOff.alpha = 0;			Tweener.removeTweens( m_iconNetworkOff);			Tweener.addTween( m_iconNetworkOff,{ alpha:1, time:3, transition:"linear", onComplete:onCompleteAbsence});		}		function onCompleteAbsence() {			m_video.clear();		}		// 出席		function attend() {			m_iconNetworkOff.visible = false;		}		// 自分自身が強制退室になった後（ネットコネクション切断直後）にMainから呼ばれる		public function setStatusDisconnect() {			m_video.clear();			absence();			if( m_volumeMeter) m_volumeMeter.setLevel( 0);			if( m_delayText) m_delayText.text = "";		}						override public function setEnabled( b:Boolean):void {//alertDialog( "setEnabled" + b);			//m_video.visible = b;			m_camBtn.setEnabled( b);			//m_micBtn.setEnabled( b);			if( Main.CONF.isPro( Main.CONF.UID)) m_volumeCtl.visible = b;		}				override public function setViewWidth( w:Number, debug:String = ""):void {			if( w < MIN_W) w = MIN_W;			super.setViewWidth( w);			//if( debug!="") if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", w + " :" + debug + " -- ProVideo:setViewWidth");//else if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", w + " :" + "ProVideo:debug:不明");			m_containerMask.width = w;						//講師のカメラサイズを調べる			var hash:Object = Main.CONF.getMemberDataHash( Main.CONF.getProId());//ExternalInterface.call( "flashFunc_title", "ProVideo:setViewWidth() " + hash.camerawidth + "," + hash.cameraheight)			m_video.width = w;			setVideoHeight();			//m_video.height = w / hash.camerawidth * hash.cameraheight;						// 画像サイズと位置			setLoaderSizePosi();						m_footerBase.graphics.clear();			m_footerBase.graphics.beginFill( FOOTER_COLOR);			m_footerBase.graphics.drawRect( 0, m_video.height, w, getViewHeight() - m_video.height);			m_footerBase.graphics.endFill();		}		override public function setViewHeight( h:Number):void {			if( h < MIN_H) h = MIN_H;			super.setViewHeight( h);						m_containerMask.height = h;						m_footer.y = m_video.height;						m_footerBase.graphics.clear();			m_footerBase.graphics.beginFill( FOOTER_COLOR);			m_footerBase.graphics.drawRect( 0, m_video.height, getViewWidth(), h - m_video.height);			m_footerBase.graphics.endFill();		}				// 講師用		function onTimer( e:TimerEvent) {			var level:int = 0;			if( m_mic != null) {				if( m_mic.activityLevel > 0 || ! m_mic.muted) level = m_volumeMeter.setLevel( m_mic.activityLevel);			} else {				m_volumeMeter.setLevel( 0);			}			if( so_volume != null && level != m_prevLevel) {				if( Main.needsShare_LecVolume()) {					so_volume.setProperty( Main.CONF.UID, level);					m_prevLevel = level;//trace(level);									} else {//trace("stage == null");									}			}		}		//ネットステータスイベントの処理		function onNetStatus( e:NetStatusEvent):void {Main.addDebugMsg("ProVideo:"+e.info.code);			switch( e.info.code) {				case "NetStream.Publish.Idle":					if( USE_PUBLISH_IDLE_CHECK) {						Main.addErrMsg("ProVideo: you are not publishing anything , u r in idle state. try republish.");						restartPublish();					}					break;				case "NetStream.Unpublish.Success":					break;				case "NetStream.Publish.Start":					sendMetaData();//Main.addErrMsg( "録画開始");								//m_nc.call("startRecording", null, Main.CONF.UID, { append:true, versionFile:true, startOnKeyFrame:true, recordData:false});					break;				case "NetStream.Publish.BadName":					//leave( "参加できません");					break;				default:break;			}		}				//ネットステータスイベントの処理		function onNetStatus_stu( e:NetStatusEvent):void {Main.addDebugMsg("ProVideo:onNetStatus_stu: "+e.info.code);			switch( e.info.code) {				case "NetStream.Play.Start":					m_playing = true;//Main.addDebugMsg("ProVideo:onNetStatus_stu: m_playing = true");					break;				case "NetStream.Play.Stop":					break;				case "NetStream.Play.Reset":					break;				case "NetStream.Play.PublishNotify":					break;				case "NetStream.Play.UnpublishNotify":					break;				case "NetStream.Play.StreamNotFound":					m_playing = false;//Main.addDebugMsg("ProVideo:onNetStatus_stu: m_playing = false");					break;				case "NetStream.Buffer.Full":					break;				case "NetStream.Buffer.Empty":					break;				default:break;			}		}		//セキュリティーエラーイベントの処理		function onSecurityError( e:SecurityErrorEvent):void {		}		//Asyncエラーイベントの処理		function onAsyncError( e:AsyncErrorEvent):void {		}		//IOエラーイベントの処理		function onIoError( e:AsyncErrorEvent):void {		}	}}