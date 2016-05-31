package window.whiteboard {
	import flash.display.*;
	import flash.geom.*;
	import common.*;
	import window.*;
	import window.header.HeaderContents;
	import window.header.HeaderContentsLecturer;
	import window.whiteboard.toolchip.*;
	import window.whiteboard.slide.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import fl.controls.Slider;
	import flash.media.Sound;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import com.adobe.images.*;
	import com.hurlant.util.Base64;
	import com.adobe.protocols.dict.events.MatchEvent;
	import window.whiteboard.imgdoc.Doc;
	import flash.errors.ScriptTimeoutError;
	import common.AlertManager;
	
	// ホワイトボード
	public class Whiteboard extends ResizableContainer {
		
		private const ERR_MSG_SAVE_PNG = Main.LANG.getParam( "警告：保存した画像（PNG画像）に拡張子が指定されていませんでした。画像が見られない場合はファイルに拡張子.pngを設定してください。");
		static public const SLIDE_NOT_FOUND:String = "SLIDE_NOT_FOUND";
		//static private const BGTYPE_IMG:String = WhiteboardContainer.BGTYPE_IMG;
		//static private const BGTYPE_CAMERA:String = WhiteboardContainer.BGTYPE_CAMERA;
		//static private const BGTYPE_PLAIN:String = WhiteboardContainer.BGTYPE_PLAIN;
		static public var POSITIONING:Object = new Object(); //{ BGTYPE_CAMERA: "center", BGTYPE_IMG: "lefttop", BGTYPE_PLAIN: "lefttop"};
		protected var m_container:Sprite;
		protected var m_containerMask:Sprite;
		private var m_imgSlideArr:Array;
		private var m_camSlideArr:Array;
		private var m_plainSlide:PlainWbSlide;
		protected var m_targetSlide:WbSlide = null;
		protected var m_scrollY:WbScrollBar;
		protected var m_scrollX:WbScrollBarH;
		private var m_preW:Number = 0;
		private var m_preH:Number = 0;
		private var m_shutterSound:ShutterSound = null; // シャッター音
		private const MSG_CAPTURE_OK = HeaderContentsLecturer.MSG_CAPTURE_OK;
		private var m_nc:NetConnection;
		protected var m_sync:Boolean = false; // 同期モードか否か
		
		private var m_timer_changeSlide:Timer;
		private var m_bgtype_now = null;
		private var m_param_now = null;
//private var m_1st:Boolean = true;

		public function Whiteboard() {
			
			setPositioning();
			
			super( 10, 10, 0, 0);
			
			// スライド表示コンテナ
			m_container = Sprite( addChild( new Sprite()));
			m_container.y = 0;
			
			// スライド表示コンテナのマスク
			m_containerMask = Sprite( addChild( new Sprite()));
			m_containerMask.graphics.beginFill(0);
			m_containerMask.graphics.drawRect( 0, 0, 1, 1);
			m_containerMask.y = m_container.y;
			m_container.mask = m_containerMask;
			
			// スライドの配列
			m_imgSlideArr = new Array(); // 画像スライド格納用
			m_camSlideArr = new Array(); // カメラ映像スライド格納用
			
			m_plainSlide = new PlainWbSlide( WhiteboardContainer.BGTYPE_PLAIN, 0xffffff);// 無地スライド
			addCamSlide( LoadConf.DEFAULT_CAM_ID, null);
			
			// スライド表示コンテナのスクロールバー
			m_scrollY = addChild( new WbScrollBar()) as WbScrollBar;
			m_scrollY.y = 0;
			m_scrollY.setSize( m_scrollY.width, 200);
			m_scrollY.setScrollTarget( m_container);
			m_scrollY.scrollMask = m_containerMask;
			
			m_scrollX = addChild( new WbScrollBarH()) as WbScrollBarH;
			m_scrollX.x = 0;
			m_scrollX.setSize( 200, m_scrollX.height);
			m_scrollX.setScrollTarget( m_container);
			m_scrollX.scrollMask = m_containerMask;
			
			// 権限が有ればスクロールの変更を監視、dispatchして他ユーザーに同期させる
			m_scrollY.addEventListener( "updated", function( e:*){
									   if( WhiteboardContainer.WB_AUTHORIZED)
									   		dispatchEvent( new Event( "scroll changed"));
										setSlideViewArea();
									});			
			m_scrollX.addEventListener( "updated", function( e:*){
									   if( WhiteboardContainer.WB_AUTHORIZED)
									   		dispatchEvent( new Event( "scrollH changed"));
											setSlideViewArea();
									});
			
			
			m_timer_changeSlide = new Timer( 1000, 5);
			m_timer_changeSlide.addEventListener( TimerEvent.TIMER, onTimer);
			m_timer_changeSlide.addEventListener( TimerEvent.TIMER_COMPLETE, onTimerComplete);
		}
		function onTimer( e:TimerEvent) {
			if( m_bgtype_now != null && m_param_now != null) changeSlide( m_bgtype_now, m_param_now);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "Whiteboard:onTimer:changeSlide");
		}
		function onTimerComplete( e:TimerEvent) {
			var errMsg = "";
			if( Main.CONF.isPro( Main.CONF.UID) || Main.CONF.UID == Main.CONF.getWhiteboardUID()) 
				errMsg = Main.LANG.getParam( "他の参加者画面と不整合が生じている恐れがありますので、ページを再読み込みするか、資料を選択し直してください。");
			else errMsg = Main.LANG.getParam( "他の参加者画面と不整合が生じている恐れがありますので、ページを再読み込みするか、講師に資料を選択し直すよう、ご連絡ください。");
			Main.addErrMsg( errMsg);
		}
		public function reloadSlide() {
			if( ! m_timer_changeSlide.running) m_timer_changeSlide.reset();
			m_timer_changeSlide.start();
		}
		
		protected function setPositioning() {
			POSITIONING[ WhiteboardContainer.BGTYPE_CAMERA] = "center";
			POSITIONING[ WhiteboardContainer.BGTYPE_IMG] = "lefttop";
			POSITIONING[ WhiteboardContainer.BGTYPE_PLAIN] = "lefttop";
		}
				
		public function getImgSlideArr() : Array { return m_imgSlideArr;}
		public function getCamSlideArr() : Array { return m_camSlideArr;}
		
		// ツールチップボタンクリック時と
		// WhiteboardContainerのso_wbNow変更時に呼ばれる
		public function setToolModeDetail( toolModeDetail:ToolModeDetail) : void {
			if( m_targetSlide != null) {
				m_targetSlide.setToolModeDetail( toolModeDetail);
			}
		}
		
		// ImgdocContainerに資料サムネイルが追加されたとき、WhiteboardContainerからonDocAdded()より呼ばれる
		public function addImgSlide( doc:Doc) {
			var slide:ImgWbSlide = new ImgWbSlide( WhiteboardContainer.BGTYPE_IMG, doc);
			slide.name = doc.getId();
			m_imgSlideArr.push( slide);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Whiteboard:addImgSlide():"+ doc.getName() + " / " + doc.getId());
		}
		
		// ImgdocContainerから資料サムネイルが削除されたとき、WhiteboardContainerからonThuRemoved()より呼ばれる
		// サムネイル一覧から削除されれば、もう表に出ることは無いから、
		// ここでわざわざ削除しなくてもいいのかもしれないけど…
		public function removeImgSlide( docid:String):void {
			for( var i:uint = 0; i < m_imgSlideArr.length; i++) {
				var imgSlide:ImgWbSlide = ImgWbSlide( m_imgSlideArr[i]);
				if( imgSlide.getDocId() == docid) {
					m_imgSlideArr.splice( i, 1);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Whiteboard:removeImgSlide()");
					break;
				}
			}
		}
		
		// スライドが削除(so_slideListから削除)されたときに、m_imgSlideArrと整合性をとるため、
		// WhiteboardContainerから呼ばれる
		public function removeImgSlide_ifMissMatch( exist_slideList:Array) : Array {
			var removedDocIds:Array = new Array();
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Whiteboard:removeImgSlide_ifMissMatch()");
			
			var imgSlide:ImgWbSlide;
			if( !exist_slideList || exist_slideList.length == 0) {
				while( m_imgSlideArr.length) {
					imgSlide = m_imgSlideArr.pop();
					//imgSlide.dispose();
				}
			} else {
				for( var i:uint = 0; i < m_imgSlideArr.length; i++) {
					imgSlide = ImgWbSlide( m_imgSlideArr[i]);
					var exist:Boolean = false;
					for each( var obj_slideList in exist_slideList) {
						if( obj_slideList.param == imgSlide.getDocId()) {
							exist = true;
							break;
						}
					}
					if( ! exist) {
						m_imgSlideArr.splice( i, 1);
						i--;
						removedDocIds.push( imgSlide.getDocId());
					}
				}
			}
			return removedDocIds;
		}
		
		function addCamSlide( cameraid:String, receive_ns_pro) {
//alertDialog( "addCamSlide:" + String( receive_ns_pro));
			var slide:CamWbSlide = new CamWbSlide( WhiteboardContainer.BGTYPE_CAMERA, cameraid);
			if( receive_ns_pro != null) slide.setNs( receive_ns_pro);
			slide.name = cameraid;
			m_camSlideArr.push( slide);
		}
		
		// MainからWhiteboardContainer経由で、ネットコネクションが切れたときに呼ばれる。
		public function resetNetStream() {
			for( var i:uint = 0; i < m_camSlideArr.length; i++) {
				var slide:CamWbSlide = CamWbSlide( m_camSlideArr[i]);
				slide.setNs( null);
			}
		}
		
		// Main()からホワイトボードユーザの参加／退席時にWhiteboardContainer経由で呼ばれる
		// receive_ns_proには講師若しくはホワイトボードユーザ若しくはNULLのネットストリームが入る
		// receive_ns_proがNULLの場合は、自分自身（非生徒）の映像が背景になる
		public function setCamSlideNs( cameraid:String, receive_ns_pro) {
//Main.addDebugMsg( "wb:setCamSlideNs:" + String( receive_ns_pro));
			for( var i:uint = 0; i < m_camSlideArr.length; i++) {
				var slide:CamWbSlide = CamWbSlide( m_camSlideArr[i]);
				if( slide.name == cameraid) {
					slide.setNs( receive_ns_pro);
				}
			}
		}
		
		/*
		public function setCamSlideSo( so_wb) {
			for( var i:uint = 0; i < m_camSlideArr.length; i++) {
				var slide:CamWbSlide = CamWbSlide( m_camSlideArr[i]);
				slide.setSo( so_wb);
			}
		}*/
		public function setSoWb( so_wb:SharedObject) {
			for( var i:uint = 0; i < m_camSlideArr.length; i++) {
				var slide:CamWbSlide = CamWbSlide( m_camSlideArr[i]);				
				slide.setSoWb( so_wb);
			}
		}
		public function setWbVideo( wbVideo) {
			for( var i:uint = 0; i < m_camSlideArr.length; i++) {
				var slide:CamWbSlide = CamWbSlide( m_camSlideArr[i]);				
				slide.setWbVideo( wbVideo);
			}
		}
		
		// WhiteboardContainerから
		public function getCurrentSlide() {
			return m_targetSlide;
		}
		// WhiteboardContainerから
		public function setNc( nc:NetConnection) {
			m_nc = nc;
		}
						
		function hideSlide() {
			if( m_targetSlide != null) {
				m_targetSlide.removeEventListener( WbSlide.BG_COMPLETE, onComplete);
				m_targetSlide.removeEventListener( WbSlide.CHANGE_SIZE, onChangeWbSlideSize);
				m_targetSlide.removeEventListener( WbSlide.CHANGE_PP, onChangeWbSlidePP);
				m_targetSlide.removeEventListener( WbSlide.CHANGE_PP_LOCAL, reDispatch);
				//m_targetSlide.removeEventListener( WbSlide.REMOVED_PP, onRemovedWbSlidePP);
				m_targetSlide.removeEventListener( WbSlide.CHANGE_SIZE_BY_COMBO, onChangeWbSlideSize_byCombo);
				m_targetSlide.removeEventListener( PaintPartsEvent.ADDED, reDispatch_paintParts);
				m_targetSlide.removeEventListener( PaintPartsEvent.REMOVED, reDispatch_paintParts);
				m_targetSlide.removeEventListener( PaintPartsEvent.CHANGED, reDispatch_paintParts);
				m_targetSlide.removeEventListener( PaintPartsEvent.MULTI_CHANGE, reDispatch_paintParts);
				m_targetSlide.removeEventListener( TextPaintPartsEvent.START_CHANGE, reDispatch_textPaintParts);
				//m_targetSlide.removeEventListener( PaintParts.PP_REMOVED, onPpRemoved);
				m_targetSlide.unsetBg();
				if( m_container.contains( m_targetSlide)) {
					m_targetSlide.setParentPosi( m_container.x, m_container.y);
					m_container.removeChild( m_targetSlide);
				}
				m_targetSlide = null;
			}
		}
		
		// WhiteboardContainerからso_wbNowの値変更時に呼ばれる
		public function changeSlide( bgtype:String, param) {

//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "Whiteboard:changeSlide():start:" + bgtype +" "+ Math.random());
			m_bgtype_now = bgtype;
			m_param_now = param;
			
			var slide;
			switch( bgtype) {
				case WhiteboardContainer.BGTYPE_IMG :
					if( m_targetSlide != null && m_targetSlide.name == param) break; // 変更無し
					else hideSlide();
//Main.addDebugMsg( "Whiteboard changeSlide: m_imgSlideArr.length:["+ m_imgSlideArr.length + "]");					
			
					// 画像スライド配列から該当スライドを探して表示
					for each( slide in m_imgSlideArr) {
//Main.addDebugMsg( "Whiteboard changeSlide: ["+ slide.name +" ＜-＞ "+ param + "]");					
						if( slide.name == param) {
							m_targetSlide = slide;
							break;
						}
					}

					if( m_targetSlide != null) {
						
						if( m_timer_changeSlide.running) m_timer_changeSlide.stop();
						
						m_container.addChild( m_targetSlide);
						m_targetSlide.addEventListener( WbSlide.BG_COMPLETE, onComplete);
						m_targetSlide.setBg();
Main.addDebugMsg( "Whiteboard changeSlide: 該当スライド["+ m_targetSlide.name + "]セットOK");					
												
					} else {
						// 該当スライド無し
//Main.addDebugMsg( "Whiteboard changeSlide: 該当スライド["+ param + "]がみつからないので、スライドリストを再読み込みします");					
						
						dispatchEvent( new Event( SLIDE_NOT_FOUND));
						/*
						// スリープ後、再読み込み
						if( ! m_timer_changeSlide.running) m_timer_changeSlide.reset();
						m_timer_changeSlide.start();
						*/
						break;
					}
					break;
				case WhiteboardContainer.BGTYPE_CAMERA :
					if( m_targetSlide != null && m_targetSlide.name == param) break; // 変更無し
					else hideSlide();
					
					if( m_timer_changeSlide.running) m_timer_changeSlide.stop();
					
					// カメラ映像スライド配列から該当スライドを探して表示
					for each( slide in m_camSlideArr) {
						if( slide.name == param) {
							m_targetSlide = slide;
							break;
						}
					}
					if( m_targetSlide != null) {
						
						m_container.addChild( m_targetSlide);
//ExternalInterface.call( "flashFunc_alert", "Whiteboard:changeSlide(): onCompleteをまつだけ");
						m_targetSlide.addEventListener( WbSlide.BG_COMPLETE, onComplete);
						m_targetSlide.setBg();
					} else {
						// 該当スライド無し
					}
					break;
				default :
					if( m_targetSlide != null && m_targetSlide == m_plainSlide) break; // 変更無し
					else hideSlide();
					
					if( m_timer_changeSlide.running) m_timer_changeSlide.stop();
					
					// 無地スライドの表示
					m_targetSlide = m_plainSlide;
					m_container.addChild( m_targetSlide);
					m_targetSlide.addEventListener( WbSlide.BG_COMPLETE, onComplete);
					m_targetSlide.setBg();
					break;
				
			}
			
			if( m_targetSlide != null) {
				m_targetSlide.initSo( m_nc);
				m_targetSlide.setAuthority( WhiteboardContainer.WB_AUTHORIZED);
				m_targetSlide.addEventListener( WbSlide.CHANGE_SIZE, onChangeWbSlideSize);
				m_targetSlide.addEventListener( WbSlide.CHANGE_PP, onChangeWbSlidePP);
				m_targetSlide.addEventListener( WbSlide.CHANGE_PP_LOCAL, reDispatch);
				//m_targetSlide.addEventListener( WbSlide.REMOVED_PP, onRemovedWbSlidePP);
				m_targetSlide.addEventListener( WbSlide.CHANGE_SIZE_BY_COMBO, onChangeWbSlideSize_byCombo);
				m_targetSlide.addEventListener( PaintPartsEvent.ADDED, reDispatch_paintParts);
				m_targetSlide.addEventListener( PaintPartsEvent.REMOVED, reDispatch_paintParts);
				m_targetSlide.addEventListener( PaintPartsEvent.CHANGED, reDispatch_paintParts);
				m_targetSlide.addEventListener( PaintPartsEvent.MULTI_CHANGE, reDispatch_paintParts);
				m_targetSlide.addEventListener( TextPaintPartsEvent.START_CHANGE, reDispatch_textPaintParts);
				
				onChangeWbSlidePP();
				
			}
			setSlideViewArea();
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "Whiteboard:changeSlide():end:" + bgtype +" "+ rand);			
		}
		
		function wait( count:uint ):void{
			var start:uint = getTimer();
			while( getTimer() - start < count){
			}
		}
		
		// LiveStatusManagerからWbCon経由で呼ばれる。
		public function changeJoinStatus( uid:String, flag:Boolean) {
			var slide;
			// 全画像スライド配列からライブポインタの表示を合わせる
			for each( slide in m_imgSlideArr) {
				slide.changeJoinStatus( uid, flag);
			}
			// 全画像スライド配列からライブポインタの表示を合わせる
			for each( slide in m_camSlideArr) {
				slide.changeJoinStatus( uid, flag);
			}
			m_plainSlide.changeJoinStatus( uid, flag);
		}
		
		function reDispatch_paintParts( e:PaintPartsEvent) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Whiteboard:reDispatch_paintParts()" + String( e.paintPartsData));
			//m_scrollX.update();
			//m_scrollY.update();
			dispatchEvent( new PaintPartsEvent( e.type, e.paintPartsData));
		}
		function reDispatch_textPaintParts( e:TextPaintPartsEvent) {
			dispatchEvent( new TextPaintPartsEvent( e.type, e.ppd));
		}
		function reDispatch( e:Event) {
			dispatchEvent( e);
		}
		
		// 虫眼鏡ツールでサイズが変わったとき、またはカメラスライドの映像サイズが変わったときに呼ばれる
		function onChangeWbSlideSize( e:Event) {
			
			onScaleChanged();
			
			// WhiteboardContinerに知らせて、ToolchipContainerのコンボボックスのscale表示を変更してもらう
			dispatchEvent( e);

		}
		
		// ToolchipContainerのコンボボックスでサイズが変わったとき呼ばれる
		function onChangeWbSlideSize_byCombo( e:Event) {
//alertDialog( "onChangeWbSlideSize_byCombo");

			onScaleChanged();

		}
		
		// 拡大縮小によりm_targetSlideの相対位置がずれてしまっているので、
		// m_targetSlideの左上がm_containerの(0,0)にくるように補正する
		protected function onScaleChanged() {
//alertDialog( "onScaleChanged");		

			if( m_targetSlide == null) return;
						
			// 拡大縮小によりm_targetSlideの相対位置がずれてしまっているので、
			// m_targetSlideの左上がm_containerの(0,0)にくるように補正する
			resetSlideRelativePosiX();
			resetSlideRelativePosiY();
			
			if( m_sync && !WhiteboardContainer.WB_AUTHORIZED) return; // 同期モードで編集権限無しのときはここまで

			switch( POSITIONING[ m_targetSlide.getBgtype()]) {
				case "center":
					// 表示わくより小さかったら、全表示するよう画面の中心寄せにする
					if( getConW() < m_containerMask.width) {
						m_container.x = ( m_containerMask.width- getConW()) / 2;
					}
					if( getConH() < m_containerMask.height) {
						m_container.y = ( m_containerMask.height - getConH()) / 2;
					}
					break;
				case "centertop":
					// 表示わくより小さかったら、全表示するよう画面の中心寄せにする
					if( getConW() < m_containerMask.width) {
						m_container.x = ( m_containerMask.width- getConW()) / 2;
					}
					m_container.y = 0;
					break;
				case "lefttop":
					m_container.x = 0;
					m_container.y = 0;
					break;
				default:
					Main.addErrMsg( "Whiteboard:onScaleChanged()" + Main.LANG.getReplacedSentence( "%sのPOSITIONINGは設定されていません", m_targetSlide.getBgtype()));
				break;
			}
			/*switch( m_targetSlide.getBgtype()) {
				case WhiteboardContainer.BGTYPE_CAMERA:
				case WhiteboardContainer.BGTYPE_PLAIN:
					// 表示わくより小さかったら、全表示するよう画面の中心寄せにする
					if( getConW() < m_containerMask.width) {
						m_container.x = ( m_containerMask.width- getConW()) / 2;
					}
					if( getConH() < m_containerMask.height) {
						m_container.y = ( m_containerMask.height - getConH()) / 2;
					}
					break;
				case WhiteboardContainer.BGTYPE_IMG:
					m_container.x = 0;
					m_container.y = 0;
					break;
				default:break;
			}*/
			
			
			
//trace("onScaleChanged");
			m_scrollY.update();
			m_scrollX.update();
			
			if( stage) stage.dispatchEvent( new Event( Event.RESIZE)); // フルフラッシュのときのため
		}
		
		
		// 現在表示中のWbSlideに、誰かによってペイントパーツに変更（追加／変更／削除）があったとき
		// 現在表示中のWBSlideから直接dispatchして呼ばれる
		// 自分によってペイントパーツに変更（追加／変更／削除）があったときはWhiteboardContainerから呼ばれる
		public function onChangeWbSlidePP( e:Event = null) {
			if( m_sync && !WhiteboardContainer.WB_AUTHORIZED) return; // 同期モードで編集権限無しのときはキャンセル
			
//alertDialog("onChangeWbSlidePP()" + m_targetSlide.getBgtype() + " w:" + getConW() + " h:" + getConH());	
			switch( POSITIONING[ m_targetSlide.getBgtype()]) {
				case "center":
				case "centertop":
					onChangeWbSlidePP_center( e);
					break;
				case "lefttop":
					onChangeWbSlidePP_lefttop( e);
					break;
				default:
					Main.addErrMsg( "Whiteboard:onChangeWbSlidePP() " + Main.LANG.getReplacedSentence( "%sのPOSITIONINGは設定されていません", m_targetSlide.getBgtype()));
				break;
			}
			/*switch( m_targetSlide.getBgtype()) {
				case WhiteboardContainer.BGTYPE_CAMERA:
				case WhiteboardContainer.BGTYPE_PLAIN:
					onChangeWbSlidePP_center( e);
					break;
				case WhiteboardContainer.BGTYPE_IMG:
					onChangeWbSlidePP_lefttop( e);
					break;
				default:break;
			}*/
		}
		function onChangeWbSlidePP_lefttop( e:Event = null) {
			
			var pre_container_x = m_container.x;
			
			// 常にm_containerの左端が見た目上の左端となるように
			// m_targetSlideの左上がマイナス方向にはみ出ている場合は m_targetSlideの位置を補正する
			var dx = resetSlideRelativePosiX();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.x += dx;
								
			if( getConW() < m_containerMask.width - m_scrollY.width) {
				// 表示わくより小さかったら、全表示するよう移動
				m_container.x = 0;
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP無しなので左寄せ");
					m_container.x = 0;
				} else {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP有り、移動しない");
				}
			}
			if( m_container.x != pre_container_x) m_scrollX.update();


			var pre_container_y = m_container.y;
			var dy = resetSlideRelativePosiY();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.y += dy;
			
			if( getConH() < m_containerMask.height - m_scrollX.height) {
				// 表示わくより小さかったら、全表示するよう移動
				m_container.y = 0;
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
					// PP無しなので上寄せ
					m_container.y = 0;
				} else {
					// 表示わくより大きい、PP有り、移動しない
				}
			}
			if( m_container.y != pre_container_y) m_scrollY.update();
			
			setSlideViewArea();
//alertDialog("onChangeWbSlidePP_lefttop() m_container.y " + m_container.y);				
		}
		function onChangeWbSlidePP_center( e:Event = null) {
			// 常にm_containerの左端が見た目上の左端となるように
			// m_targetSlideの左上がマイナス方向にはみ出ている場合は m_targetSlideの位置を補正する
			var dx = resetSlideRelativePosiX();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.x += dx;
								
			if( getConW() < m_containerMask.width - m_scrollY.width) {
				// 表示わくより小さかったら、全表示するよう移動
				if( m_container.x < m_containerMask.x) {
					// 表示領域からマイナス方向にはみ出ている
					if( dx < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、描画によってマイナス方向にはみ出た");	
						m_container.x = 0;
					} else {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）けど、
						// 表示領域からはマイナス方向にはみ出ている
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、左端のPPが削除された");							
					}
				} else if( m_container.x + getConW() > m_containerMask.width) {
					// 表示領域からプラス方向にはみ出ている
					if( dx < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
//alertDialog("このケースは無いはず");	
						// 右揃えにしても表示枠からははみでないので
						m_container.x = m_containerMask.width - getConW();
					} else if( dx > 0) {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）");							
						m_container.x = m_containerMask.width - getConW();
					} else {
						// ずっと右側に描画された場合とか
						m_container.x = m_containerMask.width - getConW();
					}
				} else {
					// はみ出てない
					if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、はみ出てない、PPも無し");
						if( m_targetSlide.getBgtype() == WhiteboardContainer.BGTYPE_PLAIN) {
							// 無地
							//m_container.x = 0;
							//m_container.x = ( m_containerMask.width - getConW()) / 2;
						} else {
							// 資料かカメラ映像
							m_container.x = ( m_containerMask.width - getConW()) / 2;
						}
//alertDialog( " m_container.x:"+ String(m_container.x)+ " m_containerMask.width:"+ String(m_containerMask.width) + " getConW():" + String(getConW()));
					} else {
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、はみ出てない、PP有り、移動しない");
					}
				}
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP無しなので左寄せ");
					m_container.x = 0;
				} else {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP有り、移動しない");
				}
			}
			
			m_scrollX.update();
			
			
			var dy = resetSlideRelativePosiY();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.y += dy;
			
			if( getConH() < m_containerMask.height - m_scrollX.height) {
				// 表示わくより小さかったら、全表示するよう移動
				if( m_container.y < m_containerMask.y) {
					// 表示領域からマイナス方向にはみ出ている
					if( dy < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
						m_container.y = 0;
					} else {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（上端のPPが削除された）けど、
						// 表示領域からはマイナス方向にはみ出ている
					}
				} else if( m_container.y + getConH() > m_containerMask.height) {
					// 表示領域からプラス方向にはみ出ている
					if( dy < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
						// このケースは無いはず
						// 右揃えにしても表示枠からははみでないので
						m_container.y = m_containerMask.height - getConH();
					} else if( dy > 0) {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（上端のPPが削除された）
						m_container.y = m_containerMask.height - getConH();
					} else {
						// このケースは無いはず
						// ずっと下側に追加描画された場合とか
						m_container.y = m_containerMask.height - getConH();
					}
				} else {
					// はみ出てない
					if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、はみ出てない、PPも無し");
						if( m_targetSlide.getBgtype() == WhiteboardContainer.BGTYPE_PLAIN) {
							// 無地
							//m_container.y = 0;
						} else {
							// 資料かカメラ映像
							m_container.y = ( m_containerMask.height - getConH()) / 2;
						}
					} else {
						// PP有り、移動しない
					}
				}
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
					// PP無しなので上寄せ");
					m_container.y = 0;
				} else {
					// 表示わくより大きい、PP有り、移動しない
				}
			}
			m_scrollY.update();
			
			
			setSlideViewArea();
			
		}
		/*function onChangeWbSlidePP_centertop( e:Event = null) {
			// 常にm_containerの左端が見た目上の左端となるように
			// m_targetSlideの左上がマイナス方向にはみ出ている場合は m_targetSlideの位置を補正する
			var dx = resetSlideRelativePosiX();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.x += dx;
								
			if( getConW() < m_containerMask.width - m_scrollY.width) {
				// 表示わくより小さかったら、全表示するよう移動
				if( m_container.x < m_containerMask.x) {
					// 表示領域からマイナス方向にはみ出ている
					if( dx < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、描画によってマイナス方向にはみ出た");	
						m_container.x = 0;
					} else {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）けど、
						// 表示領域からはマイナス方向にはみ出ている
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、左端のPPが削除された");							
					}
				} else if( m_container.x + getConW() > m_containerMask.width) {
					// 表示領域からプラス方向にはみ出ている
					if( dx < 0) {
						// ペイントパーツが描画によってm_containerからマイナス方向にはみ出てた
//alertDialog("このケースは無いはず");	
						// 右揃えにしても表示枠からははみでないので
						m_container.x = m_containerMask.width - getConW();
					} else if( dx > 0) {
						// ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、ペイントパーツが削除によってm_containerからプラス方向に移動した（左端のPPが削除された）");							
						m_container.x = m_containerMask.width - getConW();
					} else {
						// ずっと右側に描画された場合とか
						m_container.x = m_containerMask.width - getConW();
					}
				} else {
					// はみ出てない
					if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、はみ出てない、PPも無し");
						if( m_targetSlide.getBgtype() == WhiteboardContainer.BGTYPE_PLAIN) {
							// 無地
							//m_container.x = 0;
							//m_container.x = ( m_containerMask.width - getConW()) / 2;
						} else {
							// 資料かカメラ映像
							m_container.x = ( m_containerMask.width - getConW()) / 2;
						}
//alertDialog( " m_container.x:"+ String(m_container.x)+ " m_containerMask.width:"+ String(m_containerMask.width) + " getConW():" + String(getConW()));
					} else {
//alertDialog("dx:" + String(dx) +" 表示わくより小さい、はみ出てない、PP有り、移動しない");
					}
				}
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP無しなので左寄せ");
					m_container.x = 0;
				} else {
//alertDialog("dx:" + String(dx) +" 表示わくより大きい、PP有り、移動しない");
				}
			}
			
			m_scrollX.update();
			
			
			var pre_container_y = m_container.y;
			var dy = resetSlideRelativePosiY();
			// 画面上の見た目位置は変えないように
			// スライドの移動量と同じだけ、反対方向にm_containerを動かす
			m_container.y += dy;
			
			if( getConH() < m_containerMask.height - m_scrollX.height) {
				// 表示わくより小さかったら、全表示するよう移動
				m_container.y = 0;
			} else {
				// 表示わくより大きい
				if( ! m_targetSlide.containsPaintParts()) {
					// PP無しなので上寄せ
					m_container.y = 0;
				} else {
					// 表示わくより大きい、PP有り、移動しない
				}
			}
			if( m_container.y != pre_container_y) m_scrollY.update();
			
			setSlideViewArea();
			
		}*/
		
		// ペイントパーツを含めたスライドの左端をm_containerの0点に移動し、
		// その移動量を返す
		function resetSlideRelativePosiX():Number {
			
			if( m_targetSlide == null) return 0;
			//if( ! m_targetSlide.containsPaintParts()) return 0;
			
			// m_container、m_targetSlideの見た目上の左端を合わせる
			//var rectSelf:Rectangle = m_targetSlide.getBounds( m_targetSlide);
			
			// m_containerよりマイナス方向にはみ出ている分を取得
			m_targetSlide.removeSelectBoxTemporary();
			var rect:Rectangle = m_targetSlide.getBounds( m_container);
			var rectX = rect.x;
			m_targetSlide.addSelectBoxTemporary();
			//if( rectX < 0) m_targetSlide.x -= rectX;
			m_targetSlide.x -= rectX;
			return rectX;
			
		}
		// ペイントパーツを含めたスライドの上端をm_containerの0点に移動し、
		// その移動量を返す
		function resetSlideRelativePosiY():Number {
			
			if( m_targetSlide == null) return 0;
			//if( ! m_targetSlide.containsPaintParts()) return 0;
			
			m_targetSlide.removeSelectBoxTemporary();
			var rect:Rectangle = m_targetSlide.getBounds( m_container);
			var rectY = rect.y;
			m_targetSlide.addSelectBoxTemporary();
			m_targetSlide.y -= rectY;
			return rectY;
		}
				
		// m_containerの見た目サイズを返す（SelectBoxを除いたサイズ）
		function getConW():Number {
			//if( m_targetSlide.getBgtype() == WhiteboardContainer.BGTYPE_CAMERA) {
				//return CamWbSlide( m_targetSlide).getViewWidth();
			//} else {
			
				m_targetSlide.removeSelectBoxTemporary();
				var rect:Rectangle = m_targetSlide.getBounds( m_container);
				m_targetSlide.addSelectBoxTemporary();
				return rect.width;
			//}
				
		}
		// m_containerの見た目サイズを返す（SelectBoxを除いたサイズ）
		function getConH():Number {
			//if( m_targetSlide.getBgtype() == WhiteboardContainer.BGTYPE_CAMERA) {
				//return CamWbSlide( m_targetSlide).getViewHeight();
			//} else {
				m_targetSlide.removeSelectBoxTemporary();
				var rect:Rectangle = m_targetSlide.getBounds( m_container);
				m_targetSlide.addSelectBoxTemporary();
				return rect.height;
			//}
		}
		
		// 画面モードが変更されたときにWhiteboardContainerのchangeMode()から呼ばれる
		public function changeMode( sync:Boolean) {
			m_sync = sync;
			// 中心寄せにする
			onScaleChanged();
		}
		
		// ホワイトボード書き込み権限が変更されたときにWhiteboardContainerのonAuthorityChanged()から呼ばれる
		public function setAuthority( b:Boolean) {
			if( m_targetSlide != null) m_targetSlide.setAuthority( b);
		}

			
		function onComplete( e:Event) {
//Main.addDebugMsg( "Whiteboard:onComplete() " + String( m_targetSlide) + " " + m_targetSlide.name);
			// 中心寄せにする				
			onScaleChanged();
		}
		
		/*// WhiteboardContainerからスライドの削除時に呼ばれる
		public function allClear( bgtype:String, param) {
			// ペイントパーツが属するスライドを取得
			var tSlide = null; // ペイントパーツが属するスライド
			switch( bgtype) {
				case WhiteboardContainer.BGTYPE_IMG:
					for each( var imgSlide:ImgWbSlide in m_imgSlideArr) {
						if( imgSlide.getDocId() == param) {
							tSlide = imgSlide;
							break;
						}
					}
					break;
				case WhiteboardContainer.BGTYPE_CAMERA:
					for each( var camSlide:CamWbSlide in m_camSlideArr) {
						if( camSlide.getCameraid() == param) {
							tSlide = camSlide;
							break;
						}
					}
					break;
				case WhiteboardContainer.BGTYPE_PLAIN:
					tSlide = m_plainSlide;
					break;
			}
			
			if( tSlide == null) {
				return;
			}
			
			tSlide.allClear();
		}*/
			
		// WhiteboardContainerからペイントパーツのsoの値変更時に呼ばれる
		// 自分もしくは誰かによってペイントパーツに変更（追加／変更／削除）があったとき。
		public function setPaintParts( bgtype:String, param, ppdArr:Array) {
//alertDialog("setPaintParts");	
			
			// ペイントパーツが属するスライドを取得
			var tSlide = null; // ペイントパーツが属するスライド
			switch( bgtype) {
				case WhiteboardContainer.BGTYPE_IMG:
					for each( var imgSlide:ImgWbSlide in m_imgSlideArr) {
						if( imgSlide.getDocId() == param) {
							tSlide = imgSlide;
							break;
						}
					}
					break;
				case WhiteboardContainer.BGTYPE_CAMERA:
					for each( var camSlide:CamWbSlide in m_camSlideArr) {
						if( camSlide.getCameraid() == param) {
							tSlide = camSlide;
							break;
						}
					}
					break;
				case WhiteboardContainer.BGTYPE_PLAIN:
					tSlide = m_plainSlide;
					break;
			}
			
			if( tSlide == null) {
				// これが呼ばれるのは、この資料の表示中に、他者によってこの資料自体が削除されたとき
				Main.addDebugMsg( "Whiteboard: cannot find [ bgtype: " + bgtype +" , docid: "+ param + "]");
				return;
			}
			
			tSlide.setPaintParts( ppdArr);
			
		}
		
		public function getScale() : Number {
			if( m_targetSlide != null) return m_targetSlide.getScale();
			
			return -1;
		}
		public function setScale( scale:Number) : void {
			if( m_targetSlide != null) m_targetSlide.setScale( scale);
		}
		// 同期モード用
		public function setScroll( posi:Number) {
			m_scrollY.setScrollTargetPosi( posi);
			setSlideViewArea();
//Main.addDebugMsg("setScroll() m_container.y " + m_container.y);				

		}
		// 同期モード用
		public function setScrollH( posi:Number) {
			m_scrollX.setScrollTargetPosi( posi);
			setSlideViewArea();
//Main.addDebugMsg("setScrollH() m_container.y " + m_container.x);				

		}
		// 同期モード用
		public function getScroll() : Number {
			return m_scrollY.getScrollTargetPosi();
		}
		// 同期モード用
		public function getScrollH() : Number {
			return m_scrollX.getScrollTargetPosi();
		}
		
		// 同期モード用
		public function hideScroll( b:Boolean) {
			m_scrollX.visible = !b;
			m_scrollY.visible = !b;
		}
		
		// ホワイトボードの画面キャプチャ
		// WhiteboardContainerから呼ばれる
		public function capture() {
			if( m_targetSlide == null) return;
			
			var rect:Rectangle = m_targetSlide.getBounds( m_targetSlide);
			var matrix:Matrix = new Matrix();
			var _scale:Number = 1 / m_targetSlide.getScale();
			matrix.createBox( _scale, _scale, 0, -rect.x * _scale, -rect.y * _scale);
			var bmd :BitmapData = new BitmapData( rect.width * _scale, rect.height * _scale, false, 0xFFFFFF );
			try {
				bmd.draw( m_targetSlide, matrix);
			} catch( e:Error) {
				 errDialog( "Security Error: "+ Main.LANG.getParam( "ライブストリーミング映像はキャプチャできません。") + String( e.message));
				return;
			}
			if( m_shutterSound == null) m_shutterSound = new ShutterSound();
			m_shutterSound.play( 0, 1);
			
			var byteArray:ByteArray = PNGEncoder.encode( bmd);
			
			if( Main.CONF.isStudent( Main.CONF.UID)) {
				// ローカルにダウンロードする
				var now:Date = new Date();
				var fr:FileReference = new FileReference();
				configureListeners( fr);
				fr.save( byteArray, "capture.png");
				/*fr.save( byteArray, "capture_" + String( now.getFullYear())
												+ ( now.getMonth() + 1 < 10) ? '0' + String( now.getMonth() + 1) : String( now.getMonth() + 1)
												+ ( now.getDate() < 10) ? '0' + String( now.getDate()) : String( now.getDate())
												+ "_"
												+ ( now.getHours() < 10) ? '0' + String( now.getHours()) : String( now.getHours())
												+ ( now.getMinutes() < 10) ? '0' + String( now.getMinutes()) : String( now.getMinutes())
												+ ( now.getSeconds() < 10) ? '0' + String( now.getSeconds()) : String( now.getSeconds())												
												+ ".png");*/
				
			} else {
				// サーバにアップする
				
				// Base64形式に変換
				var enc:String = Base64.encodeByteArray(byteArray);
				// URLVariables
				var urlVar:URLVariables = new URLVariables();
				urlVar.do_mode = "up-capture";
				urlVar.class_id = Main.CONF.CLASS_ID;
				urlVar.capture_target = "wb";
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
					loader.addEventListener( Event.COMPLETE, function(e:*){ errDialog( MSG_CAPTURE_OK);}); 
					loader.addEventListener( IOErrorEvent.IO_ERROR, function(e:*){ errDialog( "IO_ERR:"+Main.LANG.getParam( "キャプチャ画像の保存失敗"));});
					loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function(e:*){errDialog(  "SECURITY_ERR:"+Main.LANG.getParam( "キャプチャ画像の保存失敗"));});
	
				} else {
					Main.addErrMsg( "Whiteboard:capture():" + Main.LANG.getParam( "UPLOAD_URLが指定されていないためキャプチャ画像を保存できません"));
				}
			}
			bmd.dispose();
						
		}
		private function configureListeners(dispatcher:IEventDispatcher):void {
            dispatcher.addEventListener(Event.CANCEL, cancelHandler);
            dispatcher.addEventListener(Event.COMPLETE, completeHandler);
            dispatcher.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
            dispatcher.addEventListener(Event.OPEN, openHandler);
            dispatcher.addEventListener(ProgressEvent.PROGRESS, progressHandler);
            dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
            dispatcher.addEventListener(Event.SELECT, selectHandler);
        }

        private function cancelHandler(event:Event):void {
            //HeaderContents( Main.HEADER_CON).showInfo("cancelHandler: " + event);
        }

        private function completeHandler(event:Event):void {
			var file:FileReference = FileReference(event.target);
			
            //Main.addErrMsg("completeHandler: " + file.name);
			if( ! file.name.match( /\.png$/)) {
				file.cancel();
				Main.addErrMsg( ERR_MSG_SAVE_PNG + "\n" + Main.LANG.getParam( "（例）") + file.name + " → " + file.name + ".png");  
			}
        }

        private function ioErrorHandler(event:IOErrorEvent):void {
            Main.addErrMsg("ioErrorHandler: " + event);
        }

        private function openHandler(event:Event):void {
			var file:FileReference = FileReference(event.target);
			/*if( ! file.name.match( /\.png$/)) {
				file.cancel();
				if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", ERR_MSG_SAVE_PNG);  
			}*/
            Main.addErrMsg("openHandler: " + event);
        }

        private function progressHandler(event:ProgressEvent):void {
            var file:FileReference = FileReference(event.target);
            Main.addErrMsg("progressHandler name=" + file.name + " bytesLoaded=" + event.bytesLoaded + " bytesTotal=" + event.bytesTotal);
        }

        private function securityErrorHandler(event:SecurityErrorEvent):void {
            Main.addErrMsg("securityErrorHandler: " + event);
        }

        private function selectHandler(event:Event):void {
            var file:FileReference = FileReference(event.target);
			/*if( ! file.name.match( /\.png$/)) {
				file.cancel();
				if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", ERR_MSG_SAVE_PNG);  
			}*/
            Main.addErrMsg("selectHandler: name=" + file.name + " URL=");
        }
		

		
		// WhiteboardContainer：ホワイトボード権限が無い場合、全クリアボタンクリックでclearAllPaintParts()から呼ばれる。
		public function clearAllPaintParts_local() : void {
			if( m_targetSlide != null) m_targetSlide.clearAllPaintParts_local();
		}
		// WhiteboardContainer：ホワイトボード権限がある場合、全クリアボタンクリックでSO変更後にclearAllPaintParts()から呼ばれる。
		// 自分によるSOの変更（code==success）は反映されないため
		public function clearAllPaintParts() : void {
			if( m_targetSlide != null) m_targetSlide.clearAllPaintParts();
		}
		
		// WhiteboardContainer：clearLastPaintParts()から呼ばれる
		public function clearLastPaintParts() : void {
			if( m_targetSlide != null) {
				m_targetSlide.clearLastPaintParts();
			}
		}
		
		// WhiteboardContainer：redoClearedPaintParts()から呼ばれる
		public function redoClearedPaintParts() : void {
			if( m_targetSlide != null) {
				m_targetSlide.redoClearedPaintParts();
			}
		}
		

		override public function setEnabled( b:Boolean):void {
			//m_testBtn.setEnabled( b);
			if( b) {
				//m_testBtn.addEventListener( MouseEvent.CLICK, onClick);
			} else {
				//m_testBtn.removeEventListener( MouseEvent.CLICK, onClick);
			}
		}
		
		override public function setViewWidth( w:Number, debug:String = ""):void {
			if( w < MIN_W) w = MIN_W;
			super.setViewWidth( w);
			
			m_containerMask.width = w - m_scrollY.width - 1;
			m_scrollY.x = w - m_scrollY.width;
			
			// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、
			// サイズがかわらないのであればここでリターン
			if( w != m_preW ) {
				m_preW = w;
				
				onScaleChanged() 
				
				m_scrollY.update();
				m_scrollX.setSize( w - ( m_scrollY.width - 1), m_scrollX.height);
				m_scrollX.update();
			}
			
			setSlideViewArea();
		}
		override public function setViewHeight( h:Number):void {
			if( h < MIN_H) h = MIN_H;
			super.setViewHeight( h);
			
			m_containerMask.height = h - m_scrollX.height - 1;
			m_scrollX.y = h - m_scrollX.height;
			
			// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、
			// サイズがかわらないのであればここでリターン
			if( h != m_preH ) {
				m_preH = h;
				
				onScaleChanged() 
				
				m_scrollY.setSize( m_scrollY.width, h - ( m_scrollX.height - 1) );
				m_scrollY.update();
				m_scrollX.update();
			}
			
			setSlideViewArea();
			
		}
		
		function setSlideViewArea() {
			if( m_targetSlide == null) return;
			
			m_targetSlide.setViewArea( m_container.x + m_targetSlide.x, m_container.y + m_targetSlide.y, getViewWidth() - m_scrollY.width, getViewHeight() - m_scrollX.height);
		}
		function errDialog( msg) {
			AlertManager.createAlert( this, msg);
		}
	}
}