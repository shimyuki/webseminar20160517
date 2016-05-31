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
	import fl.motion.easing.Back;
	
	// 個別メンバーの環境設定のデータ
	public class MemberSettingContents extends EventDispatcher {
		
		private var m_nc:NetConnection = null;
		
		public var uid:String;
		
		//private var m_chat:MemberChat;
		private var m_chatCon:ChatContainer;
		private var m_log:MemberLog;
		private var m_buffer_time:Number = 0;
		
		private var m_inited:Boolean = false;
						
		public function MemberSettingContents( uid:String) {
			
			this.uid = uid;
			
			// 個別チャット
			//m_chat = new MemberChat( uid);
			m_chatCon = new ChatContainer( 100, 100, "chat", uid);
			//m_chatCon.setViewHeight( H - PAD * 2);

			
			// 個別アクションログ
			m_log = new MemberLog( uid);
		}
		/*public function getMemberChat():MemberChat {
			return m_chat;
		}*/
		public function getMemberLog():MemberLog {
			return m_log;
		}
		public function getBufferTime() : Number {
			return m_buffer_time;
		}
		// MainのonSyncSoRcvBufferTime()から呼ばれる
		public function setBufferTime( buffer_time: Number, dispatch:Boolean = true) {
			m_buffer_time = buffer_time;
			if( dispatch)dispatchEvent( new Event( "m_buffer_time changed")); // MemberSettingContentsConに知らせる（表示中だったら）
		}
		
		// クイック一覧の個別チャットのポップアップ用に、ResizableChatWindowから呼ばれる
		// MemberSettingContentsConからsetContents()で呼ばれる
		public function getChatContainer() : ChatContainer {
			return m_chatCon;
		}
		
		
		public function initSo( nc:NetConnection) {
			m_nc = nc;
			m_chatCon.initSo( Main.CONF.SO_NAME_CHAT_STU, m_nc);
			m_inited = true;
		}
		public function setSoLog( so:SharedObject) {
			m_log.setSo( so);
		}
		// MainからSharedObjectの値変更イベントから呼ばれる
		public function addHtmlText( htmlText:String) {
			m_log.addHtmlText( htmlText);
		}
		function initSoChat_private( e:Event = null) {
			m_chatCon.removeEventListener( Event.ADDED_TO_STAGE, initSoChat_private);
			//m_fullVideo.receiveNetStream( m_nc);
			m_chatCon.initSo( Main.CONF.SO_NAME_CHAT_STU, m_nc);
			m_inited = true;
		}
		public function initSoChatIfMada():Boolean {
			var inited:Boolean = m_inited;
			if( !m_inited) initSoChat_private();
			return inited;
		}
		
		// ライブステータスを反映させる用。この関数自体はMainで呼ばれ、ライブステータスに渡される
		public function getLogCon() : MemberLog { return m_log;}
		public function getUid() : String { return uid;}
		
		public function setEnabled( b:Boolean):void {
			m_chatCon.setEnabled( b);
		}
		
	}
}