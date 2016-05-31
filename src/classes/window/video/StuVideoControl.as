package window.video {
	import flash.display.*;
	import flash.geom.*;
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import flash.utils.*;
	import common.AlertManager;
	import common.*;
	import window.*;
	import flash.text.*;
	import window.video.list.*;
	import flash.media.H264Level;
	import flash.media.H264Profile;
	import flash.media.H264VideoStreamSettings;
	import flash.system.Capabilities;
	
	// 受講生ビデオコントロール
	// ホワイトボード書き込みやビデオ閲覧の権限変更もついでに監視してる
	public class StuVideoControl extends Sprite {
		//protected const MSG_WELCOME_01:String = "ようこそ";
		//protected const MSG_WELCOME_02:String = "さん";
		private var m_uid:String;
		private var PAD = 3;
		private var m_videoStopFlag:Boolean = false;
		private var m_nc:NetConnection = null
		private var m_mic:Microphone = null;
		private var m_cam:Camera = null;
		private var m_video:Video;
		private var m_voiceMeter:VoiceMeter;
		private var m_camBtn:CamBtn = null;
		private var m_micBtn:MicBtn = null;
		private var m_bitmap:Bitmap = null;
		private var m_welcome:TextField;
		private var publish_ns:NetStream = null;
		private var m_fpsStatus:TextField;
		
		private var m_timer:Timer;
		
		private var m_listCon:ListContainer = null;
		private var so:SharedObject = null;
		private var so_volume:SharedObject = null;
		//private var m_dummyLevel:int = 0; // 生死判定のMyNetStreamで、音声がゼロ続きにならなければSO変更を受け取り続けるから、それを基に参加中と判断するために使用する
		private var m_prevLevel:int = 0; // 前回の音量
		private var m_so_oldValue:Object = null;
		
		
		public function StuVideoControl( uid:String) {
			m_uid = uid;
			
			m_fpsStatus = TextField( addChild( new TextField()));
			var fmt:TextFormat = new TextFormat( Main.CONF.getMainFont(), "10", 0xcc0000);
			m_fpsStatus.defaultTextFormat = fmt;
			m_fpsStatus.selectable = m_fpsStatus.mouseEnabled = false;
			m_fpsStatus.text = "fps";
			m_fpsStatus.height = m_fpsStatus.textHeight + 4;
			m_fpsStatus.y = 5;
			
		}
		public function setListContainer( listCon:ListContainer) {
			m_listCon = listCon;
		}
		
		public function init( h:Number) {
			
			// サムネイルとなる画像の読み込みと配置
			m_bitmap = new Bitmap( null);
			addChild( m_bitmap);
			var imgpath:String = Main.CONF.getImgpath( m_uid);
			if( imgpath != LoadConf.NOTFOUND) m_bitmap.bitmapData = Main.CONF.getMemberImgBmpdata( imgpath);
			
			/*
			m_loader = new Loader();
			m_loader.contentLoaderInfo.addEventListener( Event.COMPLETE, onComplete);
			var imgpath:String = Main.CONF.getImgpath( m_uid);
			if( imgpath != LoadConf.NOTFOUND) m_loader.load( new URLRequest( imgpath));
			addChild( m_loader);
			*/
									
			// カメラボタン
			m_camBtn = new CamBtn();
			m_camBtn.x = 0;
			var scale:Number = h / m_camBtn.height;
			if( scale < 1) {
				m_camBtn.scaleX = m_camBtn.scaleY = scale;
			} else {
				m_camBtn.y = Math.ceil(( h - m_camBtn.height) / 2);
			}
			addChild( m_camBtn);
			
			// ビデオ
			m_video = Video( addChild( new Video()));
			m_video.width = h / 3 * 4;
			m_video.height = h;
			m_video.visible = false;
			m_video.smoothing = true;
			m_video.x = m_camBtn.x + m_camBtn.width + PAD;
			m_video.y = 0;
			
			// ビデオの背景
			graphics.beginFill( 0xf0f0f0);
			graphics.drawRect( m_video.x, m_video.y, m_video.width, m_video.height);
			graphics.endFill();
						
			
			// マイクボタン
			m_micBtn = new MicBtn();
			m_micBtn.x = m_video.x + m_video.width + PAD + 10;
			m_micBtn.y = m_camBtn.y;
			addChild( m_micBtn);
		
			// 音量メーター
			m_voiceMeter = new VoiceMeter( 100, 15);
			m_voiceMeter.x = m_micBtn.x + m_micBtn.width + PAD;
			m_voiceMeter.y = m_camBtn.y + ( m_camBtn.height - m_voiceMeter.height) / 2;
			addChild( m_voiceMeter);
			
			// 音量タイマー
			m_timer = new Timer( 500); // 0.5秒おき
			if( ! Main.DEBUG_CANSEL_TIMER) m_timer.addEventListener( TimerEvent.TIMER, onTimer);
			
			setLoaderSizePosi();
		}
		
		
		function setLoaderSizePosi() {
			if( m_bitmap.bitmapData != null) {
				var scale_x:Number = m_video.width / m_bitmap.bitmapData.width < 1 ? m_video.width / m_bitmap.bitmapData.width : 1;
				var scale_y:Number = m_video.height / m_bitmap.bitmapData.height < 1 ? m_video.height / m_bitmap.bitmapData.height : 1;
				m_bitmap.scaleX = m_bitmap.scaleY = scale_x < scale_y ? scale_x : scale_y;
			} else {
				m_bitmap.width = m_video.width;
				m_bitmap.height = m_video.height;
			}
			
			var x0:Number = m_video.x;
			var y0:Number = m_video.y;
			m_bitmap.x = x0 + ( m_video.width - m_bitmap.width) / 2;
			m_bitmap.y = y0 + ( m_video.height - m_bitmap.height) / 2;
		}
		
		// カメラボタンクリックイベント
		function onCamBtnClick(e:MouseEvent):void {
			m_camBtn.status = !m_camBtn.status;
			
			if( ! m_camBtn.status) {
				m_video.visible = false;
				//if( m_cam != null && Camera.names.length) {
					publish_ns.attachCamera( null);
					m_video.attachCamera( null);
					if( m_listCon != null) m_listCon.setCamera( null);
				//}
			} else {
				m_video.visible = true;
				if( m_cam != null) {
					publish_ns.attachCamera( m_cam);
					m_video.attachCamera( m_cam);
				
					if( m_listCon != null) m_listCon.setCamera( m_cam);
				}
			}
		}
		// マイクボタンクリックイベント
		function onMicBtnClick(e:MouseEvent):void {
			m_micBtn.status = !m_micBtn.status;
			
			if( ! m_micBtn.status) {
				publish_ns.attachAudio( null);
			} else {
				if( m_mic != null) publish_ns.attachAudio( m_mic);
			}
		}
		// 自分が生徒の場合、更新ボタンが押された際にMain：onReload()から呼ばれる
		// 配信し直し
		public function restartPublish() :Boolean {
//Main.addDebugMsg( "StuVideoControl: restartPublish");
			if( Microphone.names.length && m_mic == null) m_mic = Microphone.getMicrophone();
			if( Camera.names.length && m_cam == null) m_cam = Camera.getCamera();
//Main.addDebugMsg( "StuVideoControl: getMicrophone");
			if( ! m_camBtn.status) {
Main.addDebugMsg( "StuVideoControl: カメラボタンがOFFなので再配信はキャンセルします");
				return false;
			}
			
			if( m_nc != null) {
				// 映像に関しては、m_camの設定値を同じ値で再設定（setModeとか）することにより
				// カメラデバイスを再認識するから、initPublishNetStreamの第1引数はtrueに。
				// 音声に関しては、m_micの設定値を再設定した後にpublish_ns.attachAudio( m_mic);をすると
				// 失敗してしまうっぽいので、initPublishNetStreamの第2引数はfalseにしとく。
				// （カメラデバイスの再認識時に音声も一瞬途切れるので、そのあたりの関係かな？）
				initPublishNetStream( true, false);
				return true;
			} else {
				return false;
			}
		}
		// 配信用ストリームの初期化
		protected function initPublishNetStream( changeCamSetting:Boolean, changeMicSetting:Boolean):void {
//Main.addDebugMsg( "StuVideoControl: initPublishNetStream publish_ns:" + publish_ns+ "  changeCamSetting:"+ changeCamSetting + "  changeMicSetting:"+ changeMicSetting);
			if( publish_ns == null) {
				publish_ns = new NetStream( m_nc);
				//FlashPlayerのバージョンを調べる
				var fp_version = uint(Capabilities.version.split(" ")[1].split(",")[0]);
				//alertDialog(fp_version);

				if( Main.USE_H264) {
AlertManager.createAlert( this , "パブリッシュの際のFlashPlayerのバージョンを11にし、ここ(StuVideoControl.as）を修正してください");					
trace( "パブリッシュの際のFlashPlayerのバージョンを11にし、ここ(StuVideoControl.as）を修正してください");					
/*					
					if (fp_version >= 11) {
						//FlashPlayerのバージョンが11以上の時
						var h264Settings:H264VideoStreamSettings = new H264VideoStreamSettings();
						//H264VideoStreamSettings = new H264VideoStreamSettings();
						h264Settings.setProfileLevel(H264Profile.BASELINE,H264Level.LEVEL_3);
						publish_ns.videoStreamSettings = h264Settings;
					} else {
						alertDialog( "FlashPlayerのバージョンが11未満(" + fp_version + ")のため、H.264配信はできません");
					}*/
				}

				publish_ns.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus);
				publish_ns.addEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
			} else {
				publish_ns.close();
			}

			// ローカルのビデオとマイクに接続
			// 自分のストリーム情報（メンバー情報）を取得
			var hash:Object = Main.CONF.getMemberDataHash( m_uid);
			
			if( m_cam != null && changeCamSetting) {
				m_cam.setMode( hash.camerawidth, hash.cameraheight, hash.fps, false); // Width, height, fps
				m_cam.setQuality( hash.bandwidth / 8, Main.CONF.CAMERA_QUALITY); // bandwidth, quality
				m_cam.setMotionLevel( Main.CONF.CAMERA_MOTIONLEVEL, 500); // motionLevel, motionTimeout 
				m_cam.setKeyFrameInterval( Main.CONF.CAMERA_KEYFRAME);
				m_cam.setLoopback( false);
			}
			//if( m_cam != null && m_listCon != null) m_listCon.setCamera( m_cam);

			if( m_mic != null && changeMicSetting) {
				if( m_mic.silenceLevel != hash.silencelevel) m_mic.setSilenceLevel( hash.silencelevel);
				if( m_mic.rate != hash.rate) m_mic.rate = hash.rate;
				if( m_mic.gain != hash.gain) m_mic.gain = hash.gain;
				//m_mic.setLoopBack( false);
				if( ! m_mic.useEchoSuppression) m_mic.setUseEchoSuppression( true);
				if( m_mic.codec != hash.audio_codec) m_mic.codec = hash.audio_codec;
			}
			if( m_mic != null) {
				m_mic.addEventListener( ActivityEvent.ACTIVITY, onActivity);
			}
			
			m_timer.start();
			
//alertDialog("配信：hash.video:" + String(hash.video) + "/ hash.mic:" + String(hash.mic) + "/ hash.fps:" + String(hash.fps));	

			if( m_cam != null && hash.video == 1) {
				publish_ns.attachCamera( m_cam);
				m_video.attachCamera( m_cam);
				if( m_listCon != null) m_listCon.setCamera( m_cam);
			} else {
				publish_ns.attachCamera( null);
				m_video.attachCamera( null);
				m_video.clear();
				if( m_listCon != null) m_listCon.setCamera( null);
			}
						
			if( m_mic != null && hash.mic == 1) {
				publish_ns.attachAudio( m_mic);
			} else {
				publish_ns.attachAudio( null);
			}
			publish_ns.publish( m_uid);
//Main.addDebugMsg( "========== StuVideoCon: publish");
//if( m_mic && changeMicSetting) Main.addDebugMsg( "Microphone.codec:" + m_mic.codec + " / Microphone.rate:" + m_mic.rate + " / Microphone.silenceLevel:" + m_mic.silenceLevel + " / Microphone.gain:" + m_mic.gain);
		}
				
		function onActivity( e:ActivityEvent) {
			if( ! e.activating) m_voiceMeter.setLevel( 0);
		}
		
		// Mainから、ネットコネクションが切れたときに呼ばれる。
		public function resetNetStream() {
//Main.addDebugMsg( "StuVideoControl: resetNetStream publish_ns:" + publish_ns);
			// 次にinitSoが再度呼ばれたときに、NetStreamを新たに生成するために、nullに戻しておく。
			if( publish_ns != null) {
				publish_ns.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus);
				publish_ns.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
				publish_ns.close();
				publish_ns = null;
			}
			m_timer.stop();
		}
		public function initSo( nc:NetConnection, so_volume:SharedObject) : void {
			m_nc = nc;
			this.so_volume = so_volume;
			
			if( Microphone.names.length && m_mic == null) m_mic = Microphone.getMicrophone();
//Main.addDebugMsg( "StuVideoControl: getMicrophone");
			if( Camera.names.length && m_cam == null) m_cam = Camera.getCamera();

			// 自分の動画配信／権限設定の変更を監視する
			if( so == null) so = Main.CONF.getSo( m_uid);
			if( so != null) {
				so.addEventListener( SyncEvent.SYNC, onSoChanged);
			}
		}

		function onSoChanged( e:SyncEvent):void {
			if( so.data.hash != undefined) {
				
				// 自分の配信設定が変わった				
				Main.CONF.apply_member( m_uid, so.data.hash); // CONFを更新
				
				m_camBtn.status = so.data.hash.video == 1 ? true : false;
				m_micBtn.status = so.data.hash.mic == 1 ? true : false;
				
				if( m_camBtn.status) m_camBtn.addEventListener( MouseEvent.CLICK, onCamBtnClick);
				else  m_camBtn.removeEventListener( MouseEvent.CLICK, onCamBtnClick);
				if( m_micBtn.status) m_micBtn.addEventListener( MouseEvent.CLICK, onMicBtnClick);
				else  m_micBtn.removeEventListener( MouseEvent.CLICK, onMicBtnClick);
				
				
				var member_latest:Member = Main.CONF.getMember( Main.CONF.UID);
				var changeCamSetting:Boolean = ! member_latest.isEqualCamSetting( m_so_oldValue);
				var changeMicSetting:Boolean = ! member_latest.isEqualMicSetting( m_so_oldValue);
//Main.addDebugMsg("StuVideoControl: onSoChanged");
				initPublishNetStream( changeCamSetting, changeMicSetting);
				m_so_oldValue = so.data.hash;
				
				if( so.data.hash.whiteboard != undefined && so.data.hash.whiteboard == 1) {
					// ホワイトボード書き込みOKをMainに知らせる
					dispatchEvent( new Event( "whiteboard ok"));
				} else {
					dispatchEvent( new Event( "whiteboard ng"));
				}
				if( so.data.hash.read != undefined && so.data.hash.read == 1) {
					// 資料閲覧OKをMainに知らせる
					dispatchEvent( new Event( "read ok"));
				} else {
					dispatchEvent( new Event( "read ng"));
				}
			}
		}
		
		// 自分自身が強制退室になった後（ネットコネクション切断直後）に呼ばれる
		public function setStatusDisconnect() {
			m_voiceMeter.setLevel( 0);
			m_camBtn.status = false;
			m_micBtn.status = false;
			setEnabled( false);
			m_camBtn.removeEventListener( MouseEvent.CLICK, onCamBtnClick);
			m_micBtn.removeEventListener( MouseEvent.CLICK, onMicBtnClick);
			m_video.attachCamera( null);
			m_timer.stop();
			m_timer.removeEventListener( TimerEvent.TIMER, onTimer);
		}
		
		public function setEnabled( b:Boolean):void {
			m_video.visible = b;
			m_camBtn.setEnabled( b);
			m_micBtn.setEnabled( b);
		}

		function alertDialog( str:String) {
			Main.addErrMsg( "StuVideoControl:" + str);
		}
		function onTimer( e:TimerEvent) {
			var level:int = 0;
			if( m_mic != null) {
				if( m_mic.activityLevel > 0 || ! m_mic.muted) {
					level = m_voiceMeter.setLevel( m_mic.activityLevel);
				}
			} else {
				m_voiceMeter.setLevel( 0);
			}

			if( so_volume != null && level != m_prevLevel) {
				if( Main.needsShare_StuVolume()) {
					so_volume.setProperty( Main.CONF.UID, level);
					m_prevLevel = level;
				}
			}
			
		}
		//ネットステータスイベントの処理
		function onNetStatus( e:NetStatusEvent):void {
//Main.addDebugMsg( "StuVideoControl:" + e.info.code);					

			switch( e.info.code) {
				case "NetStream.Unpublish.Success":
					break;
				case "NetStream.Publish.Start":
					break;
				case "NetStream.Publish.BadName":
					//leave( "参加できません");
					break;
				default:break;
			}
		}
		//セキュリティーエラーイベントの処理
		function onSecurityError( e:SecurityErrorEvent):void {
		}
		//Asyncエラーイベントの処理
		function onAsyncError( e:AsyncErrorEvent):void {
		}
		//IOエラーイベントの処理
		function onIoError( e:AsyncErrorEvent):void {
		}
	}
}
