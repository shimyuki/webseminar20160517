package window.setting {
	import flash.display.*;
	import flash.geom.*;
	import common.*;
	import window.*;
	import flash.net.*;
	import flash.text.*;
	import flash.events.*;
	import partition.Layout;
	import window.setting.*;
	import common.AlertManager;
	import com.hurlant.crypto.prng.ARC4;
	import window.chat.ChatContainer;
	
	// 個別メンバーの環境設定
	public class MemberSettingContentsCon extends ResizableContainer {
		private const TITLE_DRAWER_00 = Main.LANG.getParam( "画像");
		private const TITLE_DRAWER_01 = Main.LANG.getParam( "動画配信／権限の設定");
		private const TITLE_DRAWER_02 = Main.LANG.getParam( "個別チャット");
		private const TITLE_DRAWER_03 = Main.LANG.getParam( "アクションログ");
		private const TITLE_DRAWER_04 = "";
		private const LABEL_CAMERA = Main.LANG.getParam( "映像");
		private const LABEL_MIC = Main.LANG.getParam( "映像");
		private const LABEL_WB = Main.LANG.getParam( "ホワイトボード書き込み権限");
		private const LABEL_DOC = Main.LANG.getParam( "資料の自由閲覧権限");
		private const LABEL_APPLY = Main.LANG.getParam( "適用する");
		private const MSG_APPLYED = Main.LANG.getParam( "適用しました");
		private const MSG_SAVED = Main.LANG.getParam( "画面モード一覧に追加しました");
		
		private var m_drawer01:Drawer;
		private var m_drawer02:Drawer;
		private var m_drawer03:Drawer;
		private var m_drawer04:Drawer;
		
		private var m_container:Sprite;
		private var m_containerMask:Sprite;
		private var m_scroll:SimpleScrollBar;
		private const PAD = 8;
		private const INIT_Y = 2;
		private var m_preW:Number = 0;
		private var m_preH:Number = 0;
		
		private var m_currentMSC:MemberSettingContents = null;
		
		private var m_stuStreamCompo:StreamComponents; // 動画配信設定コンポーネントセット
		private var m_stuAuthorityCompo:AuthorityComponents; // 権限設定コンポーネントセット
		private var m_stuReceiveCompo:ReceiveComponents; // 講師映像の受信設定コンポーネントセット
		private var m_btnDrawer02:DynamicTextBtn;
		private var m_fullVideo:FullVideo;
		private var m_chat:MemberChat;
		private var m_drawerArr:Array;
		
		private var m_chatOpen:Boolean = false;
						
		public function MemberSettingContentsCon( w:Number, h:Number) {
						
			super( w, h, 0, 0); // min_w は後で設定し直すのでとりあえずゼロ
			
			// 表示コンテナ
			m_container = Sprite( addChild( new Sprite()));
			m_container.x = PAD;
			m_container.y = INIT_Y;
			
			// 表示コンテナのマスク
			m_containerMask = Sprite( addChild( new Sprite()));
			m_containerMask.graphics.beginFill(0);
			m_containerMask.graphics.drawRect( 0, 0, 1, 1);
			m_containerMask.x = m_container.x;
			m_containerMask.y = m_container.y;
			m_container.mask = m_containerMask;
			
			// 表示コンテナのスクロールバー
			m_scroll = SimpleScrollBar( addChild( new SimpleScrollBar()));
			m_scroll.y = INIT_Y;
			m_scroll.setSize( m_scroll.width, 200);
			m_scroll.setScrollTarget( m_container);
			m_scroll.scrollMask = m_containerMask;
			
			m_drawerArr = new Array();
			//----------------------------------
			// Drawer01：映像表示
			//----------------------------------
			// 中身の生成
			m_fullVideo = new FullVideo();
			// 配置
			m_drawer01 = new Drawer( TITLE_DRAWER_00, m_fullVideo, FullVideo.H + 10);
			m_container.addChild( m_drawer01);
			m_drawerArr.push( m_drawer01);
			
			//----------------------------------
			// Drawer02：動画配信／権限の設定
			//----------------------------------
			// 中身の生成
			m_stuStreamCompo = new StreamComponents();// コンポーネントセット
			m_stuStreamCompo.addEventListener( StreamComponents.REPUBLISH_BTN_CLICKED, redispatch);
			m_stuStreamCompo.addEventListener( StreamComponents.EVICTED_BTN_CLICKED, redispatch);
			m_stuAuthorityCompo = new AuthorityComponents();// コンポーネントセット
			m_btnDrawer02 = new DynamicTextBtn( LABEL_APPLY); // 適用するボタン
			m_btnDrawer02.setEnabled( true);
			var drawerCon01 = new Sprite(); // 中身のコンテナ
			drawerCon01.addChild( m_stuStreamCompo);
			m_stuAuthorityCompo.x = 30;
			m_stuAuthorityCompo.y = StreamComponents.H + 10;
			drawerCon01.addChild( m_stuAuthorityCompo);
			
			m_stuReceiveCompo = new ReceiveComponents();
			m_stuReceiveCompo.x = 30;
			m_stuReceiveCompo.y = m_stuAuthorityCompo.y + AuthorityComponents.H + 10;
			drawerCon01.addChild( m_stuReceiveCompo);
			m_btnDrawer02.x = 370;
			m_btnDrawer02.y = m_stuReceiveCompo.y + m_stuReceiveCompo.height + 10;
			m_btnDrawer02.addEventListener( MouseEvent.CLICK, save01);
			drawerCon01.addChild( m_btnDrawer02);
			// 配置
			m_drawer02 = new Drawer( TITLE_DRAWER_01, drawerCon01, StreamComponents.H + AuthorityComponents.H + m_stuReceiveCompo.height + m_btnDrawer02.height + 40);
			m_drawer02.y = m_drawer01.y + m_drawer01.getViewHeight();
			m_container.addChild( m_drawer02);
			m_drawerArr.push( m_drawer02);
			
			//----------------------------------
			// drawer03：個別チャット
			//----------------------------------
			// 個別チャット
			m_chat = new MemberChat();
			// 配置
			m_drawer03 = new Drawer( TITLE_DRAWER_02, m_chat, MemberChat.H + 10);
			m_container.addChild( m_drawer03);
			m_drawerArr.push( m_drawer03);
			
			//----------------------------------
			// drawer04：個別アクションログ
			//----------------------------------
			// 配置
			m_drawer04 = new Drawer( TITLE_DRAWER_03, null, MemberLog.H + 10);
			m_container.addChild( m_drawer04);
			m_drawerArr.push( m_drawer04);
			
			m_drawer01.addEventListener( Drawer.SIZE_CHANGED, onDrawerSizeChanged);
			m_drawer02.addEventListener( Drawer.SIZE_CHANGED, onDrawerSizeChanged);
			m_drawer03.addEventListener( Drawer.SIZE_CHANGED, onDrawerSizeChanged);
			m_drawer04.addEventListener( Drawer.SIZE_CHANGED, onDrawerSizeChanged);
			
			m_drawer01.close();
			m_drawer02.close();
			m_drawer03.close();
			m_drawer04.close();
			
			addEventListener( Event.ADDED_TO_STAGE, onAdded2Stage);
		}
					
		function onAdded2Stage( e:Event) {
			// 現在の状態に合わせる（編集途中の値をリセット）
			var hash:Object = Main.CONF.getMemberDataHash( m_currentMSC.uid);
			if( hash != null) {
				m_stuStreamCompo.init( hash); // 動画配信設定状態
				m_stuAuthorityCompo.init( hash);// 権限設定状態
			}
						
			m_drawer01.close();
			m_drawer02.close();
			m_drawer03.close();
			m_drawer04.close();
			
			// チャットを開いた状態にする
			if( m_chatOpen) {
				m_drawer03.open();
				m_chatOpen = false;
			}
			
			scrollup();
			
		}

		function redispatch( e) {
			dispatchEvent( e);// Mainに知らせる
		}
		public function setContents( msc:MemberSettingContents) {
			if( m_currentMSC != null) {
				m_currentMSC.removeEventListener("m_buffer_time changed", onChangeBufferTime);
			}
			
			m_currentMSC = msc;
			m_currentMSC.addEventListener("m_buffer_time changed", onChangeBufferTime);
			
			m_fullVideo.init( m_currentMSC.uid);
			
			//m_drawer03.setContents( m_currentMSC.getMemberChat());
			m_chat.setChatCon( m_currentMSC.getChatContainer());
			m_drawer04.setContents( m_currentMSC.getMemberLog());
			
			setBufferTime( m_currentMSC.getBufferTime());
						
			scrollup();
		
		}
		function onChangeBufferTime( e:Event) {
			setBufferTime( m_currentMSC.getBufferTime());
		}
		public function getUid() : String { return m_currentMSC.uid;}
				
		// 次回ADDED_TO_STAGEされたときにチャットを開いた状態にするためのフラグをたてる
		public function openChat() {
			m_chatOpen = true;
		}
		function scrollup( e:Event = null) {
			m_container.y = INIT_Y;
			m_scroll.setBarYMin();
			m_scroll.update();
		}
		
		function onDrawerSizeChanged( e:Event) {
			for( var i = 1; i < m_drawerArr.length; i++) {
				m_drawerArr[i].y = m_drawerArr[i-1].y + m_drawerArr[i-1].getViewHeight();
			}
			m_scroll.update();
		}
		
		// Drawer02：動画配信／権限の設定の適用するボタンクリック
		// ここではSharedObjectの変更を行う。
		function save01( e:MouseEvent) {
			
			// 入力チェック
			var errMsg:String = m_stuStreamCompo.checkInputData();
			if( errMsg != "") {
				alertDialog( errMsg);
				return;
			}
			// 入力チェック
			errMsg = m_stuAuthorityCompo.checkInputData();
			if( errMsg != "") {
				alertDialog( errMsg);
				return;
			}
			
			// 入力チェック
			errMsg = m_stuReceiveCompo.checkInputData();
			if( errMsg != "") {
				msgDialog( errMsg);
				return;
			}
			// 受信設定に関しては、Mainからso変更してもらう。
			m_currentMSC.setBufferTime( getBufferTime(), false);
			dispatchEvent( new Event( SettingContents.STU_RECEIVE_SETTING_CHANGED));

			// まずはCONFのメンバーの状態を更新
			Main.CONF.apply_member( m_currentMSC.uid, m_stuStreamCompo.getHash());
			Main.CONF.apply_member( m_currentMSC.uid, m_stuAuthorityCompo.getHash());
			
			// CONFから一番最新のデータを取得
			var hash:Object = Main.CONF.getMemberDataHash( m_currentMSC.uid);
			
			// 適用実行
			if(! Main.CONF.resetSo_member( m_currentMSC.uid, hash)) {
				alertDialog( Main.LANG.getParam( "通信エラーにより、変更を反映できませんでした"));
				return;
			}
			msgDialog( MSG_APPLYED);
			
		}
		public function getBufferTime() : Number {
			return m_stuReceiveCompo.getBufferTime();
		}
		
		function setBufferTime( buffer_time: Number) {
			m_stuReceiveCompo.setBufferTime( buffer_time);
		}
				
		override public function setViewWidth( w:Number, debug:String = ""):void {
			if( w < MIN_W) w = MIN_W;
			super.setViewWidth( w);
			
			m_containerMask.width = w - m_scroll.width;
			m_scroll.x = w - m_scroll.width;
			
			for each( var drawer:Drawer in m_drawerArr) {
				drawer.setViewWidth( w - m_scroll.width - PAD);
			}
			
			m_fullVideo.setViewWidth( w - m_scroll.width - PAD);
			m_chat.setViewWidth( w - m_scroll.width - PAD * 2);
			if( m_currentMSC) m_currentMSC.getMemberLog().setViewWidth( w - m_scroll.width - PAD * 2);
			
			// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、
			// サイズがかわらないのであればここでリターン
			if( w != m_preW ) {
				m_preW = w;
				m_scroll.update();
			}
		
			//m_text.width = w - m_scroll.width - PAD * 2;
		}
		override public function setViewHeight( h:Number):void {
			super.setViewHeight( h);
			m_containerMask.height = h - INIT_Y;
			// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、
			// サイズがかわらないのであればここでリターン
			if( h != m_preH ) {
				m_preH = h;
				m_scroll.setSize( m_scroll.width, h - INIT_Y - 15);
				m_scroll.update();
			}
		}
		
		function alertDialog( str:String) {
			Main.addErrMsg( "MemberSettingContents:" + str);
		}
		function msgDialog( str) {
			AlertManager.createAlert( this , str);
		}
	}
}