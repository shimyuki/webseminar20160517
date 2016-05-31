package window.whiteboard.slide
{
	import flash.display.*;
	import flash.geom.*;
	import common.*;
	import window.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import window.video.WbVideo;
	import window.whiteboard.BgSelector;
	import common.AlertManager;

	// ホワイトボードに表示する１枚のスライド
	public class CamWbSlide extends WbSlide
	{
		//private const CAMERA_WIDTH = 80;
		//private const CAMERA_HEIGHT = 60;
		//private const CAMERA_FPS = 5;
		private const STATUS_PRO_CAMERA_PLAYING = 1;
		private const STATUS_WB_CAMERA_PLAYING = 2;
		private const STATUS_STREAM_RECEIVING = 3;
		private var m_status:int = -1;
		private var m_cameraid:String;
		private var m_video:Video;
		private var m_receive_ns:MyNetStream = null;
		private var m_cam:Camera = null;
		private var so_lec:SharedObject = null;
		private var so_wb:SharedObject = null;
		private var m_wbVideo:WbVideo = null;

		public function CamWbSlide( bgtype:String, cameraid:String) {
			super( bgtype);

			m_cameraid = cameraid;

			m_video = Video( m_bg.addChild( new Video()));
			m_video.width = 100;
			m_video.height = 75;
			m_video.smoothing = true;
		}

		override public function initSo( nc:NetConnection) {
			m_livePointerCon.initSo( Main.CONF.CLASS_ID + m_cameraid, nc);
trace(Main.CONF.CLASS_ID + m_cameraid);
			onLivePointerStatusChanged();
		}

		public function setSoWb( so:SharedObject) {
			so_wb = so;
			so_wb.addEventListener( SyncEvent.SYNC, onSync);
		}

		public function setWbVideo( wbVideo) {
			m_wbVideo = wbVideo;
			m_wbVideo.addEventListener( WbVideo.CAMERA_CHANGED, function( e:*) { setBg();});
		}
		public function setNs( receive_ns_pro) {
			//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "CamWbSlide:setNs:" + String( receive_ns_pro));
			if (m_receive_ns != null && receive_ns_pro != null) {
				if (m_receive_ns.getId() == receive_ns_pro.getId()) {
					//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "..... canseled");
					return;
				}
			}

			if (receive_ns_pro == null) {
				m_receive_ns = null;
			} else {
				m_receive_ns = receive_ns_pro;// 講師もしくはホワイトボードユーザのストリーム
				m_receive_ns.receiveAudio( false);
				m_status = STATUS_STREAM_RECEIVING;
			}

			m_video.clear();

			// ステージ上にaddされていたら、新しいストリームを再生し直す
			if (stage != null) {
				setBg();
			}
		}


		// WhiteboardContainer経由でWhiteboardからも呼ばれる
		override public function unsetBg()
		{
//ExternalInterface.call( "flashFunc_title", "unsetBg");
			super.unsetBg();
			m_video.attachNetStream( null);
			m_video.attachCamera( null);
		}
		function onSync( e:SyncEvent):void
		{
			if (so_wb.data.stream != undefined) {
				if (stage != null) {
					setBg();
				}
			}
		}

		// 講師の配信設定がかわったとき。
		// WB背景にも講師の映像を流していたら、カメラのON/OFFだけを反映させる。
		function onSyncLec( e:SyncEvent):void {
			if (so_lec.data.hash != undefined && m_status == STATUS_PRO_CAMERA_PLAYING) {
				if (so_lec.data.hash.video) {
					var hash:Object;
					if (so_wb != null && so_wb.data.stream != undefined) {
						hash = so_wb.data.stream;
					} else {
						hash = BgSelector.STREAM[0];
					}
					m_video.width = hash.camerawidth;
					m_video.height = hash.cameraheight;

					m_cam = Camera.getCamera();// 講師の場合は、映像ソースはデフォルト
					if( m_cam != null && Camera.names.length) {
						setCameraSetting( hash);
						m_video.attachCamera( m_cam);
					}
				} else {
					m_video.attachCamera( null);
				}
			}
		}
		function setCameraSetting( hash:Object) {
			if( m_cam.width != hash.camerawidth || m_cam.fps != hash.fps) m_cam.setMode( hash.camerawidth, hash.cameraheight, hash.fps);// Width, height, fps
			if( m_cam.bandwidth != hash.bandwidth) m_cam.setQuality( hash.bandwidth, 80);
			// bandwidth, quality;
			if( m_cam.motionLevel != Main.CONF.CAMERA_MOTIONLEVEL) m_cam.setMotionLevel( Main.CONF.CAMERA_MOTIONLEVEL, 500);
			// motionLevel, motionTimeout ;
			if( m_cam.keyFrameInterval != Main.CONF.CAMERA_KEYFRAME) m_cam.setKeyFrameInterval( Main.CONF.CAMERA_KEYFRAME);
			if( m_cam.loopback) m_cam.setLoopback( false);
		}
		// WhiteboardContainer経由でWhiteboardからSharedObjectの値変更時に呼ばれる
		override public function setBg() {
//alertDialog("CamWbSlide:setBg ");
//ExternalInterface.call( "flashFunc_title", "setBg");

			super.setBg();
			m_video.attachCamera( null);
			m_video.attachNetStream( null);

			// 講師の動画配信設定の変更を監視する
			if (so_lec == null) {
				so_lec = Main.CONF.getSo(Main.CONF.getProId());
				if (so_lec != null) {
					so_lec.addEventListener( SyncEvent.SYNC, onSyncLec);
				}
			}

			//var so:SharedObject = m_wbVideo != null ? m_wbVideo.getSo() : null;
			if (so_wb != null) {
				//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", so.data.stream + " " + (so.data.stream)?"undefined":"");
				so_wb.addEventListener( SyncEvent.SYNC, onSync);
				//so_wb.addEventListener( SyncEvent.SYNC, resizeVideo);
			}

			var hash:Object;
			if (so_wb != null && so_wb.data.stream != undefined) {
				hash = so_wb.data.stream;
			} else {
				hash = BgSelector.STREAM[0];
			}
			m_video.width = hash.camerawidth;
			m_video.height = hash.cameraheight;
			//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", m_video.width + "," + m_video.height);
			if (( Main.CONF.isPro( Main.CONF.UID) || Main.CONF.UID == Main.CONF.getWhiteboardUID()) && m_receive_ns == null) {
				// 「自分が講師もしくはホワイトボードユーザの場合」かつ「m_receive_nsがNULLの場合」は、自分の映像を流す

				if (Main.CONF.isPro(Main.CONF.UID)) {
//ExternalInterface.call( "flashFunc_title", "自分、講師の映像を流す");
Main.addDebugMsg("CamWbSlide:自分、講師の映像を流す");
					var hash_lec = Main.CONF.getMemberDataHash(Main.CONF.UID);
					if (hash_lec != null) {
						if (hash_lec.video) {
							m_cam = Camera.getCamera();// 講師の場合は、映像ソースはデフォルト
							setCameraSetting( hash);

						} else {
							m_cam = null;
							m_video.clear();
						}
					} else {
						m_cam = Camera.getCamera();// 講師の場合は、映像ソースはデフォルト
						setCameraSetting( hash);
					}

					m_status = STATUS_PRO_CAMERA_PLAYING;
				} else {
//ExternalInterface.call( "flashFunc_title", "自分、WBの映像を流す");
Main.addDebugMsg("CamWbSlide:自分、WBの映像を流す");
					// ホワイトボードユーザ
					if( m_wbVideo.getPublishStatus() != WbVideo.STATUS_NOW_ON_AIR) {
						m_wbVideo.startPublish();
					}
					m_cam = m_wbVideo != null ? m_wbVideo.getCamera():null;
					m_status = STATUS_WB_CAMERA_PLAYING;
				}

				if (m_cam != null && Camera.names.length) {
					m_video.attachCamera( m_cam);
				}
				//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "CamWbSlide:自分の映像を流す " + m_video.width + "," + m_video.height);
//alertDialog("CamWbSlide:自分の映像を流す ");

			} else {
				// 自分が受講生の場合、もしくは
				// 自分自身が講師の場合でも、ホワイトボードユーザの参加中はこちら。
				if (m_receive_ns != null) {
					m_video.attachNetStream( m_receive_ns);
					m_receive_ns.play( m_receive_ns.getId());

					//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "CamWbSlide:" + String( m_receive_ns.getId()) + "の映像を流す " + m_video.width + "," + m_video.height);;
//alertDialog("CamWbSlide:" + String( m_receive_ns.getId()) + "の映像を流す ");
//ExternalInterface.call( "flashFunc_title", String( m_receive_ns.getId()) + "の映像を流す ");
Main.addDebugMsg("CamWbSlide:" + String( m_receive_ns.getId()) + "の映像を流す ");

					m_status = STATUS_STREAM_RECEIVING;
				} else {
//ExternalInterface.call( "flashFunc_title", "流す映像がない");
Main.addDebugMsg( "CamWbSlide:流す映像がない");
					// ここにはこないはず
					//alertDialog( "CamWbSlide:error m_receive_ns is null");
					m_status = STATUS_STREAM_RECEIVING;
				}

			}
			dispatchEvent( new Event( WbSlide.BG_COMPLETE));
		}

		public function getCameraid():String {
			return m_cameraid;
		}

		public function getVideoWidth():Number {
			return m_video.width;
		}
		public function getVideoHeight():Number {
			return m_video.height;
		}
	}
}