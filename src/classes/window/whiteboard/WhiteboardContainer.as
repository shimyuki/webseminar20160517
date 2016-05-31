package window.whiteboard {
	import flash.display.*;
	import flash.geom.*;
	import common.*;
	import window.*;
	import window.whiteboard.toolchip.*;
	import window.whiteboard.slide.*;
	import window.whiteboard.imgdoc.*;
	import partition.*;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import fl.motion.easing.Back;
	import window.whiteboard.slide.PaintPartsEvent;
	import com.hurlant.crypto.Crypto;
	import com.hurlant.crypto.symmetric.*;
	import com.hurlant.crypto.hash.*;
	import com.hurlant.util.Hex;
	import flash.utils.ByteArray;
	import window.whiteboard.slide.PaintPartsData;
	import window.video.WbVideo;
	import window.header.HeaderEvent;
	import common.AlertManager;
	
	// ホワイトボード
	public class WhiteboardContainer extends ResizablePartitionContainer {
		
		static public const FORCE_CAMERA_ON:String = "FORCE_CAMERA_ON"; // 強制カメラON
		static public const BGTYPE_IMG:String = Main.LANG.getParam( "資料");
		static public const BGTYPE_CAMERA:String = Main.LANG.getParam( "カメラ映像");
		static public const BGTYPE_PLAIN:String = Main.LANG.getParam( "無地");
		
		static public const TOOL_ARROW = Main.LANG.getParam( "選択ツール");
		static public const TOOL_PENCIL = Main.LANG.getParam( "鉛筆ツール");
		static public const TOOL_SMOOTH = Main.LANG.getParam( "スムーズペンツール");
		static public const TOOL_ZOOMIN = Main.LANG.getParam( "拡大ツール");
		static public const TOOL_ZOOMOUT = Main.LANG.getParam( "縮小ツール");
		static public const TOOL_LINE = Main.LANG.getParam( "直線ツール");
		static public const TOOL_SQUARE = Main.LANG.getParam( "長方形ツール");
		static public const TOOL_CIRCLE = Main.LANG.getParam( "楕円ツール");
		static public const TOOL_TEXT = Main.LANG.getParam( "テキストツール");
		static public const TOOL_ERASER = Main.LANG.getParam( "消しゴムツール");		
		
		private const XML_RELOAD_COMPLETE:String = "XML_RELOAD_COMPLETE";
		
		// HeaderContentsLecturerのonItemRollOver()とonItemRollOut()と
		// ToolchipBtnsのonShowPanel()とonHidePanel()と
		// ToolchipBtnsのonItemRollOver()とonItemRollOut()と
		// BgSelectorのonItemRollOver_comboImg()とonItemRollOut_comboImg()と
		// ToolModeDetailのonItemRollOver()とonItemRollOut()と
		// SimpleToolModeDetailのonItemRollOver()とonItemRollOut()と
		// PopupContainerのaddWindow()とremoveWindow()と
		// onToolchipSelected()のTOOL_ARROW選択時に設定され、
		// WbSlideのonEnterFrame()のカーソル切り替え表示時に参照される
		static public var CURSOR_BUSY:Boolean = false;
		
		// ホワイトボード権限を持つか否か
		// WbSlide:setPPSelectable()
		static public var WB_AUTHORIZED:Boolean = true;
		
		private var m_nc:NetConnection = null;
		private var m_objname:String;
		private var m_ready4InitSo:Boolean = false;
		
		private var so_wbNow:SharedObject = null; // 現在の状態（背景タイプ、画像orカメラID）
		private var so_slideList:SharedObject = null; // スライドリスト
		//private var so_deletedDirList:SharedObject; // 削除されたDirリスト
		private var so_wb:SharedObject = null; // 講師やWBユーザが発信する、カメラ背景の画角
		private var m_paintParts_soArr:Array = null; // 各スライドの各ペイントパーツ（○とか□とか）の共有オブジェクト格納用配列
		private var so_sortId:SharedObject; // サムネイルnameとsortIdのセット
		private var m_isThumbsInitSorted:Boolean = false;
		protected var so_scrollScale:SharedObject = null; // スクロールとスケールの同期用
		private var m_syncScrollScale:Boolean = false; // スクロールとスケールを同期するか
		
		private var INIT_LEFT_W = 150;
		protected var m_toolchipCon:ToolchipContainer;
		private var m_imgdocWin:ImgdocWindow;
		private var m_imgdocCon:ImgdocContainer;
		protected var m_leftCon:PartitionContainer;
		protected var m_whiteboard:Whiteboard;
		protected var m_toolchipBtns:ToolchipBtns;
		private var m_wbVideo:WbVideo;
		private var m_bgSelector:BgSelector;		// 講師orWBユーザ用
		private var m_iconAuthority:IconAuthority;	// 受講生用
		
		private var m_is1stThumbXmlLoad:Boolean = true; // サムネイルXMLの一番最初の読み込みか、2回目以降（リロードボタンorスライド不整合処理による）
		
		private var m_ns_arr:Array = new Array();

		public function WhiteboardContainer( w:Number, h:Number) {
			dontDispose = true;
		
			m_toolchipCon = newToolchipContainer();
			m_imgdocCon = new ImgdocContainer();
			m_imgdocWin = new ImgdocWindow( m_imgdocCon);
			
			m_leftCon = new PartitionContainer( INIT_LEFT_W, h, Main.TOP_BTM, m_toolchipCon, m_imgdocWin, 200);
			m_leftCon.dontDispose = true;

			var rightWin:ResizableWindow = new ResizableWindow( 150, 300);
			m_whiteboard = newWhiteboard();
			rightWin.setContents( m_whiteboard);
			
			super( w, h, Main.LEFT_RIGHT, m_leftCon, rightWin, INIT_LEFT_W); // 
			
			// 開く閉じるの監視
			m_toolchipCon.addEventListener( ToolchipContainer.OPENED,
										   function( e:Event) {
											   setPartitionX( INIT_LEFT_W);
										   });
			m_toolchipCon.addEventListener( ToolchipContainer.CLOSED,
										   function( e:Event) {
											   setPartitionX( m_leftCon.MIN_W);
										   });
			m_imgdocCon.addEventListener( ImgdocContainer.OPENED,
										   function( e:Event) {
											   setPartitionX( INIT_LEFT_W);
										   });
			m_imgdocCon.addEventListener( ImgdocContainer.CLOSED,
										   function( e:Event) {
											   setPartitionX( m_leftCon.MIN_W);
										   });
			
			// サムネイルリストのXML読み込み完了
			m_imgdocCon.addEventListener( FolderContainer.XML_LOAD_COMPLETE, onLoadThumbXml);

			// サムネイルの追加時
			m_imgdocCon.addEventListener( DocEvent.ADDED, onDocAdded);
			m_imgdocCon.addEventListener( DocEventMulti.ADDED, onDocAddedMulti);
			m_imgdocCon.addEventListener( FolderContainer.REPLACED, onDocReplaced);
			//m_imgdocCon.addEventListener( FolderContainer.RESORTED, onThumbsResorted);
			
			//////////////////////////////////////
			// ペイントツールきりかえのボタン生成
			m_toolchipBtns = newToolchipBtns();
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_PENCIL));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_SMOOTH));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_LINE));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_SQUARE));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_CIRCLE));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_TEXT));
			m_toolchipBtns.initSimpleToolModeDetail( m_toolchipCon.getToolModeDetail( TOOL_ERASER));
			m_toolchipBtns.addEventListener( ToolchipEvent.SELECTED, onToolchipSelected);
			m_toolchipBtns.addEventListener( "clear", clearAllPaintParts);
			m_toolchipBtns.addEventListener( "back", clearLastPaintParts);
			m_toolchipBtns.addEventListener( "redo", redoClearedPaintParts);
			m_toolchipBtns.addEventListener( "capture", function( e:*){ m_whiteboard.capture()});
			
			// ToolchipContainerの拡大縮小率のコンボボックスの値が変更されるのを監視。
			// コンボボックスが変更されたら実際のスライドのコンテナのスケールを変更する。
			m_toolchipBtns.addEventListener( ScaleComboEvent.CHANGED, setSlideScale);
			
			//////////////////////////////////////
			// 背景きりかえのボタン生成
			if( Main.CONF.isPro( Main.CONF.UID) || Main.CONF.getWhiteboardUID() == Main.CONF.UID) m_bgSelector = new BgSelector_lec();
			else m_bgSelector = new BgSelector();
			
			m_bgSelector.addEventListener( BgSelector.POPUP_CLICKED, function( e:HeaderEvent) {
												dispatchEvent( new HeaderEvent( e.type, e.winname));
											 });
			m_bgSelector.addEventListener( DocStepper.FIRST_CLICKED, select1stDoc);
			m_bgSelector.addEventListener( DocStepper.BACK_CLICKED, selectBackDoc);
			m_bgSelector.addEventListener( DocStepper.NEXT_CLICKED, selectNextDoc);
			m_bgSelector.addEventListener( DocStepper.LAST_CLICKED, selectLastDoc);

			
			m_iconAuthority = new IconAuthority();
			
			//////////////////////////////////////
			// ペイントツール詳細設定の変更時
			m_toolchipCon.addEventListener( ToolchipContainer.TOOLMODEDETAIL_CHANGE,
										   function( e:Event) {

											   // ホワイトボードのペイントモードを設定
												m_whiteboard.setToolModeDetail( m_toolchipCon.getCurrentToolMode());
												
												// 簡易ツールパネルSimpleToolModeDetailを合わせる
												m_toolchipBtns.applySimpleToolModeDetail( m_toolchipCon.getCurrentToolMode());
										   });
			m_toolchipBtns.addEventListener( ToolchipBtns.SIMPLE_TOOLMODEDETAIL_CHANGE,
										   function( e:Event) {
											   // ペイントツール詳細設定に反映
												m_toolchipCon.applyToolModeDetail( m_toolchipBtns.getCurrentToolMode());
										   });
			
			// ToolchipContainerの拡大縮小率のコンボボックスの値が変更されるのを監視。
			// コンボボックスが変更されたら実際のスライドのコンテナのスケールを変更する。
			m_toolchipCon.addEventListener( ScaleComboEvent.CHANGED, setSlideScale);
			
			// ペイントパーツの変更を監視
			m_whiteboard.addEventListener( PaintPartsEvent.ADDED, changePaintPartsSo);
			m_whiteboard.addEventListener( PaintPartsEvent.REMOVED, changePaintPartsSo);
			m_whiteboard.addEventListener( PaintPartsEvent.CHANGED, changePaintPartsSo);
			m_whiteboard.addEventListener( PaintPartsEvent.MULTI_CHANGE, changePaintPartsSo);
			m_whiteboard.addEventListener( TextPaintPartsEvent.START_CHANGE, changeTool);
			
			m_whiteboard.addEventListener( WbSlide.CHANGE_PP_LOCAL, changePpLocal);
			
			// スライドのコンテナのスケールが虫眼鏡クリックによって変更されるのを監視。
			// サイズが変更されたらToolchipContainerのコンボボックスの表示を
			// 実際のスケールに合わせて変更する
			m_whiteboard.addEventListener( WbSlide.CHANGE_SIZE, changeScaleCombo);
			
			m_whiteboard.addEventListener( Whiteboard.SLIDE_NOT_FOUND, onSlideNotfound);
			
			// 生徒だったら左カラムをツールチップコンテナのみにする
			if( ! Main.CONF.isPro( Main.CONF.UID) && Main.CONF.UID != Main.CONF.getWhiteboardUID()) init_container1st( m_toolchipCon);
						
		}
		function onSlideNotfound( e:Event) {
Main.addDebugMsg( "WhiteboardConteiner onSlideNotfound: 該当スライド["+ so_wbNow.data.hash.param + "]がみつからないので、スライドリストを再読み込みします");					
			m_imgdocCon.reloadThumbXml();
			addEventListener( XML_RELOAD_COMPLETE, onReloadThumbXml_4SlideNotFound);
			// 講師の場合
			// スライドリストを再読み込み中は、とりあえず無地に戻しておく。
			//（探し中のdocIDが永遠にみつからないスライドの場合もあるので。）
			if( Main.CONF.isPro( Main.CONF.UID)) {
				setSo_wbNow( BGTYPE_PLAIN, "");
			}
		}
		function onReloadThumbXml_4SlideNotFound( e:Event) {
			removeEventListener( XML_RELOAD_COMPLETE, onReloadThumbXml_4SlideNotFound);
			m_whiteboard.reloadSlide();
		}
		function onLoadThumbXml( e:Event) {
			if( m_is1stThumbXmlLoad) {
				m_ready4InitSo = true;
				if( m_nc != null) initSo( m_objname, m_nc, m_wbVideo);
				m_is1stThumbXmlLoad = false;
			} else {
				// ２回目以降。（リロードボタンや、スライドが見つからないときに呼ばれる）
				dispatchEvent( new Event( XML_RELOAD_COMPLETE)); // 自分自身に知らせる
			}
		}		
		function select1stDoc( e:Event) {
			m_imgdocCon.select1stDoc( m_bgSelector.getDocId());
		}
		function selectBackDoc( e:Event) {
			m_imgdocCon.selectBackDoc( m_bgSelector.getDocId());
		}
		function selectNextDoc( e:Event) {
			m_imgdocCon.selectNextDoc( m_bgSelector.getDocId());
		}
		function selectLastDoc( e:Event) {
			m_imgdocCon.selectLastDoc( m_bgSelector.getDocId());
		}
		
		// 講師の場合呼ばれる
		public function lockBgSelectorCam( b:Boolean) {
			if( BgSelector_lec( m_bgSelector) == null) return;
			BgSelector_lec( m_bgSelector).lockCam( b);
		}
		
		protected function newWhiteboard() {
			return new Whiteboard();
		}
		
		// アンドロイドでoverrideされる
		protected function newToolchipContainer() {
			return new ToolchipContainer();
		}
		// アンドロイドでoverrideされる
		protected function newToolchipBtns() {
			return new ToolchipBtns();
		}
				
		// サムネイルの手動ソート操作が行われた後に呼ばれる
		function onDocReplaced( e:Event) {
			
			// 背景セレクタのDocStepperの戻る進むボタンのenableを更新
			if( m_bgSelector.getDocId() != "") {
				// 実際に背景として表示されていないとしても、DocStepperに資料名が入っていたら
				var selectedDoc:Doc = m_imgdocCon.getDocById( m_bgSelector.getDocId());
				if( selectedDoc != null) m_bgSelector.setSelectorDocStepper( selectedDoc.getName(), m_imgdocCon.existPrevDoc( selectedDoc), m_imgdocCon.existNextDoc( selectedDoc));
			}
			
		}
		
		// テキストペイントツールがダブルクリックで編集モードになったときの処理
		// ツールチップコンテナのテキストツールのToolModeDetailを編集中のテキストの内容に合わせ、
		// ツールボタンのテキストツールをONにする
		function changeTool( e:TextPaintPartsEvent) {
			m_toolchipBtns.setTextOn();
			m_toolchipCon.setTextToolModeDetail( e.ppd);
		}
		
		// 最初の読み込み、若しくは手動によって資料画像がサムネイル一覧に追加されたときに呼ばれる
		// PDF変換画像など複数同時にアップされた場合でも、一個一個の画像のdocid取得完了の度に呼ばれる
		function onDocAdded( e:DocEvent) {
			if( e.doc.getId() == "") {
				Main.addErrMsg( "WhiteboardContainer:" + Main.LANG.getParam( "画像識別IDが設定されていないため、ホワイトボードに画像スライド追加できません") + ":" + e.doc.getName());
				// サムネイル一覧から削除
				e.doc.dispatchEvent( new DirEvent( DirEvent.MINUS_CLICKED, e.doc));
				m_imgdocCon.setFileStatusText("ERROR: " + e.doc.getName() + " " + Main.LANG.getParam( "画像識別IDが設定されていないため、ホワイトボードに画像スライド追加できません"));
				return;
			}

			// ホワイトボードに画像スライド追加
			m_whiteboard.addImgSlide( e.doc);
			// 背景セレクタの資料ラジオボタンを有効に
			m_bgSelector.setEnabledRadioImg( true);
			// 背景セレクタのDocStepperの戻る進むボタンのenableを更新
			if( m_bgSelector.getDocId() != "") {
				// 実際に背景として表示されていないとしても、DocStepperに資料名が入っていたら
				var selectedDoc:Doc = m_imgdocCon.getDocById( m_bgSelector.getDocId());
				if( selectedDoc != null) m_bgSelector.setSelectorDocStepper( selectedDoc.getName(), m_imgdocCon.existPrevDoc( selectedDoc), m_imgdocCon.existNextDoc( selectedDoc));
			}

		}
		// 最初の読み込み、若しくは手動によって資料画像がサムネイル一覧に追加されたときに呼ばれる
		// PDF変換画像など複数同時にアップされた場合、全ての画像のdocid取得完了の後に呼ばれる
		function onDocAddedMulti( e:DocEventMulti) {
			if( so_slideList == null) {
Main.addErrMsg( "WCon:onDocAddedMulti()" + Main.LANG.getParam( "通信エラー") + " so_slideList is null.");						
				return;
			}
			var objArr:Array = null;
			if( so_slideList.data.objArr != undefined) {
				objArr = so_slideList.data.objArr as Array;
			} else {
				objArr = new Array();
			}
			for each( var doc:Doc in e.docArr) {
				objArr.push( { bgtype:BGTYPE_IMG, param:doc.getId()});
			}
			so_slideList.data.objArr = objArr;
			so_slideList.setDirty( "objArr");
//Main.addDebugMsg( "WCon:so_slideList.setDirty 4");
		}
		
		// ツールチップボタンがクリックされたとき
		function onToolchipSelected( e:ToolchipEvent) {
			// ツールチップコンテナにペイントモードの詳細設定情報を反映。
			m_toolchipCon.setToolMode( e.tool_name);
			
			// ホワイトボードのペイントモードを設定
			m_whiteboard.setToolModeDetail( m_toolchipCon.getCurrentToolMode());
			
			// コンボボックスのスケール表示を実際の値に合わせる
			if( e.tool_name == TOOL_ZOOMIN || e.tool_name == TOOL_ZOOMOUT) {
				var scale:Number = m_whiteboard.getScale(); // 実際のスケールを取得
				m_toolchipCon.setScaleCombo( scale);
				m_toolchipBtns.setScaleCombo( ( scale * 100).toString() + "%");
			}
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", String(e.tool_name));			
			// 選択ツールの場合はカーソル表示
			if( e.tool_name == TOOL_ARROW) {
				CURSOR_BUSY = true;
			} else {
				CURSOR_BUSY = false;
			}
		}
		
		public function initSo( objname:String, nc:NetConnection, wbVideo:WbVideo) : void {
//alertDialog( "initSo" + String ( m_ready4InitSo));
			m_nc = nc;
			m_objname = objname;
			m_wbVideo = wbVideo;
			m_whiteboard.setNc( m_nc);
			m_whiteboard.setWbVideo( wbVideo);
			
			m_imgdocCon.initStatus();
			
			if( ! m_ready4InitSo) {
				// 最初のサムネイルリストXMLの読み込みが終わっていない場合は
				// 終わるまで待つ。
				// （対応するホワートボードのスライドも存在しないので、
				// 　SharedObjectが空で上書きされてしまうため。）
				return;
			}
			
			///////////////////////
			// 各スライドの各ペイントパーツ（○とか□とか）のSharedObject格納用配列生成
			// (配列の長さ＝スライドの数)
			if( m_paintParts_soArr == null) {
				m_paintParts_soArr = new Array();
			} else {
				for each( var so:SharedObject in m_paintParts_soArr) {
					so.connect( nc);
				}
			}
			
			//////////////////////
			//SharedObjectの取得
			
			if( so_wb == null) {
				so_wb = SharedObject.getRemote( objname + "_wbStream", nc.uri, false);
				m_bgSelector.setSoWb( so_wb);
				m_whiteboard.setSoWb( so_wb);
				m_wbVideo.setSoWb( so_wb, m_nc);
			}
			so_wb.connect( m_nc);
			
			// 現在のWBの状態を取得
			if( so_wbNow == null) {
				so_wbNow = SharedObject.getRemote( objname + "_wbNow", nc.uri, false);
				so_wbNow.addEventListener( SyncEvent.SYNC, function( e:SyncEvent):void {
					if( so_wbNow.data.hash == undefined) {
						setSo_wbNow( BGTYPE_PLAIN, "");
						return;
					}
					
					for each( var obj in e.changeList) {
						if( obj.name == "hash") {
							var lastBgType:String = "";
							if( m_whiteboard.getCurrentSlide() != null) lastBgType = WbSlide( m_whiteboard.getCurrentSlide()).getBgtype();					
							
							///////////////////////
							// スライドのチェンジ
							m_whiteboard.changeSlide( so_wbNow.data.hash.bgtype, so_wbNow.data.hash.param);
		
							// 背景セレクタの状態を合わせる
							if( so_wbNow.data.hash.bgtype == BGTYPE_IMG) {
								var doc:Doc = m_imgdocCon.getDocById( so_wbNow.data.hash.param);
								m_bgSelector.setSelector( so_wbNow.data.hash.bgtype, so_wbNow.data.hash.param);
								if( doc != null) {
									m_bgSelector.setSelectorDocStepper( doc.getName(), m_imgdocCon.existPrevDoc( doc), m_imgdocCon.existNextDoc( doc));
								} else {
									m_bgSelector.resetSelectorDocStepper();
								}
							} else {
								m_bgSelector.setSelector( so_wbNow.data.hash.bgtype, so_wbNow.data.hash.param);
							}
							// Imgdocのサムネイルの選択状態を合わせる
							if( so_wbNow.data.hash.bgtype == BGTYPE_IMG) m_imgdocCon.setSelected( so_wbNow.data.hash.param);
							else m_imgdocCon.setSelected( "");
							// ホワイトボード（と新しいスライド）のペイントモードを設定
							m_whiteboard.setToolModeDetail( m_toolchipCon.getCurrentToolMode());
							
							// 戻る、進むボタンの初期設定
							m_toolchipBtns.setEnabledBackBtn( WbSlide( m_whiteboard.getCurrentSlide()).canBack());
							m_toolchipBtns.setEnabledRedoBtn( WbSlide( m_whiteboard.getCurrentSlide()).canRedo());
							
							// コンボボックスのスケール表示を合わせる
							var scale:Number = m_whiteboard.getScale(); // 実際のスケールを取得
							m_toolchipCon.setScaleCombo( scale);
							m_toolchipBtns.setScaleCombo( ( scale * 100).toString() + "%");
							
//Main.addErrMsg( so_wbNow.data.hash.bgtype + "," + so_wbNow.data.hash.param);					
							
							// 自分が講師の場合、カメラ映像からカメラ映像以外に変わったとき、Mainに知らせる
							// (講師映像の画角がカメラ映像背景と同じサイズになっちゃっていることがあるので、それを正すため)
							if( Main.CONF.isPro( Main.CONF.UID) && lastBgType == BGTYPE_CAMERA && so_wbNow.data.hash.bgtype != BGTYPE_CAMERA) dispatchEvent( new Event( "resetCameraSize"));
					
							if( obj.code == "success" && WhiteboardContainer.WB_AUTHORIZED) {
							
//Main.addErrMsg( "自分のをみんなに反映　"+( scale* 100).toString() + "% ," + m_whiteboard.getScroll()+ "," + m_whiteboard.getScrollH());								
								so_scrollScale.setProperty( "scale", scale);
								so_scrollScale.setProperty( "scroll", m_whiteboard.getScroll());
								so_scrollScale.setProperty( "scrollH", m_whiteboard.getScrollH());
								//break;
							}
						}
					}
				
				});
			}
			// スライドリスト（「背景タイプと画像パスorカメラID」のセットの配列）
			if( so_slideList == null) {
				so_slideList = SharedObject.getRemote( objname + "_slideList", nc.uri, false);
				so_slideList.addEventListener( SyncEvent.SYNC, function( e:SyncEvent):void {
//Main.addDebugMsg( "wbCon so_slideList SyncEvent");					
											  
					// 一番最初と、サムネイル追加に伴うスライドの追加時に呼ばれる
					// 講師orWBユーザにより最初に1回のみ、以下が実行される
					if( so_slideList.data.objArr==undefined) {
					// Whiteboardに追加済みのスライド情報を共有オブジェクトに設定する
//Main.addErrMsg( "Whiteboardに追加済みのスライド情報を共有オブジェクトに設定する");
						var objArr = new Array();
						objArr.push( { bgtype:BGTYPE_PLAIN, param:0xffffff});
						
						var imgSlideArr:Array = m_whiteboard.getImgSlideArr();
						for each( var imgSlide:ImgWbSlide in imgSlideArr) {
							objArr.push( { bgtype:BGTYPE_IMG, param:imgSlide.getDocId()});
						}
						
						var camSlideArr:Array = m_whiteboard.getCamSlideArr();
						for each( var camSlide in camSlideArr) {
							objArr.push( { bgtype:BGTYPE_CAMERA, param:camSlide.name});
						}
						
						so_slideList.data.objArr = objArr;
						so_slideList.setDirty( "objArr");
//Main.addDebugMsg( "WCon:so_slideList.setDirty 1");						
						return;
						
					}
					
					
					for each( var _obj in e.changeList) {
						
						if( _obj.name == "objArr") {
							// 講師とWBユーザのサムネイル一覧の整合性を合わせるため、サムネイルを全部更新
//Main.addDebugMsg( "WCon:so_slideList.SyncEvent _obj.code:" + _obj.code);
							if( _obj.code == "change") {
								m_imgdocCon.updateFolderCon( so_slideList.data.objArr);
							}
							
									
							// 各スライドのペイントパーツ（○とか□とか）リスト追加を試みる
							//（既に追加済みならなにも起こらないはず）
							for each( var obj in so_slideList.data.objArr) {
								// ペイントパーツ監視用SharedObjectの生成、格納
								addPaintPartsSo( obj.bgtype, obj.param);
							}
					
							// スライドが削除されたときに、ホワイトボードのm_imgSlideArrと整合性をとるため、
							// so_slideListから削除済みのスライドはホワイトボードのm_imgSlideArrからも削除する
							var removedDocIds:Array = m_whiteboard.removeImgSlide_ifMissMatch( so_slideList.data.objArr);
//alertDialog("スライド削除数：" + removedDocIds.length);
							
							for each( var removedDocId:String in removedDocIds) {
								for( var i = 0; i < m_paintParts_soArr.length; i++) {
									var so:SharedObject = SharedObject( m_paintParts_soArr[ i]);
									if( so.data.param != undefined && so.data.param == removedDocId) {
										so.data.ppdArr = new Array();
										so.setDirty( "ppdArr");

										//so.removeEventListener( SyncEvent.SYNC, onSync_paintParts);
//										so.close();
//										m_paintParts_soArr.splice( i, 1);
//										i--;
//alertDialog("ペイントパーツも削除:" + so.data.param);
									}
								}
							}
						}
					}
					
				});
			}
			
			// サムネイルnameとsortIdのセット
			if( so_sortId == null) {
				so_sortId = SharedObject.getRemote( objname + "_thuNameSortId", nc.uri, true);
				// この関数が呼ばれるのは、Thumbnails.XML_LOAD_COMPLETEがdispatchされた後に
				// SharedObjectが初めて読み込まれたときと、
				// 手動ソートによってSharedObjectの値変更イベントが発生したとき。
				so_sortId.addEventListener( SyncEvent.SYNC, onSyncSortId);
			}
						
			// スクロールやスケールの同期
			if( so_scrollScale == null) {
				so_scrollScale = SharedObject.getRemote( objname + "_scrollScale", nc.uri, false);
				so_scrollScale.addEventListener( SyncEvent.SYNC, onSyncScrollScale);
			}
			
			//SOにアクセス
			so_sortId.connect( nc);
			so_wbNow.connect( nc);
			so_slideList.connect( nc);
			so_scrollScale.connect( nc);
		}
		function onSyncSortId ( e:SyncEvent):void {
//Main.addDebugMsg( "wbCon onSyncSortId");					
			if( so_sortId.data.hash == undefined) return;

			// この関数でサムネイルをソートすべきは一番最初のSharedObjectが初めて読み込まれた時のみで、
			// 手動ソート時には実行キャンセルする。（重複になるから）
			//if( ! m_isThumbsInitSorted) m_imgdocCon.init_sort( so_sortId.data.hash);
			if( ! m_isThumbsInitSorted) m_imgdocCon.init_sort( so_sortId);
			m_isThumbsInitSorted = true;
			
			// m_bgSelectorのソート
			//m_bgSelector.resortImgCombo();
		}
		
		// スクロールやスケールの同期をするか否かの設定。
		// 画面モードの変更時にMainのonLayoutChangeやchangeStuLayoutから呼ばれる
		// wb_admin: 自分が講師の場合：WBユーザがログイン中だったらfalse。
		// wb_admin: 自分がWBユーザの場合：講師がログイン中だったらfalse。
		// * WhiteboardContainer_viewがオーバーライドしている
		public function syncScrollScale( b:Boolean, wb_admin:Boolean) {
			m_syncScrollScale = b;
//Main.addDebugMsg( "スクロールやスケールの同期1:" + String( b) + " admin:" + String( wb_admin) + " so:" + String( so_scrollScale));			
			
			if( m_syncScrollScale) {
				// 実際にm_whiteboardがスクロール時にdispatchするかどうかはそのときの権限状態による
				m_whiteboard.addEventListener( "scroll changed", onScrollChanged);
				m_whiteboard.addEventListener( "scrollH changed", onScrollHChanged);
			} else {
				m_whiteboard.removeEventListener( "scroll changed", onScrollChanged);
				m_whiteboard.removeEventListener( "scrollH changed", onScrollHChanged);
			}
			
			changeMode();
			
			if( so_scrollScale != null) {
				if( m_syncScrollScale) {
					so_scrollScale.addEventListener( SyncEvent.SYNC, onSyncScrollScale);
					if( ( Main.CONF.isPro( Main.CONF.UID) || Main.CONF.UID == Main.CONF.getWhiteboardUID()) && WhiteboardContainer.WB_AUTHORIZED) {
						// 講師またはWBユーザで、かつWB編集権減をもっている場合
						var scale:Number = m_whiteboard.getScale(); // 実際のスケールを取得
						if( scale > 0 && wb_admin) so_scrollScale.setProperty( "scale", scale);
					}
					
					// すでにonSync済みだった場合のため、実行しておく
					onSyncScrollScale();
					
				} else {
					so_scrollScale.removeEventListener( SyncEvent.SYNC, onSyncScrollScale);
				}
			}
		}
		function onSyncScrollScale( e:SyncEvent = null):void {
//trace( "wbCon onSyncScrollScale");					
			
			if( ! m_syncScrollScale) return;
			if( e == null || !WhiteboardContainer.WB_AUTHORIZED) {
				// スケールを変更
				if( so_scrollScale.data.scale != undefined) {
//Main.addErrMsg( "スケールを変更 -> " + ( so_scrollScale.data.scale * 100).toString() + "%");
					m_whiteboard.setScale( so_scrollScale.data.scale);
					m_toolchipCon.setScaleCombo( Number( so_scrollScale.data.scale));
					m_toolchipBtns.setScaleCombo( ( so_scrollScale.data.scale * 100).toString() + "%");
				}
				// 垂直スクロールを変更
//trace( "scroll: " + so_scrollScale.data.scroll);		
				if( so_scrollScale.data.scroll != undefined) m_whiteboard.setScroll( so_scrollScale.data.scroll);
				// 水平スクロールを変更
//trace( "scrollH: " + so_scrollScale.data.scrollH);
				if( so_scrollScale.data.scrollH != undefined) m_whiteboard.setScrollH( so_scrollScale.data.scrollH);
			} else {
				for each( var obj in e.changeList) {
					// スケールに変更があった場合
					if( obj.name == "scale" && obj.code == "change") {
//trace( "wbCon 実際のスケールを変更");					
						// 実際のスケールを変更
						m_whiteboard.setScale( so_scrollScale.data.scale);
						// こんボボックスの表記も変更
						m_toolchipCon.setScaleCombo( so_scrollScale.data.scale);
						m_toolchipBtns.setScaleCombo( ( so_scrollScale.data.scale * 100).toString() + "%");
					}
					// 垂直スクロールに変更があった場合
					if( obj.name == "scroll" && obj.code == "change") {	
//trace( "wbCon 実際の垂直スクロールを変更");					
						m_whiteboard.setScroll( so_scrollScale.data.scroll);
					}
					// 水平スクロールに変更があった場合
					if( obj.name == "scrollH" && obj.code == "change") {
//trace( "wbCon 実際の水平スクロールを変更");					
						m_whiteboard.setScrollH( so_scrollScale.data.scrollH);
					}
				}
			}
			
		}
		function onScrollChanged( e:Event) { if( so_scrollScale != null) so_scrollScale.setProperty( "scroll", m_whiteboard.getScroll());}
		function onScrollHChanged( e:Event) { if( so_scrollScale != null) so_scrollScale.setProperty( "scrollH", m_whiteboard.getScrollH());}
		
		// 権限変更時にWhiteboardWindowからも呼ばれる
		public function onAuthorityChanged() {
			changeMode();
			m_whiteboard.setAuthority( WB_AUTHORIZED);
			m_toolchipCon.setAuthority( WB_AUTHORIZED);
			if( WhiteboardContainer.WB_AUTHORIZED) m_iconAuthority.on();
			else m_iconAuthority.off();
			
			// 戻る、進むボタンの初期設定（権限が変わったらいじれるPPも変わるので）
			if( m_whiteboard.getCurrentSlide() != null) {
				m_toolchipBtns.setEnabledBackBtn( WbSlide( m_whiteboard.getCurrentSlide()).canBack());
				m_toolchipBtns.setEnabledRedoBtn( WbSlide( m_whiteboard.getCurrentSlide()).canRedo());
			} else {
				m_toolchipBtns.setEnabledBackBtn( false);
				m_toolchipBtns.setEnabledRedoBtn( false);
			}

		}
		
		function changePpLocal( e:Event) {
			if( m_whiteboard.getCurrentSlide() != null) {
				m_toolchipBtns.setEnabledBackBtn( WbSlide( m_whiteboard.getCurrentSlide()).canBack());
				m_toolchipBtns.setEnabledRedoBtn( WbSlide( m_whiteboard.getCurrentSlide()).canRedo());
			} else {
				m_toolchipBtns.setEnabledBackBtn( false);
				m_toolchipBtns.setEnabledRedoBtn( false);
			}
		}
		
		// 画面モードの変更対応
		protected function changeMode() {
			if( ! WhiteboardContainer.WB_AUTHORIZED) {
				m_toolchipCon.close();
			} else {
				m_toolchipCon.open();
			}
			m_toolchipCon.setAuthority( WhiteboardContainer.WB_AUTHORIZED);
			
			if( m_syncScrollScale && ! WhiteboardContainer.WB_AUTHORIZED) {
				// 同期モードで、かつこのユーザにWB編集権限はないので、WBはただ表示するだけ。
				m_whiteboard.hideScroll( true);
				//m_toolchipCon.lock( true);
				m_toolchipBtns.setSyncMode( true);
				
				// 同期モード中の権限無し中はPartitionDragManagerが効かないので、手動で横幅をあわせる
				m_toolchipCon.setViewWidth( OpenCloseBtn.W);
			} else {
				// 通常の表示に戻す
				m_whiteboard.hideScroll( false);
				//m_toolchipCon.lock( false);
				m_toolchipBtns.setSyncMode( false);
			}
	
			m_whiteboard.changeMode( m_syncScrollScale);
		}
				
		// ペイントパーツ監視用SharedObjectの生成、格納
		function addPaintPartsSo( bgtype:String, param) {

			// 同じbgtype,paramのものが生成済みだったらキャンセル　を検証
			if( getPaintPartsSo( bgtype, param) != null) {
				return;
			} else {
			}
			
			var key:String;
			switch( bgtype) {
				case BGTYPE_PLAIN: key = "plain"; break;
				case BGTYPE_CAMERA: key = "camera" + String( param); break;
				case BGTYPE_IMG:
					var tmp_arr:Array = String( param).split( "/");
					key = tmp_arr[ tmp_arr.length - 1];
					break;
			}
			
//Main.addErrMsg( key);
			/*
			var hash:IHash = Crypto.getHash( "sha1"); // sha sha1 sha224 sha256
			var result:ByteArray = hash.hash( Hex.toArray(Hex.fromString( key)));
			var sha1:String = Hex.fromArray(result);
//Main.addErrMsg( sha1);
*/

			var so:SharedObject = SharedObject.getRemote( key, m_nc.uri, true);
			
			so.setProperty( "bgtype", bgtype);
			if( param != null) so.setProperty( "param", param);
			so.addEventListener( SyncEvent.SYNC, onSync_paintParts);
			
			//SOにアクセス
			so.connect( m_nc);
			
			m_paintParts_soArr.push( so);

		}
		// ペイントパーツが手動で生成or変更or削除された時に呼ばれる
		// SharedObjectを変更させる
		function changePaintPartsSo( e:PaintPartsEvent) {
			// e.paintPartsData の値は、e.typeがPaintPartsEvent.MULTI_CHANGEの場合はPaintPartsの配列、
			// それ以外の場合はPaintPartsDataとなる。
			if( !so_wbNow || so_wbNow.data.hash.bgtype == undefined) {
				//if( Main.DEBUG_ALERT) Main.addErrMsg( "WhiteboardContainer:" + Main.LANG.getParam( "通信エラーにより、ホワイトボードを他の参加者と共有できません"));
				if( Main.DEBUG_ALERT) Main.addErrMsg( "WhiteboardContainer:スライドが削除されたタイミングならOK、それ以外だったら、通信エラー");
				return;
			}

			var so:SharedObject = getPaintPartsSo( so_wbNow.data.hash.bgtype, so_wbNow.data.hash.param);
			if( so.data.ppdArr == undefined) {
				so.data.ppdArr = new Array();
			} else {
			}
			
			var ppdArr:Array = so.data.ppdArr as Array;
			var i:uint;
			switch( e.type) {
				case PaintPartsEvent.ADDED:
					ppdArr.push( e.paintPartsData);
					break;
				case PaintPartsEvent.CHANGED:
					for( i = 0; i < ppdArr.length; i++) {
						if( ppdArr[i].id == e.paintPartsData.id) {
							ppdArr[i] = Object( e.paintPartsData);
							break;
						}
					}
					break;
				case PaintPartsEvent.MULTI_CHANGE:
					// SelectBoxによって一括編集（サイズ・位置変更）された場合
					var ppArr_new = e.paintPartsData as Array;
					if( ppArr_new == null) {
						Main.addErrMsg( "WhiteboardContainer:changePaintPartsSo() MULTI_CHANGE:fatal error");
					}
					for( i = 0; i < ppdArr.length; i++) {
						for each( var pp_new:PaintParts in ppArr_new) {
							 var ppd_new = pp_new.getPaintPartsData();
							 if( ppdArr[i].id == ppd_new.id) {
								 ppdArr[i] = Object( ppd_new);
								 break;
							 }
						 }
					}
					break;
				case PaintPartsEvent.REMOVED:
					
					var now:Number = ( new Date()).getTime();
					for( i = 0; i < ppdArr.length; i++) {
						var ppd = ppdArr[i];
						if( ppd.id == e.paintPartsData.id) {
							ppd.visible = false;
							ppd.lastUpdateTime = now;
						}
					}
					break;
			}
			
			so.data.ppdArr = ppdArr;
			so.setDirty( "ppdArr");
		}
		// ペイントパーツSharedObjectが変更された
		function onSync_paintParts( e:SyncEvent) {
			var so:SharedObject = SharedObject( e.target);
			if( so.data.bgtype == undefined) {
Main.addErrMsg( "WhiteboardContainer:onSync_paintParts() bgtype is undefined.");
				return;
			}
//Main.addDebugMsg( "wbCon onSync_paintParts");					
			
			if( so.data.ppdArr == undefined) return;
			
			var code = "";
			for each( var obj in e.changeList) {
				code = obj.code;
				
				if( code == "success") {
					m_whiteboard.onChangeWbSlidePP();
					// 戻る、進むボタンの再設定
					if( m_whiteboard.getCurrentSlide() != null) {
						m_toolchipBtns.setEnabledBackBtn( WbSlide( m_whiteboard.getCurrentSlide()).canBack());
						m_toolchipBtns.setEnabledRedoBtn( WbSlide( m_whiteboard.getCurrentSlide()).canRedo());
					} else {
						m_toolchipBtns.setEnabledBackBtn( false);
						m_toolchipBtns.setEnabledRedoBtn( false);
					}
				} else if( code == "change")  {
					if( !so.data.ppdArr || so.data.ppdArr.length == 0) {
						// ペイントパーツはまだ未登録、もしくはスライド削除によっていったん空になった状態なので
						// スライド削除時にペイントパーツ配列から削除されているはずなので、
						// m_whiteboardのペイントパーツの変更は行わなくて大丈夫
					} else {
						m_whiteboard.setPaintParts( so.data.bgtype, so.data.param != undefined ? so.data.param : null, so.data.ppdArr);
					}
				}
			}
		}
		
		function getPaintPartsSo( bgtype:String, param) : SharedObject {
			for each( var so:SharedObject in m_paintParts_soArr) {
				if( so.data.bgtype == bgtype) {
					if( bgtype == BGTYPE_PLAIN) {
						return so;
						break;
					} else if( so.data.param != undefined && String( so.data.param) == String( param)) {
						return so;
						break;
					}
				}
			}
			return null;
		}
		
		// ツールチップコンテナのclearボタンがクリックされた
		function clearAllPaintParts( e:Event) {
			if( WB_AUTHORIZED) {
				if( so_wbNow && so_wbNow.data.hash.bgtype != undefined) {
					var bgtype = so_wbNow.data.hash.bgtype;
					var param:String = so_wbNow.data.hash.param as String;
									
					// ペイントパーツの共有オブジェクトの設定を変更
					var so:SharedObject = getPaintPartsSo( bgtype, param);
					if( so.data.ppdArr == undefined) return;
					var ppdArr:Array = so.data.ppdArr;
					for each( var ppd in so.data.ppdArr) {
						if( ppd.visible) {
							ppd.visible = false;
							ppd.lastUpdateTime = ( new Date()).getTime();
						}
					}
					so.setDirty( "ppdArr");
					
					// ホワイトボード書き込みを削除する
					m_whiteboard.clearAllPaintParts();
				}
			} else {
				// ローカルのホワイトボード書き込みを削除する
				m_whiteboard.clearAllPaintParts_local();
			}
			
		}
		// ツールチップコンテナのbackボタンがクリックされた
		function clearLastPaintParts( e:Event) {
			m_whiteboard.clearLastPaintParts();
		}
		// ツールチップコンテナのredoボタンがクリックされた
		function redoClearedPaintParts( e:Event) {
			m_whiteboard.redoClearedPaintParts();
		}
		
		public function getLeftCon() : PartitionContainer { return m_leftCon;}
		public function getImgdocWin() : ImgdocWindow { return m_imgdocWin;}
		public function getBgSelector() { return m_bgSelector;}
		public function getIconAuthority() { return m_iconAuthority;}// 受講生の場合呼ばれる
		public function getToolchipBtns() { return m_toolchipBtns;}
		public function getBgtype() :String {
			if( m_whiteboard.getCurrentSlide() == null) return "";
			else return WbSlide( m_whiteboard.getCurrentSlide()).getBgtype();
		}
						
		public function setEnabled( b:Boolean):void {
			m_toolchipCon.setEnabled( b);
			m_imgdocCon.setEnabled( b);
			m_whiteboard.setEnabled( b);
			m_toolchipBtns.setEnabled( b);
			m_bgSelector.setEnabled( b);
			if( b) {
				m_imgdocCon.addEventListener( DocEvent.SELECTED, onChangeImgdoc);
				m_imgdocCon.addEventListener( DocEvent.REMOVED, onDocRemoved);
				m_imgdocCon.addEventListener( PreMultiDocRemoveEvent.REMOVED, preMultiDocRemove);
				m_bgSelector.addEventListener( BgSelectorEvent.SELECTED, onBgSelected);
			} else {
				m_imgdocCon.removeEventListener( DocEvent.SELECTED, onChangeImgdoc);
				m_imgdocCon.removeEventListener( DocEvent.REMOVED, onDocRemoved);
				m_imgdocCon.removeEventListener( PreMultiDocRemoveEvent.REMOVED, preMultiDocRemove);
				m_bgSelector.removeEventListener( BgSelectorEvent.SELECTED, onBgSelected);
			}
		}
		
		// サムネイルがクリックされた
		function onChangeImgdoc( e:DocEvent) {
			
			// 共有オブジェクトを変更してFMS経由でセッティング
			setSo_wbNow( BGTYPE_IMG, e.doc.getId());
		}
		
		// 背景ラジオボタン（若しくは画像のプルダウン）が変更された
		function onBgSelected( e:BgSelectorEvent) {
			setSo_wbNow( e.bgtype, e.imgpath_or_cameraid_or_color);
		}
		// 資料がまとめて削除された（複数選択での削除orフォルダごと削除）
		public function preMultiDocRemove( e:PreMultiDocRemoveEvent) {				
			
			// 共有オブジェクト so_slideListから削除
			//
			var objArr_new:Array = new Array();
			if( so_slideList != null && so_slideList.data.objArr != undefined) {
				var objArr:Array = so_slideList.data.objArr as Array;
			
				for ( var i = 0; i < objArr.length; i++) {
					var obj:Object = objArr[i];
					var removed:Boolean = false;
					for each( var removedDocId:String in e.removingDocIdArr) {
						if( obj.bgtype == BGTYPE_IMG && obj.param == removedDocId) {
							removed = true;
							break;
						}
					}
					if( !removed) objArr_new.push( obj);
				}
			
				so_slideList.data.objArr = objArr_new;
				so_slideList.setDirty( "objArr");

			}
			
		}

		// 資料が削除された
		function onDocRemoved( e:DocEvent) {
			var removedDoc:Doc = e.doc;
			
			// 現在表示中だったら、ホワイトボードの資料を無選択にする
			var imgWbSlide:ImgWbSlide = m_whiteboard.getCurrentSlide() as ImgWbSlide;
			if( imgWbSlide != null && imgWbSlide.getDocId() == removedDoc.getId()) {
				setSo_wbNow( BGTYPE_PLAIN, "");
				// 資料名を空欄にする
				m_bgSelector.clearDocName();
			}
			
			
			// 背景セレクタのDocStepperの戻る進むボタンのenableを更新
			if( m_bgSelector.getDocId() != "") {
				// 実際に背景として表示されていないとしても、DocStepperに資料名が入っていたら
				var selectedDoc:Doc = m_imgdocCon.getDocById( m_bgSelector.getDocId());
				if( selectedDoc != null) m_bgSelector.setSelectorDocStepper( selectedDoc.getName(), m_imgdocCon.existPrevDoc( selectedDoc), m_imgdocCon.existNextDoc( selectedDoc));
			}

			
			// スライド削除
			m_whiteboard.removeImgSlide( removedDoc.getId());
			
			// 共有オブジェクト so_slideListからも削除
			// （もしもこのremovedDocがピンで削除されたのではなくフォルダごともしくは複数選択で削除されていた場合は
			//   すでにpreMultiDocRemove()によってso_slideListからは削除されている）
			var removed:Boolean = false;
			var objArr_new:Array = new Array();
			if( so_slideList != null && so_slideList.data.objArr != undefined) {
				var objArr:Array = so_slideList.data.objArr as Array;
			
				for ( var i = 0; i < objArr.length; i++) {
					var obj:Object = objArr[i];
					if( obj.bgtype == BGTYPE_IMG && obj.param == removedDoc.getId()) {
						//objArr.splice( i, 1);
						removed = true;
					} else {
						objArr_new.push( obj);
					}
				}
			
				if( removed) {
					so_slideList.data.objArr = objArr_new;
					so_slideList.setDirty( "objArr");
					
				} else {
				}
				

				// 資料が空になった場合はBgSelectorの資料ラジオボタンを選択不可にする
				var img_exist:Boolean = false;
				for each( obj in objArr_new) {
					if( obj.bgtype == BGTYPE_IMG) img_exist = true;
				}
				if( !img_exist) {
					// 資料名を空欄にする
					m_bgSelector.clearDocName();
					m_bgSelector.setEnabledRadioImg( false);
				}
			}
			
		}
		
		function setSo_wbNow( _bgtype:String, docid_or_cameraid_or_color) {
			if( so_wbNow) {
				if( so_wbNow.data.hash && so_wbNow.data.hash.bgtype == _bgtype && so_wbNow.data.hash.param == docid_or_cameraid_or_color) {
					// 自分自身によってこの関数が呼ばれてso_wbNowが変更され、onSyncでcode==successだったけどこの関数がまた呼ばれた場合
					return;
				}
				so_wbNow.data.hash = { bgtype:_bgtype, param:docid_or_cameraid_or_color};
				so_wbNow.setDirty( "hash");
			} else {
				Main.addErrMsg( Main.LANG.getParam( "通信エラーにより、変更を反映できませんでした") + " so_wbNow:" + so_wbNow);
			}
			
			// 講師画面にて、カメラ背景が選択されたとき
			if( _bgtype == WhiteboardContainer.BGTYPE_CAMERA && Main.CONF.isPro( Main.CONF.UID)) {
				// もし講師カメラがOFFの状態だとWB映像も映らなくなってしまうので、
				dispatchEvent( new Event( FORCE_CAMERA_ON));
			}
			
			// WB画面にて
			if( Main.CONF.getWhiteboardUID() == Main.CONF.UID) {
				// 、カメラ背景が選択されたとき
				if( _bgtype == WhiteboardContainer.BGTYPE_CAMERA) {
					// 配信開始
					m_wbVideo.startPublish();
				} else {
					// 配信中止
					m_wbVideo.stopPublish();
				}
			}
		}
		
		// ToolchipContainerの拡大縮小率のコンボボックスの値を変更する
		function changeScaleCombo( e:Event) {
			var scale:Number = m_whiteboard.getScale(); // 実際のスケールを取得
			if( scale <= 0) return;
			
			m_toolchipCon.setScaleCombo( scale);
			m_toolchipBtns.setScaleCombo( ( scale * 100).toString() + "%");
						
			if( m_syncScrollScale && WhiteboardContainer.WB_AUTHORIZED) {
				// 同期モードで、かつWB編集権減をもっている場合
				so_scrollScale.setProperty( "scale", scale);
			}
		}
		
		// コンボボックスで拡大縮小されたのをリッスンして呼ばれる
		// 実際のスケールを変更する
		function setSlideScale( e:ScaleComboEvent) {
			m_whiteboard.setScale( e.scale);
			
			if( m_syncScrollScale && WhiteboardContainer.WB_AUTHORIZED) {
				// 同期モードで、かつWB編集権減をもっている場合
				so_scrollScale.setProperty( "scale", e.scale);
			}
		}
				
		// Mainから、ネットコネクションが切れたときに呼ばれる。
		public function resetNetStream() {
			// 次にinitSoが再度呼ばれたときに、NetStreamを新たに生成するために、nullに戻しておく。
			while( m_ns_arr.length) {
				var ns:MyNetStream = m_ns_arr.pop();
				if( ns) ns.close();
				ns = null;
			}
			
			m_whiteboard.resetNetStream();
		}
		
		public function setCamSlideNs( cameraid:String, uid) :void /*MyNetStream*/ {
			if( uid != null) {
				// 既に対象uidの受信ストリームを生成済みかチェック
				var ns:MyNetStream;
				for each( ns in m_ns_arr) {
					if( ns.getId() == uid) {
						// 生成済み
						m_whiteboard.setCamSlideNs( cameraid, ns);
						//return ns;
						return;
					}
				}
				// 未生成だったので生成する
Main.addDebugMsg(uid + " 未生成だったので生成");
				ns = new MyNetStream( m_nc, uid);
				m_whiteboard.setCamSlideNs( cameraid, ns);
				m_ns_arr.push( ns);
				//return ns;
				return;
			} else { 
				m_whiteboard.setCamSlideNs( cameraid, null);
				//return null;
				return;
			}
		}
		
		// LiveStatusManagerから呼ばれる。
		public function changeJoinStatus( uid:String, flag:Boolean) {
			m_whiteboard.changeJoinStatus( uid, flag);
		}
		public function fitContentsViewSize():void {
			var w = getViewWidth();
			var h = getViewHeight();
			m_whiteboard.setViewWidth( w - m_toolchipCon.getViewWidth() - 10);
			m_whiteboard.setViewHeight( h);
			m_imgdocWin.setViewWidth( m_toolchipCon.getViewWidth());
			m_leftCon.setViewHeight( h);
			m_imgdocWin.setViewHeight( h - m_toolchipCon.getViewHeight() - Partition.W);
		}
		
		override public function setViewWidth( w:Number, debug:String = ""):void {
			if( w < MIN_W) w = MIN_W;
			super.setViewWidth( w);
			fitContentsViewSize();
		}
		override public function setViewHeight( h:Number):void {
			if( h < MIN_H) h = MIN_H;
			super.setViewHeight( h);
			fitContentsViewSize();
		}
				
	}
}