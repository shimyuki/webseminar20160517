package window.video {
	import flash.display.*;
	import flash.events.*;
	import flash.net.*;
	import flash.media.*;
	import common.AlertManager;
	import fl.controls.ComboBox;
	import window.whiteboard.WhiteboardContainer;
	import flash.media.H264Level;
	import flash.media.H264Profile;
	import flash.media.H264VideoStreamSettings;
	import flash.system.Capabilities;
	
	// ホワイトボードユーザのビデオ配信を設定＆実行するクラス。
	// ホワイトボードユーザ以外に関しては、receive_nsを設定して受信するためのクラス
	public class WbVideo extends Sprite {
		static public const BEFORE_NS_PLAY = "initReceiveNetStream() before play";
		static public const CAMERA_CHANGED = "CAMERA_CHANGED"; // CamWbSlideがリッスン
		private const W = 140;
		private const MAX_W_COMBO = 400;
		private var m_nc:NetConnection = null;
		private var m_cam:Camera = null;
		public var publish_ns:NetStream = null; // 自分がWBユーザの場合
		public var receive_ns:MyNetStream = null; // 自分がWBユーザ以外の場合
		
		private var m_camCombo:ComboBox = null;
		
		private var so_wb:SharedObject = null;
		
		// 配信状況
		static public const STATUS_NOW_ON_AIR:int = 1;
		private const STATUS_STOPED:int = 0;
		private const STATUS_NO_CAMERA:int = -1;
		private var m_publishStatus:int = STATUS_STOPED;
		//private var m_prevHash:Object = new Object();
		
		
		public function WbVideo() {
			if( Main.CONF.UID == Main.CONF.getWhiteboardUID()) {
				m_camCombo = ComboBox( addChild( new ComboBox()));
				m_camCombo.setSize( W, 22);
				m_camCombo.dropdown.addEventListener( MouseEvent.ROLL_OUT , onItemRollOut_comboImg);
				m_camCombo.dropdown.addEventListener( MouseEvent.ROLL_OVER , onItemRollOver_comboImg);
				// カメラコンボボックスにカメラリストを入れる
				for( var i = 0; i < Camera.names.length; i++) {
					var item = { label: Camera.names[ i], data:String( i)};
					m_camCombo.addItem( item);
					if( m_camCombo.selectedItem == null) m_camCombo.selectedItem = item;
				}
				resetComboWidth( m_camCombo);
				
				m_camCombo.addEventListener( Event.CHANGE, onCameraChange);
				function onCameraChange( e:Event) {
					if( m_publishStatus == STATUS_NOW_ON_AIR) {
						m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));
						startPublish_private();
					}
					
				}
			}
		}
		
		// WhiteboardContainerのinitSoで呼ばれる
		public function setSoWb( so:SharedObject, nc:NetConnection) {
			m_nc = nc;
			so_wb = so;
			if( Main.CONF.UID == Main.CONF.getWhiteboardUID()) so_wb.addEventListener( SyncEvent.SYNC, onSync);
		}
		function onSync( e:SyncEvent) {
			if( m_publishStatus != STATUS_NOW_ON_AIR) return;
			startPublish_private();
		}
		
		// 自分がWBユーザの場合、更新ボタンが押された際にMain：onReload()から呼ばれる
		// 配信し直し
		public function restartPublish() : Boolean{
			if( publish_ns != null) {
				if( m_publishStatus == STATUS_NOW_ON_AIR) startPublish_private();
				return true;
			} else {
				return false;
			}
		}
		
		// Mainから、ネットコネクションが切れたときに呼ばれる。
		public function resetNetStream() {
			// 次にinitSoが再度呼ばれたときに、NetStreamを新たに生成するために、nullに戻しておく。
			if( publish_ns != null) {
				publish_ns.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus);
				publish_ns.removeEventListener( AsyncErrorEvent.ASYNC_ERROR, onAsyncError);
				publish_ns.close();
				publish_ns = null;
			}
			if( receive_ns != null) {
				receive_ns.close();
				receive_ns.removeEventListener( NetStatusEvent.NET_STATUS, onNetStatus);
				receive_ns = null;
			} 
		}
		
		// WhiteboardContainerのsetSo_wbNow()から呼ばれる
		public function startPublish():void {
			startPublish_private();
		}
		
		// WhiteboardContainerのsetSo_wbNow()から呼ばれる
		public function stopPublish():void {
			if( publish_ns != null) {
				publish_ns.attachCamera( null);
				publish_ns.close();
			}
			
			m_publishStatus = STATUS_STOPED;
		}
		
		// CamWbSlideのsetBgから呼ばれる
		public function getPublishStatus() : int {
			return m_publishStatus;
		}
		
		// 自分がWBユーザの場合呼ばれる
		// 配信用ストリームの初期化
		function startPublish_private():void {
//alertDialog( 'startPublish_private');
			if( so_wb.data.stream == undefined) return;
			if( m_cam == null) {
				m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));
				m_cam.setMotionLevel( Main.CONF.CAMERA_MOTIONLEVEL, 500); // motionLevel, motionTimeout 
				m_cam.setKeyFrameInterval( Main.CONF.CAMERA_KEYFRAME);
				m_cam.setLoopback( false);
			}
			
			if( m_cam != null && Camera.names.length) {
				if( m_cam.width != so_wb.data.stream.camerawidth) {
					m_cam.setMode( so_wb.data.stream.camerawidth, so_wb.data.stream.cameraheight, so_wb.data.stream.fps, false); // Width, height, fps
					dispatchEvent( new Event( CAMERA_CHANGED)); // CamWbSlideに知らせる
				}
				if( m_cam.bandwidth != so_wb.data.stream.bandwidth / 8)
					m_cam.setQuality( so_wb.data.stream.bandwidth / 8, Main.CONF.CAMERA_QUALITY); // bandwidth, quality
			}

			if( publish_ns == null) {
				publish_ns = new NetStream( m_nc);
				
				//FlashPlayerのバージョンを調べる
				var fp_version = uint(Capabilities.version.split(" ")[1].split(",")[0]);
				//alertDialog(fp_version);

				if( Main.USE_H264) {
AlertManager.createAlert( this ,"パブリッシュの際のFlashPlayerのバージョンを11にし、ここ(StuVideoControl.as）を修正してください");					
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

			
			publish_ns.attachAudio( null);
			if( m_cam != null) {
				publish_ns.attachCamera( m_cam);
				publish_ns.publish( Main.CONF.UID);
				m_publishStatus = STATUS_NOW_ON_AIR;
				
			} else {
				publish_ns.attachCamera( null);
				m_publishStatus = STATUS_NO_CAMERA;
			}
		}

		/*function onSync1st( e:SyncEvent) {
			if( so_wb.data.stream == undefined) return;
			// 自分がWBユーザの場合
			if( Main.CONF.UID == Main.CONF.getWhiteboardUID()) {
				m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));
				m_camCombo.addEventListener( Event.CHANGE, onCameraChange);
				function onCameraChange( e:Event) {
					m_cam = Camera.getCamera( String( m_camCombo.selectedItem.data));
					startPublish_private();
					dispatchEvent( new Event( CAMERA_CHANGED)); // CamWbSlideに知らせる
				}
				
				startPublish_private();
				
				so_wb.addEventListener( SyncEvent.SYNC, function( e:SyncEvent) {			
					startPublish_private();
				});
			}
			so_wb.removeEventListener( SyncEvent.SYNC, onSync1st);
			
		}*/
		
		// 自分がWBユーザの場合、CamWbSlideに呼ばれる。
		public function getCamera(): Camera {
//trace("-----------------------------");
			return m_cam;
		}
		
				
		// WBユーザ以外（講師or受講生）の場合
		public function startReceive( nc:NetConnection) {
			if( m_nc == null) m_nc = nc;
				
			if( receive_ns == null) receive_ns = new MyNetStream( m_nc, Main.CONF.getWhiteboardUID());
			receive_ns.addEventListener( NetStatusEvent.NET_STATUS, onNetStatus);
			receive_ns.play( Main.CONF.getWhiteboardUID());
		}

		public function getViewWidth() : Number { return W;}

		function alertDialog( str:String) {
			Main.addDebugMsg( "WbVideo:" + str);
		}


		//ネットステータスイベントの処理
		function onNetStatus( e:NetStatusEvent):void {
//alertDialog( e.info.code);
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
		function resetComboWidth( combo:ComboBox) {
			if( combo.length == 0) return;
			// ドロップダウンリストのテキストの長さに基づいて dropdownWidth プロパティを設定
			var tmp = combo.selectedItem; // ちょっととっておく
			var maxLength:Number = 0;
			var i:uint;
			for (i = 0; i < combo.length; i++) {
				combo.selectedIndex = i;
				combo.drawNow();
				var currText:String = combo.text;
				var currWidth:Number = combo.textField.textWidth;
				maxLength = Math.max( currWidth, maxLength);
			}
			combo.dropdownWidth = maxLength + 30 > MAX_W_COMBO ? MAX_W_COMBO : maxLength + 30;
			combo.selectedItem = tmp;
		}
		function onItemRollOut_comboImg( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = false;
		}
		function onItemRollOver_comboImg( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = true;
		}
	}
}
