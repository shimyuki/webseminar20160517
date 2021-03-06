﻿package window.header {
	import flash.display.*;
	import flash.geom.*;
	import common.*;
	import window.*;
	import window.whiteboard.WhiteboardContainer;
	import partition.*;
	import flash.text.*;
	import flash.net.*;
	import fl.controls.ComboBox;
	import fl.events.ListEvent;
	import flash.events.*;
	import common.AlertManager;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import com.adobe.images.*;
	import com.hurlant.util.Base64;
	
	// ヘッダー
	public class HeaderContentsLecturer extends HeaderContents {
		
		static public const FINISH_BTN_CLICKED:String = "FINISH_BTN_CLICKED";

		private const LABEL_BTN_CAPTURE_VIEW = Main.LANG.getParam( "画面キャプチャ一覧");
		static public const MSG_CAPTURE_OK:String = Main.LANG.getParam( "キャプチャ画像を保存しました");
		private const LABEL_MODE = Main.LANG.getParam( "画面モード:");
		private const LABEL_BTN_RESET = Main.LANG.getParam( "画面レイアウトをリセット");
		private const LABEL_BTN_SHARE_WEB = Main.LANG.getParam( "ウェブページ共有");
		
		private const PAD_BTN = 5;
		private var m_btnArr:Array;
		private var m_combo:ComboBox;

		private var m_settingBtn:DynamicTextBtn;// 環境設定ボタン
		private var m_qBtn:DynamicTextBtn;// アンケートボタン
		private var m_sendBtn:DynamicTextBtn;// ファイル送信ボタン
		private var m_rcvBtn:DynamicTextBtn;// 受信ファイルボタン
		private var m_webBtn:DynamicTextBtn;// ウェブページ共有ボタン
		private var m_listBtn:DynamicTextBtn;// 受講生一覧ボタン
		private var m_finishBtn:DynamicTextBtn;// 授業終了ボタン
		
		private var m_btnRec:RecBtn;
		private var m_btnRecLec:RecBtn;
		private var m_recWaitTimer:Timer = null;
		
		
		private var so_webBtn:SharedObject = null; // ウェブページ共有ボタンが講師によってクリックされた時刻
		
		//private var m_settingWin:ResizableWindow;// 環境設定ウィンドウ
		
		private var m_shutterSound:ShutterSound;
		
		public function HeaderContentsLecturer( w:Number, h:Number, btnRecLec) {
			
			super( w, h);
			//m_classTitle.appendText( "（講師用画面）");
			if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", m_classTitle.text);
			
			m_btnRecLec = btnRecLec; // 表示非表示を管理するため。実際の置き場はProVideoの中。
			
			m_shutterSound = new ShutterSound();
			
			m_btnArr = new Array();

			//----------------------------
			// 上の段のボタン、右端から
			//----------------------------
			var posi_x:Number = w;
			
			m_rightContainer.addChild( m_btnReconnect);
			posi_x -= m_btnReconnect.width;
			m_btnReconnect.x = posi_x;
			m_btnReconnect.y = PAD + 5;
			
			// FPSコントローラー
			var fpsController:FpsController = new FpsController();
			posi_x -= fpsController.width;
posi_x = w - fpsController.width - PAD;
			fpsController.x = posi_x;
			fpsController.y = PAD + 5;
			m_rightContainer.addChild( fpsController);
			
			// 画面キャプチャ一覧ボタン
			var capViewBtn:DynamicTextBtn = new DynamicTextBtn( LABEL_BTN_CAPTURE_VIEW);
			posi_x -= ( PAD + capViewBtn.width);
			capViewBtn.x = posi_x;
			capViewBtn.y = PAD;
			m_btnArr.push( capViewBtn);
			m_rightContainer.addChild( capViewBtn);
			capViewBtn.addEventListener( MouseEvent.CLICK, function( e:*) {
										if( ExternalInterface.available) ExternalInterface.call( "flashFunc_popupCaptureList", Main.CONF.CLASS_ID);});
			
			/*
			// 画面キャプチャ(カメラ)ボタン
			var capBtn:IconPartsBtn = new IconPartsBtn( new IconCameraAll(), 50, capViewBtn.height - 1);
			posi_x -= ( PAD_BTN + capBtn.width);
			capBtn.x = posi_x;
			capBtn.y = PAD;
			m_btnArr.push( capBtn);
			m_rightContainer.addChild( capBtn);
			capBtn.addEventListener( MouseEvent.CLICK, onCapture);
			*/
			

			// 画面レイアウトをリセット
			var resetBtn:DynamicTextBtn = new DynamicTextBtn( LABEL_BTN_RESET);
			posi_x -= ( PAD_BTN + resetBtn.width);
			resetBtn.x = posi_x;
			resetBtn.y = PAD;
			m_btnArr.push( resetBtn);
			m_rightContainer.addChild( resetBtn);
			resetBtn.addEventListener(MouseEvent.CLICK,
									  function ( e:*) { dispatchEvent(new Event( RESET_LAYOUT));});
			
			// 録画ボタン
			if( Main.CONF.getParam( 'REC_STATUS') != '2') {
				m_btnRec = new RecBtn();
				m_btnRec.initAsNormal( capViewBtn.height - 1);
			} else {
				m_btnRec = new RecBtnAuto();
				RecBtnAuto( m_btnRec).initAsAuto( capViewBtn.height - 1);
			}
			posi_x -= ( PAD_BTN + m_btnRec.width);
			m_btnRec.x = posi_x;
			m_btnRec.y = PAD;
			m_btnArr.push( m_btnRec);
			m_rightContainer.addChild( m_btnRec);
			// REC_STATUS:0 手動録画（録画していない状態から始まる）
			// REC_STATUS:1 手動録画（録画している状態から始まる）
			// REC_STATUS:2 自動録画（REC_STATUS_URLの返り値によって録画停止中／録画準備中／録画中を切り替える。ボタン操作不可）
			if( Main.CONF.getParam( 'REC_STATUS') == '2') {
				RecBtnAuto( m_btnRec).startWatchStatus();
			}
			if( Main.CONF.getParam( 'REC_STATUS') == '1') {
				m_btnRec.on();
			}
			if( Main.CONF.getParam( 'REC_STATUS') != '2') {
				m_recWaitTimer = new Timer( 70000, 1);
				m_recWaitTimer.addEventListener(TimerEvent.TIMER, onRecWaitTimer);
				function onRecWaitTimer( e:TimerEvent = null) {
					if( m_btnRec.isWaiting()) {
						Main.addPermanentLog( "全体録画：70秒待機しましたが、応答なしのため、録画準備失敗判定。", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
						if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", Main.LANG.getParam( "録画準備に失敗しました。再度お試しください。"));
						m_btnRec.off();
						Main.addPermanentLog( "全体録画：録画ボタンOFF", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
					}
				}
				m_btnRec.addEventListener( MouseEvent.CLICK, onRec);
				function onRec( e:MouseEvent) {
					
					if( m_btnRec.isOn()) {
						Main.addPermanentLog( "全体録画：録画終了ボタンクリック", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
						setTime( "rec-stop");
						m_btnRec.off();
						Main.addPermanentLog( "全体録画：録画ボタンOFF", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
					} else if( ! m_btnRec.isWaiting()) {
						Main.addPermanentLog( "全体録画：録画開始ボタンクリック", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
						m_btnRec.wait();						
						Main.addPermanentLog( "全体録画：録画ボタンWAIT", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
						
						var dateObj:Date = new Date();
						var cacheClear = "?dummy=" + dateObj.getMonth() + dateObj.getDate() + dateObj.getHours() + dateObj.getMinutes() + dateObj.getSeconds(); // 一秒ごとにキャッシュクリア
						//var cacheClear = "";
						var req:URLRequest = new URLRequest( Main.CONF.getParam( 'REC_URL') + cacheClear);
						
						req.method = URLRequestMethod.POST;
						var variables:URLVariables = new URLVariables();
						variables.class_id = Main.CONF.CLASS_ID;
						req.data = variables;
						
						var loader:URLLoader = new URLLoader();
						
						loader.addEventListener( Event.COMPLETE, function( e:Event) {
							var loader:URLLoader = URLLoader( e.target);
							if( String( loader.data) == "OK") {
								Main.addPermanentLog( "全体録画：録画開始", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
								m_btnRec.on();
								Main.addPermanentLog( "全体録画：録画ボタンON", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
							} else {
								Main.addPermanentLog( "全体録画：録画開始の失敗：" + loader.data, Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
								if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", loader.data);
								m_btnRec.off();
								Main.addPermanentLog( "全体録画：録画ボタンOFF", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
							}
							m_recWaitTimer.stop();
												
						});
						loader.addEventListener( IOErrorEvent.IO_ERROR,function( e:Event) {
												Main.addPermanentLog( "全体録画：IO_ERROR", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
												m_recWaitTimer.stop();
												onRecWaitTimer();
						});
						loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR,function( e:Event) {
												Main.addPermanentLog( "全体録画：SECURITY_ERROR", Main.CONF.SO_PERMANENT_LOG_KEY__RECORD);
												m_recWaitTimer.stop();
												onRecWaitTimer();
						});

						loader.load( req);
						m_recWaitTimer.reset();
						m_recWaitTimer.start();
					}
				}
			}
			m_btnRec.visible = m_btnRecLec.visible = false;
			
			
			//----------------------------
			// 下の段のボタン、左端から
			//----------------------------
			posi_x = PAD;
			
			// 環境設定ボタン
			m_settingBtn = new DynamicTextBtn( Layout.WINNAME_SETTING);
			m_settingBtn.x = posi_x;
			m_settingBtn.y = 40; // 適当
			posi_x += m_settingBtn.width + PAD_BTN;
			m_btnArr.push( m_settingBtn);
			m_settingBtn.addEventListener( MouseEvent.CLICK, function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.WINNAME_SETTING));});
			
			// アンケートボタン
			m_qBtn = new DynamicTextBtn( Layout.WINNAME_Q);
			m_qBtn.x = posi_x;
			m_qBtn.y = m_settingBtn.y;
			posi_x += m_qBtn.width + PAD_BTN;
			m_btnArr.push( m_qBtn);
			m_qBtn.addEventListener( MouseEvent.CLICK, function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.WINNAME_Q));});
			
			// ファイル送信ボタン
			m_sendBtn = new DynamicTextBtn( Layout.WINNAME_SEND);
			m_sendBtn.x = posi_x;
			m_sendBtn.y = m_settingBtn.y;
			posi_x += m_sendBtn.width + PAD_BTN;
			m_btnArr.push( m_sendBtn);
			m_sendBtn.addEventListener( MouseEvent.CLICK, function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.WINNAME_SEND));});
			
			// 受信ファイルボタン
			m_rcvBtn = new DynamicTextBtn( Layout.WINNAME_RECEIVE);
			m_rcvBtn.x = posi_x;
			m_rcvBtn.y = m_settingBtn.y;
			posi_x += m_rcvBtn.width + PAD_BTN;
			m_btnArr.push( m_rcvBtn);
			m_rcvBtn.addEventListener( MouseEvent.CLICK, function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.WINNAME_RECEIVE));});
			
			// ウェブページ共有ボタン
			m_webBtn = new DynamicTextBtn( LABEL_BTN_SHARE_WEB);
			m_webBtn.x = posi_x;
			m_webBtn.y = m_settingBtn.y;
			posi_x += m_webBtn.width + PAD_BTN;
			m_btnArr.push( m_webBtn);
			m_webBtn.addEventListener( MouseEvent.CLICK, onClickWebBtn);
			
			// 受講生一覧ボタン
			m_listBtn = new DynamicTextBtn( Layout.WINNAME_MEMBER);
			m_listBtn.x = posi_x;
			m_listBtn.y = m_settingBtn.y;
			posi_x += m_listBtn.width + PAD_BTN;
			m_btnArr.push( m_listBtn);
			m_listBtn.addEventListener( MouseEvent.CLICK, function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.WINNAME_MEMBER));});
			
			// 配置
			for each( var btn in m_btnArr) {
				if( ! m_rightContainer.contains( btn)) addChild( btn);
			}
			
			//----------------------------
			// 画面モードコンボボックス
			//----------------------------
			var modeText:TextField = TextField( addChild( new TextField()));
			modeText.autoSize = TextFieldAutoSize.LEFT;
			modeText.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 10, 0x333333);
			modeText.text = LABEL_MODE;
			modeText.x = posi_x + PAD_BTN;
			modeText.y = m_settingBtn.y + ( m_settingBtn.height - modeText.height) / 2;
			posi_x += modeText.width + PAD_BTN;
			
			m_combo = ComboBox( addChild( new ComboBox()));
			m_combo.x = posi_x;
			m_combo.y = m_settingBtn.y + ( m_settingBtn.height - m_combo.height) / 2;
			m_combo.addEventListener( Event.CHANGE, onModeChanged);
			m_combo.enabled = false;
			m_combo.width = 130;
			
			// WbSlideのonEnterFrame()のカーソル切り替え表示時に通常のカーソルがでるように
			//m_combo.addEventListener( MouseEvent.ROLL_OUT , onItemRollOut);
			//m_combo.addEventListener( MouseEvent.ROLL_OVER , onItemRollOver);
			//m_combo.addEventListener( ListEvent.ITEM_ROLL_OUT , onItemRollOut);
			//m_combo.addEventListener( ListEvent.ITEM_ROLL_OVER , onItemRollOver);
			//m_combo.addEventListener( Event.CLOSE , onItemRollOut);
			//m_combo.addEventListener( Event.OPEN , onItemRollOver);
			m_combo.dropdown.addEventListener( MouseEvent.ROLL_OUT , onItemRollOut);
			m_combo.dropdown.addEventListener( MouseEvent.ROLL_OVER , onItemRollOver);
			
			// 時計
			m_clock.addEventListener( Clock.CLASS_STARTED, onClassStarted);
			m_clock.addEventListener( Clock.CLASS_FINISHED, onClassFinished);
			m_clock.startWatchClassStartedOrFinished();
			m_clock.y = m_settingBtn.y + 3;
			m_clockAid.y = m_clock.y;
			
			// 授業終了ボタン
			m_finishBtn = DynamicTextBtn( addChild( new DynamicTextBtn( Main.LANG.getParam( "授業終了"))));
			m_finishBtn.x = w - m_finishBtn.width - 20;
			m_finishBtn.y = m_settingBtn.y;
			m_btnArr.push( m_finishBtn);
			
			
			m_clock.x = m_finishBtn.x - CLOCK_BAR_W - 30;
			m_clockAid.x = m_clock.x - m_clockAid.width - 25;

			
		}
		function onClassStarted( e:Event) {
			m_btnRec.visible = m_btnRecLec.visible = true;
			m_clock.removeEventListener( Clock.CLASS_STARTED, onClassStarted);
		}
		function onClassFinished( e:Event) {
			m_btnRec.visible = m_btnRecLec.visible = false;
			m_clock.removeEventListener( Clock.CLASS_FINISHED, onClassFinished);
		}
		override public function initSo( nc:NetConnection, so_here:SharedObject) {
			if( so_webBtn == null) so_webBtn = SharedObject.getRemote( Main.CONF.CLASS_ID + "so_webBtn", nc.uri, false);
			so_webBtn.connect( nc);
		}
		
		function onClickWebBtn( e:MouseEvent) {
			var url:String = '/live/teach_on_page?guid='+Main.CONF.CLASS_ID+'&uid='+Main.CONF.UID;
			navigateToURL( new URLRequest( url), '_blank');
			if( so_webBtn != null) {
				var dateObj:Date = new Date();
				so_webBtn.setProperty( "lastClickTime", dateObj.getTime());
			} else {
				errDialog( Main.LANG.getParam( "通信エラーにより、受講生にウェブページ共有ボタンのクリック要請アラートを表示できません"));
			}
		}
		function onItemRollOut( e:*) {
			WhiteboardContainer.CURSOR_BUSY = false;
			Main.DROP_OPENED = false;
		}
		function onItemRollOver( e:*) {
			WhiteboardContainer.CURSOR_BUSY = true;
			Main.DROP_OPENED = true;
		}
		
		public function removeAllComboItem() {
			// コンボボックスを空にする
			m_combo.removeAll();
//alertDialog( "removeAllComboItem");
		}
		
		public function addComboItem( modeName:String) {
			// 同じ名前が登録済みだったら追加しない
			for( var i = 0; i < m_combo.length; i++) {
				if( m_combo.getItemAt( i).label == modeName) return;
			}
			var item = { label: modeName, data:modeName };
			m_combo.addItem( item);
//alertDialog( modeName);
			//if( ! m_combo.selectedItem) m_combo.selectedItem = item;
			
			// ドロップダウンリストのテキストの長さに基づいて dropdownWidth プロパティを設定
			var maxLength:Number = 0;
			for (i = 0; i < m_combo.length; i++) {
				m_combo.selectedIndex = i;
				m_combo.drawNow();
				var currText:String = m_combo.text;
				var currWidth:Number = m_combo.textField.textWidth;
				maxLength = Math.max( currWidth, maxLength);
			}
			m_combo.dropdownWidth = maxLength + 30;
			
			//m_combo.dropdown.rowCount = m_combo.length < 10 ? m_combo.length : 10;
		}
		
		// コンボボックスの選択状況を強制的に変更。
		// so_layoutHashArrが読み込まれたときに、
		// so_layoutで指定されている表示画面モードとコンボボックスの選択状況が違っている場合に呼ばれる
		public function selectComboItem( modeName:String) : Boolean {
			for( var i = 0; i < m_combo.length; i++) {
				if( m_combo.getItemAt( i).label == modeName) {
					m_combo.selectedItem = m_combo.getItemAt( i);
					return true;
				}
			}
			return false; // 存在しないので選択できなかった
		}
		public function getSelectedMode():String {
//alertDialog( m_combo.selectedItem.label);
			return m_combo.selectedItem.label;
		}
		function onModeChanged( e:Event) {
			dispatchEvent( new Event( MODE_CHANGE));
		}
		
		// ステージの画面キャプチャ
		function onCapture( e:MouseEvent) {
			
//errDialog(String(stage) + " : " + String(stage.stageWidth) +","+ String(stage.stageHeight));
			var bmd :BitmapData = new BitmapData( stage.stageWidth, stage.stageHeight, false, 0xFFFFFF );
			try {
				bmd.draw( stage);
			} catch( e:Error) {
				errDialog( "Security Error:"+ Main.LANG.getParam( "ライブストリーミング映像はキャプチャできません。") + String( e.message));
				return;
			}
			m_shutterSound.play( 0, 1);
			var byteArray:ByteArray = PNGEncoder.encode( bmd);
			
			// Base64形式に変換
			var enc:String = Base64.encodeByteArray( byteArray);
//errDialog(enc);
			var urlVar:URLVariables = new URLVariables();
			urlVar.do_mode = "up-capture";
			urlVar.class_id = Main.CONF.CLASS_ID;
			urlVar.capture_target = "stage";
			urlVar.encoded_img = enc;// Base64画像セット
			
			// URLの設定
			var req:URLRequest = new URLRequest();
			req.method = URLRequestMethod.POST;
			req.data = urlVar;
			
			var path = Main.CONF.getParam( 'UPLOAD_URL');
			if( path) {
				req.url = path;
				var loader:URLLoader = new URLLoader();
				
				loader.load(req);

if( Main.DEBUG) navigateToURL( req, "_blank");

				loader.addEventListener( Event.COMPLETE, function(e:*){ errDialog( MSG_CAPTURE_OK);}); 
				loader.addEventListener( IOErrorEvent.IO_ERROR, function(e:*){ Main.addErrMsg( "IO_ERR:" + Main.LANG.getParam( "キャプチャ画像の保存失敗"));});
				loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function(e:*){ Main.addErrMsg(  "SECURITY_ERR:" + Main.LANG.getParam( "キャプチャ画像の保存失敗"));});

			} else {
				Main.addErrMsg( "HeaderContentsLecturer:onCapture():"+ Main.LANG.getParam( "UPLOAD_URLが指定されていないためキャプチャ画像を保存できません"));
			}
			bmd.dispose();
		}
		
		function setTime( mode:String) {
			var path:String = Main.CONF.getParam( "SETTIME_URL");
			if( path == LoadConf.NOTFOUND) {
				Main.addErrMsg( Main.LANG.getReplacedSentence( "%sが設定されていないためDBに保存できませんでした", "SETTIME_URL"));
				return;
			}
			var req:URLRequest = new URLRequest( path);
			req.method = URLRequestMethod.POST;
			var variables:URLVariables = new URLVariables();
			variables.mode = mode;
			variables.class_id = Main.CONF.CLASS_ID;
			variables.uid = Main.CONF.UID;
			req.data = variables;
			
//if( Main.DEBUG) navigateToURL( req, "_blank");
			
			sendToURL( req);
		}
		
		function errDialog( msg:String) {
			if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", msg);
		}
				
		override public function setEnabled( b:Boolean):void {
			super.setEnabled( b);
			for each( var btn in m_btnArr) {
				btn.setEnabled( b);
			}
			m_combo.enabled = b;
			
			if( Main.CONF.getParam( 'REC_STATUS') == '2') m_btnRec.setEnabled( false);
			
			if( b) {
				m_finishBtn.addEventListener( MouseEvent.CLICK, onClickFinish);
			} else {
				m_finishBtn.removeEventListener( MouseEvent.CLICK, onClickFinish);
			}
		}
		function onClickFinish( e:MouseEvent) {
			dispatchEvent( new Event( FINISH_BTN_CLICKED));
		}
		override public function setViewWidth( w:Number, debug:String = ""):void {
			super.setViewWidth( w);
			if( w < MIN_W) m_rightContainer.x = 0;
			else m_rightContainer.x = w - MIN_W;
			
			m_finishBtn.x = w - m_finishBtn.width - 20;
			m_clock.x = m_finishBtn.x - CLOCK_BAR_W - 30;
			m_clockAid.x = m_clock.x - m_clockAid.width - 25;
		}
		override public function setViewHeight( h:Number):void {
			super.setViewHeight( h);
		}
		
				
	}
}

