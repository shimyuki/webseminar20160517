package window.whiteboard.toolchip {
	import flash.display.*;
	import flash.geom.*;
	import flash.net.*;
	import window.*;
	import window.whiteboard.*;
	import common.*;
	import flash.events.MouseEvent;
	import flash.events.Event;
	import fl.controls.ComboBox;
	import fl.events.*;
	import common.AlertManager;
	import caurina.transitions.*;
	
	// タイトルバーコンテンツ
	public class ToolchipBtns extends TitleBarContents {
		
		private const READ_DOC = Main.LANG.getParam( "資料閲覧");
		static public const SIMPLE_TOOLMODEDETAIL_CHANGE = "SIMPLE_TOOLMODEDETAIL_CHANGE";
		
		private const SCALE_COMBO_WIDTH = 60;
		// 拡大縮小のCombobox
		protected var m_scaleCombo:ComboBox;

		private var m_arrowBtn:ToolchipBtn;
		private var m_pencilBtn:ToolchipBtn;
		private var m_smoothBtn:ToolchipBtn;
		private var m_zoomBtn:ToolchipBtn;
		private var m_lineBtn:ToolchipBtn;
		private var m_shapeBtn:ToolchipBtn;
		private var m_textBtn:ToolchipBtn;
		private var m_eraserBtn:ToolchipBtn;
		
		private var m_btnArr:Array;
		
		private var m_clearBtn:IconPartsBtn;
		private var m_backBtn:IconPartsBtn;
		private var m_redoBtn:IconPartsBtn;
		private var m_capBtn:IconPartsBtn;
		private var m_readBtn:DynamicTextBtn;
		
		// 各ペイントツールの簡易のSimpleToolModeDetail表示用コンテナ
		private var m_rightwardCon:Sprite;
		private var m_rightwardCon_tx:Number;
		
		// 各ペイントツールのSimpleToolModeDetailの連想配列
		private var m_toolModeDetailHash:Object;
		private var m_tool_name:String;
		
						
		public function ToolchipBtns() {
			super();
			
			m_scaleCombo = ComboBox( new ComboBox());
			m_scaleCombo.editable = false;
			m_scaleCombo.restrict = "0-9%";
			m_scaleCombo.addItem( { label:"300%", data:3.0});
			m_scaleCombo.addItem( { label:"200%", data:2.0});
			m_scaleCombo.addItem( { label:"150%", data:1.5});
			var defaultObj ={ label:"100%", data:1.0};
			m_scaleCombo.addItem( defaultObj);
			m_scaleCombo.addItem( { label:"80%", data:0.8});
			m_scaleCombo.addItem( { label:"60%", data:0.6});
			m_scaleCombo.addItem( { label:"40%", data:0.4});
			m_scaleCombo.addItem( { label:"20%", data:0.2});
			m_scaleCombo.setSize( SCALE_COMBO_WIDTH, 25);
			m_scaleCombo.selectedItem = defaultObj;
			super.addContents( m_scaleCombo);
			
			// WbSlideのonEnterFrame()のカーソル切り替え表示時に通常のカーソルがでるように
			m_scaleCombo.dropdown.addEventListener( MouseEvent.ROLL_OUT , onItemRollOut);
			m_scaleCombo.dropdown.addEventListener( MouseEvent.ROLL_OVER , onItemRollOver);
			
			m_scaleCombo.addEventListener( ComponentEvent.ENTER,
					function( e:*){
						
						if( m_scaleCombo.value.lastIndexOf( '%') >= 0) {
							var myPattern:RegExp = /%/g;
							m_scaleCombo.text = m_scaleCombo.value.replace( myPattern, "");
						}
						var num100:Number = Number( m_scaleCombo.text);
						var num:Number = num100 / 100;
						m_scaleCombo.text = String( num100) + "%";
						
						dispatchEvent( new ScaleComboEvent( ScaleComboEvent.CHANGED, WhiteboardContainer.TOOL_ZOOMIN, num));
					});
			m_scaleCombo.addEventListener( Event.CHANGE,
					function( e:*){
						if( ! m_scaleCombo.selectedItem.data) return;
						dispatchEvent( new ScaleComboEvent( ScaleComboEvent.CHANGED, WhiteboardContainer.TOOL_ZOOMIN, m_scaleCombo.selectedItem.data));
					});

			
			m_btnArr = new Array();
			
			// ペイントツールきりかえのボタン生成
			m_arrowBtn = addBtn( new ToolchipBtn( new IconArrow(), new IconArrow(), WhiteboardContainer.TOOL_ARROW), SCALE_COMBO_WIDTH + 5);
			m_pencilBtn = addBtn( new ToolchipBtn( new IconPencil(), new IconPencil(), WhiteboardContainer.TOOL_PENCIL), m_arrowBtn.x + m_arrowBtn.width + 5);
			m_pencilBtn.addIcon( new IconSmooth(), new IconSmooth(), WhiteboardContainer.TOOL_SMOOTH);
			//m_zoomBtn = addBtn( new ToolchipBtn( new IconGlassPlus(), new IconGlassPlus(), WhiteboardContainer.TOOL_ZOOMIN));
			//m_zoomBtn.addIcon( new IconGlassMinus(), new IconGlassMinus(), WhiteboardContainer.TOOL_ZOOMOUT);
			m_lineBtn = addBtn( new ToolchipBtn( new IconLine(), new IconLine(), WhiteboardContainer.TOOL_LINE));
			m_shapeBtn = addBtn( new ToolchipBtn( new IconSquare(), new IconSquare(), WhiteboardContainer.TOOL_SQUARE));
			m_shapeBtn.addIcon( new IconCircle(), new IconCircle(), WhiteboardContainer.TOOL_CIRCLE);
			m_textBtn = addBtn( new ToolchipBtn( new IconT(), new IconT(), WhiteboardContainer.TOOL_TEXT));
			m_eraserBtn = addBtn( new ToolchipBtn( new IconEraser(), new IconEraser(), WhiteboardContainer.TOOL_ERASER));
			
			// 戻るボタン
			m_backBtn = new IconPartsBtn( new IconBack(), 25, 25);
			super.addContents( m_backBtn);
			m_backBtn.addEventListener( MouseEvent.CLICK, function (e:*) { dispatchEvent( new Event( "back"))});
			
			// 全て削除のボタン
			//m_clearBtn = new DynamicTextBtn( "clear", 11, 25);
			m_clearBtn = new IconPartsBtn( new IconBackAll(), 25, 25);
			super.addContents( m_clearBtn);
			m_clearBtn.addEventListener( MouseEvent.CLICK,
				function (e:*) {
					var msg:String = WhiteboardContainer.WB_AUTHORIZED ? Main.LANG.getParam( "共有描画をすべて削除します") : Main.LANG.getParam( "共有描画以外の描画をすべて削除します");
					if( ExternalInterface.available) {
						var ret = ExternalInterface.call( "flashFunc_comfirm", msg);
						if( ret) dispatchEvent( new Event( "clear"));
					} else {
						dispatchEvent( new Event( "clear"));
					}
					
				});
			
			// やり直しボタン
			m_redoBtn = new IconPartsBtn( new IconRedo(), 25, 25);
			super.addContents( m_redoBtn);
			m_redoBtn.addEventListener( MouseEvent.CLICK, function (e:*) { dispatchEvent( new Event( "redo"))});
			
			// キャプチャボタン
			m_capBtn = new IconPartsBtn( new IconCamera(), 28, 25);
			super.addContents( m_capBtn);
			m_capBtn.addEventListener( MouseEvent.CLICK, function (e:*) { dispatchEvent( new Event( "capture"))});
			
			// 資料閲覧ボタン
			m_readBtn = new DynamicTextBtn( READ_DOC, 11, 25);
			if( Main.CONF.isStudent( Main.CONF.UID)) {
				super.addContents( m_readBtn);
				m_readBtn.addEventListener( MouseEvent.CLICK, onClickReadDoc);
				m_readBtn.visible = false;
			}
			
			// 押されたボタンより右側にあるボタンを右にスライドさせるため一時的に載せるコンテナ
			m_rightwardCon = Sprite( addChild( new Sprite())); 
			
			// 簡易ツールモードのデフォルト設定
			m_toolModeDetailHash = new Object();
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_ARROW] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_ARROW);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_PENCIL] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_PENCIL);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_SMOOTH] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_SMOOTH);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_LINE] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_LINE);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_SQUARE] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_SQUARE);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_CIRCLE] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_CIRCLE);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_TEXT] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_TEXT);
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_ERASER] = new SimpleToolModeDetail( WhiteboardContainer.TOOL_ERASER);
			
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_ARROW].x = m_arrowBtn.x + m_arrowBtn.width + 5;
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_PENCIL].x =
				m_toolModeDetailHash[ WhiteboardContainer.TOOL_SMOOTH].x = m_pencilBtn.x + m_pencilBtn.width + 5;
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_LINE].x = m_lineBtn.x + m_lineBtn.width + 5;
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_SQUARE].x =
				m_toolModeDetailHash[ WhiteboardContainer.TOOL_CIRCLE].x = m_shapeBtn.x + m_shapeBtn.width + 5;
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_TEXT].x = m_textBtn.x + m_textBtn.width + 5;
			m_toolModeDetailHash[ WhiteboardContainer.TOOL_ERASER].x = m_eraserBtn.x + m_eraserBtn.width + 5;
			
			for each( var toolModeDetail in m_toolModeDetailHash) {
				toolModeDetail.addEventListener( SimpleToolModeDetail.CHANGE,
					function( e:*){ dispatchEvent( new Event( SIMPLE_TOOLMODEDETAIL_CHANGE))});
			}
		}
		
		// 初期化時にWhiteBoardContainerから呼ばれる
		public function initSimpleToolModeDetail( toolModeDetail:ToolModeDetail) {
			SimpleToolModeDetail( m_toolModeDetailHash[ toolModeDetail.tool_name]).init( toolModeDetail);
			//SimpleToolModeDetail( m_toolModeDetailHash[ tool_name]).apply( toolModeDetail);
		}
		// ToolchipContainerの変更時にWhiteBoardContainerから呼ばれる
		public function applySimpleToolModeDetail( toolModeDetail:ToolModeDetail) {
			SimpleToolModeDetail( m_toolModeDetailHash[ toolModeDetail.tool_name]).apply( toolModeDetail);
		}
		
		// スケールSO変更時にWhiteboardContainer:onSyncScrollScale()から呼ばれる
		public function setScaleCombo( scale_str:String) {
			for( var i = 0; i < m_scaleCombo.length; i++) {
				var item = m_scaleCombo.getItemAt( i);
				if( item.label == scale_str) {
					m_scaleCombo.selectedIndex = i;
					break;
				}
			}
		}
		
		// WhiteboardWindowから呼ばれる、ホワイトボード書き込み権限を与えるか否かの設定。
		// 講師が共有オブジェクトを変更することによって、この関数が生徒側で実行される
		public function setAuthority( b:Boolean) {
			
			SimpleToolModeDetail( m_toolModeDetailHash[ WhiteboardContainer.TOOL_ARROW]).setAuthority( b);
			
// 権限がなくてもマイホワイトボード（共有モードOFF）として使うことになったから、ここでリターン
return;

			if( ! Main.CONF.isStudent( Main.CONF.UID)) return;
			closeDetail();
			
			if( b) {
				
				while( numChildren) removeChildAt( 0);
				super.addContents( m_scaleCombo);
				super.addContents( m_arrowBtn, SCALE_COMBO_WIDTH + 5);
				super.addContents( m_pencilBtn, m_arrowBtn.x + m_arrowBtn.width + 5);
				//super.addContents( m_zoomBtn);
				super.addContents( m_lineBtn);
				super.addContents( m_shapeBtn);
				super.addContents( m_textBtn);
				super.addContents( m_eraserBtn);
				super.addContents( m_clearBtn);
				super.addContents( m_backBtn);
				super.addContents( m_redoBtn);
				
				if( ! Main.CONF.isStudent( Main.CONF.UID)) {
					// 講師orWBユーザの場合
					super.addContents( m_capBtn);
				} else {
					// 受講生の場合
					// キャプチャは無しで、資料閲覧ボタンはあり（最初は一応visible=falseだけど）
					super.addContents( m_readBtn);
				}
				
			} else {
				while( numChildren) removeChildAt( 0);
				super.addContents( m_scaleCombo);
				//super.addContents( m_zoomBtn);
				if( Main.CONF.isStudent( Main.CONF.UID)) super.addContents( m_readBtn);
				m_arrowBtn.dispatchEvent( new ToolchipEvent( ToolchipEvent.SELECTED, WhiteboardContainer.TOOL_ARROW));
			}
			
			if( m_toolModeDetailHash[ WhiteboardContainer.TOOL_ARROW] != undefined)
				m_toolModeDetailHash[ WhiteboardContainer.TOOL_ARROW].visible = b;
		}
		
		// WhiteboardWindowから呼ばれる、資料閲覧権限を与えるか否かの設定。
		// 講師が共有オブジェクトを変更することによって、この関数が生徒側で実行される
		public function showReadBtn( b:Boolean) {
			m_readBtn.visible = b;
		}
		
		// テキストペイントパーツのダブルクリック時に、
		// WhiteboardContainer:changeTool()から呼ばれる
		public function setTextOn() {
			m_textBtn.setOn();
		}
		
		function addBtn( btn:ToolchipBtn, posiX = null) :ToolchipBtn{
			btn.addEventListener( ToolchipEvent.SELECTED, onSelected);
			btn.addEventListener( ToolchipEvent.SHOW_PANEL, onShowPanel);
			btn.addEventListener( ToolchipEvent.HIDE_PANEL, onHidePanel);
			super.addContents( btn, posiX);
			m_btnArr.push( btn);
			return btn;
		}
		
		// ペイントツールきりかえボタンが押されたとき
		function onSelected( e:ToolchipEvent) {
			for each( var btn:ToolchipBtn in m_btnArr) {
				btn.off();
			}
			var targetBtn:ToolchipBtn = e.target as ToolchipBtn;
			if( targetBtn != null) targetBtn.on();
			dispatchEvent( new ToolchipEvent( e.type, e.tool_name));
			
			// 右側に簡易のSimpleToolModeDetailを表示
			showSimpleToolModeDetail( e.tool_name);
			//if( WhiteboardContainer.WB_AUTHORIZED) showSimpleToolModeDetail( e.tool_name);
		}
		// 右側のボタンたちが全体にスライドして、できた隙間にSimpleToolModeDetailを表示
		function showSimpleToolModeDetail( tool_name:String) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", tool_name);
			
			m_tool_name = tool_name;
			
			closeDetail();
			
			var targetBtn = null;
			switch( tool_name) {
				case WhiteboardContainer.TOOL_ARROW:	targetBtn = m_arrowBtn;	break;
				case WhiteboardContainer.TOOL_PENCIL:	targetBtn = m_pencilBtn;	break;
				case WhiteboardContainer.TOOL_SMOOTH:	targetBtn = m_pencilBtn;	break;
				case WhiteboardContainer.TOOL_LINE:		targetBtn = m_lineBtn;	break;
				case WhiteboardContainer.TOOL_SQUARE:	targetBtn = m_shapeBtn;	break;
				case WhiteboardContainer.TOOL_CIRCLE:	targetBtn = m_shapeBtn;	break;
				case WhiteboardContainer.TOOL_TEXT:		targetBtn = m_textBtn;	break;
				case WhiteboardContainer.TOOL_ERASER:	targetBtn = m_eraserBtn;	break;
				default: break;
			}
			
			if( targetBtn != null) {
				// 押されたボタンより右側にあるやつを全部一時コンテナに載せてtweenerで動かす
				for( var i:uint = 0; i < numChildren; i++) {
					var child = getChildAt( i);
					if( child.x > targetBtn.x && child != m_rightwardCon) {
						m_rightwardCon.addChild( child);
						i--;
					}
				}
				if( ! contains( m_rightwardCon)) addChild( m_rightwardCon);
				if( m_toolModeDetailHash[ tool_name] != undefined) m_rightwardCon_tx = m_toolModeDetailHash[ tool_name].getViewWidth();
				Tweener.addTween( m_rightwardCon, { x:m_rightwardCon_tx, time:0.25,
								 onComplete:		onCompleteRightward,
								 onCompleteParams:	[tool_name]
								 });
				
			}
			
			
		}
		function closeDetail() {
			// 一時コンテナの位置をゼロに戻す
			Tweener.removeTweens( m_rightwardCon);
			m_rightwardCon.x = 0;
			
			for each( var simpleToolModeDetail in m_toolModeDetailHash) {
				if( contains( simpleToolModeDetail)) removeChild( simpleToolModeDetail);
			}
			
			// 一時コンテナに載っているボタンたちをおろす
			while( m_rightwardCon.numChildren) {
				var child = m_rightwardCon.removeChildAt( 0);
				addChild( child);
			}
		}
		
		protected function onCompleteRightward( tool_name:String) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert","onCompleteRightward:" +  tool_name);
			// 各ペイントツールの簡易のSimpleToolModeDetailを表示
			
			addChild( m_toolModeDetailHash[ tool_name]);
		}
		
		public function getCurrentToolMode() : SimpleToolModeDetail {
			return m_toolModeDetailHash[ m_tool_name];
		}
		
		function onShowPanel( e:ToolchipEvent) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = true;
			//TitleBarのm_leftCon_1stとして、TitleBarにm_draggableをfalseに設定させる
			dispatchEvent( new ToolchipEvent( e.type, "", e.panel, e.targetBtnX, e.targetBtnY));
		}
		function onHidePanel( e:ToolchipEvent) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = false;
			//TitleBarのm_leftCon_1stとして、TitleBarにm_draggableをtrueに設定させる
			dispatchEvent( new ToolchipEvent( e.type, "", e.panel));
		}
		function onItemRollOut( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = false;
		}
		function onItemRollOver( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = true;
		}
		
		public function setEnabledBackBtn( b:Boolean) {
			m_backBtn.setEnabled( b);
			m_clearBtn.setEnabled( b);
		}
		public function setEnabledRedoBtn( b:Boolean) {
			m_redoBtn.setEnabled( b);
		}
		public function setEnabled( b:Boolean) {
			for each( var btn:ToolchipBtn in m_btnArr) {
				btn.setEnabled( b);
			}
			m_clearBtn.setEnabled( b);
			m_backBtn.setEnabled( b);
			m_redoBtn.setEnabled( b);
			m_capBtn.setEnabled( b);
			m_readBtn.setEnabled( b);
			
			if( b) {
				m_arrowBtn.setOn();
			}
		}
		
		// WhiteboardContainerから呼ばれる。
		// 画面モードが同期モードの場合にスケールの変更をできなくするため
		public function setSyncMode( b:Boolean) {
			//m_zoomBtn.visible = !b;
			//m_scaleCombo.editable = !b;
			m_scaleCombo.enabled = !b;
			m_arrowBtn.dispatchEvent( new ToolchipEvent( ToolchipEvent.SELECTED, WhiteboardContainer.TOOL_ARROW));
		}
		function alertDialog( str) {
			if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "ToolchipBtns: " + String( str));
		}

		function onClickReadDoc( e:MouseEvent) {
			if( ExternalInterface.available) ExternalInterface.call( "flashFunc_popupDocList", Main.CONF.CLASS_ID, Main.CONF.UID, Main.CONF.getParam( "CLASS_TITLE"));
		}
	}
}