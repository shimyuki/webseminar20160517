package window.whiteboard {
	import fl.controls.RadioButton;
	import fl.controls.ComboBox;
	import fl.events.*;
	import flash.display.*;
	import flash.geom.*;
	import flash.net.SharedObject;
	import common.*;
	import window.*;
	import window.whiteboard.*;
	import window.whiteboard.imgdoc.*;
	import flash.text.*;
	import flash.events.*;
	import common.AlertManager;
	import flash.utils.unescapeMultiByte;
	import caurina.transitions.*;
	import window.header.HeaderEvent;
	import partition.Layout;

	// 背景を資料、カメラ映像、無地から選択する用
	public class BgSelector extends Sprite {
		static public const POPUP_CLICKED = "POPUP_CLICKED";
		
		// CamWbSlideとBgSelector_lecからも参照してる。
		static public const LAB_CHANGE:String = Main.LANG.getParam( "変更");
		static public const STREAM:Array = [{ camerawidth:480, cameraheight:360, bandwidth:150000, fps:12},
											{ camerawidth:760, cameraheight:570, bandwidth:150000, fps:5},
											{ camerawidth:800, cameraheight:600, bandwidth:150000, fps:5}];
		protected var so_wb:SharedObject = null;
		
		protected var m_radioImg:RadioButton;
		//protected var m_comboImg:ComboBox;
		protected var m_docName:TextField;
		protected var m_docId:String = ""; // 画像背景m_docNameに対応するDOCのID
		protected var m_docBtn:DynamicTextBtn;
		protected var m_radioCam:RadioButton;
		protected var m_radioPlain:RadioButton;
		protected var m_radioImgClickarea:Sprite = null; // enabled==falseのラジオボタンでもクリック開閉のためのクリックを受け付けたいので。
		
		protected const W_COMBO = 80;
		protected const W_TEXT = 50;
		private const MAX_W_COMBO_DROP_IMG = 210;
		 
		public function BgSelector() {
			var rect:Rectangle;
			var tf:TextFormat = new TextFormat( Main.CONF.getMainFont(), 9, 0x000000, null, null, null, null, null, null, -2);
			
			m_radioImg = RadioButton( addChild( new RadioButton()));
			m_radioImg.textField.defaultTextFormat = tf;
			m_radioImg.textField.autoSize = TextFieldAutoSize.LEFT;
			m_radioImg.label = WhiteboardContainer.BGTYPE_IMG;
			m_radioImg.x = 0;
			m_radioImg.y = ( TitleBar.H - m_radioImg.height) / 2;
			setEnabledRadioImg( false);
			
			m_docName = TextField( addChild( new TextField()));
			var tf2:TextFormat = new TextFormat( Main.CONF.getMainFont(), 12, 0x000000);
			tf2.leftMargin = 1;
			m_docName.defaultTextFormat = tf2;
			m_docName.text = "---";
			m_docName.width = W_TEXT;
			m_docName.height = 20;
			m_docName.background = true;
			m_docName.border = true;
			m_docName.backgroundColor = 0xffffff;
			m_docName.borderColor = 0xd9d9d9;
			m_docName.x = m_radioImg.x + 30 + m_radioImg.textField.width; // 適当
			
			//m_docBtn = DynamicTextBtn( addChild( new DynamicTextBtn( LAB_CHANGE, 9, 25, 3, 5)));
			m_docBtn = DynamicTextBtn( addChild( new DynamicTextBtn( LAB_CHANGE, 10, m_docName.height, 2, 4)));
			m_docBtn.x = m_docName.x + m_docName.width + 3; // 適当
			m_docBtn.y = ( TitleBar.H - m_docBtn.height) / 2;
			m_docBtn.setEnabled( true);
			m_docBtn.addEventListener( MouseEvent.CLICK,
					function( e:*) { dispatchEvent( new HeaderEvent( POPUP_CLICKED, Layout.SUB_WINNAME_WHITEBOARD_IMGDOC));});
			
			m_docName.y = m_docBtn.y - 0.5;
			
/*			m_comboImg = ComboBox( addChild( new ComboBox()));
			m_comboImg.width = 80;
			m_comboImg.x = m_radioImg.x + 30 + m_radioImg.textField.width; // 適当
			m_comboImg.y = ( TitleBar.H - m_comboImg.height) / 2;
			m_comboImg.enabled = false;
*/			
			m_radioCam = RadioButton( addChild( new RadioButton()));
			m_radioCam.textField.defaultTextFormat = tf;
			m_radioCam.textField.autoSize = TextFieldAutoSize.LEFT;
			m_radioCam.label = WhiteboardContainer.BGTYPE_CAMERA.replace( /カメラ/, '');
			m_radioCam.x = m_docBtn.x + m_docBtn.width + 10; // 適当
			m_radioCam.y = ( TitleBar.H - m_radioCam.height) / 2;
			m_radioCam.enabled = false;
			
			m_radioPlain = RadioButton( addChild( new RadioButton()));
			m_radioPlain.textField.defaultTextFormat = tf;
			m_radioPlain.textField.autoSize = TextFieldAutoSize.LEFT;
			m_radioPlain.label = WhiteboardContainer.BGTYPE_PLAIN;
			m_radioPlain.x = m_radioCam.x + 30 + m_radioCam.textField.width; // 適当
			m_radioPlain.y = ( TitleBar.H - m_radioPlain.height) / 2;
			m_radioPlain.enabled = false;
			
			m_radioImg.addEventListener( Event.CHANGE, onRadioImgChanged); 
			//m_comboImg.addEventListener( MouseEvent.ROLL_OVER, onRollOver_comboImg);
			//m_comboImg.dropdown.addEventListener( MouseEvent.ROLL_OUT , onItemRollOut_combo);
			//m_comboImg.dropdown.addEventListener( MouseEvent.ROLL_OVER , onItemRollOver_combo);
			m_radioCam.addEventListener( Event.CHANGE, onRadioCamChanged);
			m_radioPlain.addEventListener( Event.CHANGE, onRadioPlainChanged);
			
		}
		public function setSoWb( so:SharedObject) {
			so_wb = so;
			so_wb.addEventListener( SyncEvent.SYNC, onSync1st);
		}
		protected function onSync1st( e:SyncEvent) {
		}
		
		protected function onRadioImgChanged( e:Event) {
			if( m_radioImg.selected && m_docId != "") {
				dispatchEvent( new BgSelectorEvent( BgSelectorEvent.SELECTED, WhiteboardContainer.BGTYPE_IMG, m_docId));
			}
		}
		protected function onRadioCamChanged( e:Event) {
			if( m_radioCam.selected) {
				//m_comboImg.enabled = false;
				dispatchEvent( new BgSelectorEvent( BgSelectorEvent.SELECTED, WhiteboardContainer.BGTYPE_CAMERA, "dummy_id"));
			}
		}
		protected function onRadioPlainChanged( e:Event) {
			if( m_radioPlain.selected) {
				//m_comboImg.enabled = false;
				dispatchEvent( new BgSelectorEvent( BgSelectorEvent.SELECTED, WhiteboardContainer.BGTYPE_PLAIN, 0xffffff));
			}
		}
		/*function onRollOver_comboImg( e:*) {
			//WhiteboardContainer.CURSOR_BUSY = true;
			m_comboImg.addEventListener( Event.CHANGE, onComboImgChanged);
		}*/
		function onItemRollOut_combo( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = false;
		}
		function onItemRollOver_combo( e:*) {
			WhiteboardContainer.CURSOR_BUSY = Main.DROP_OPENED = true;
		}
		
		
		/*function onComboImgChanged( e:Event) {
			if( m_radioImg.selected) {
				var imgpath:String = "";
				if( m_comboImg.selectedItem != null) {
					imgpath = String( m_comboImg.selectedItem.data);
					dispatchEvent( new BgSelectorEvent( BgSelectorEvent.SELECTED, WhiteboardContainer.BGTYPE_IMG, imgpath));
				}
			}
		}*/
		
		// サムネイル一覧のソートが終わった直後に呼ばれる
		/*public function resortImgCombo() {
			var sortIdIsName:Boolean = true;
			for( var i:uint = 0; i < m_comboImg.length; i++) {
				var obj:Object = Object( m_comboImg.getItemAt( i));
				var thu:Thu = obj.thu as Thu;
				if( thu == null) if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "BgSelector:resortImgCombo():ERROR");
				obj.sortId = thu.sortId;
				if( sortIdIsName && thu.name != String( obj.sortId)) sortIdIsName = false;
			}
			m_comboImg.sortItemsOn( "data");
			if( ! sortIdIsName) m_comboImg.sortItemsOn( "sortId", Array.NUMERIC);
		}*/
		/*
		function sortThuByName( a:Object, b:Object):Boolean {
			return ( String( a.thu.name).toUpperCase() > String( b.thu.name).toUpperCase());
		}*/
		/*
		function sortThuByNumber( a:Object, b:Object):Boolean {
//if( Thu( a.thu) == null) if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "BgSelector:x");
//else  if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "BgSelector:" + a.thu.sortId);
			if( a.thu.sortId != b.thu.sortId) {
				return ( Number( a.thu.sortId) > Number( b.thu.sortId));
			} else {
				return ( String( a.thu.name) > String( b.thu.name));
			}
		}*/
		
		/*public function addComboItem( thu:Thu) {
			var imgpath = thu.name;
			var lab:String = unescapeMultiByte( imgpath.substring( imgpath.lastIndexOf( "/") + 1));
			m_comboImg.addItem( { label:lab, data:imgpath, thu:thu});
			
			// ドロップダウンリストのテキストの長さに基づいて dropdownWidth プロパティを設定
			resetComboWidth( m_comboImg, MAX_W_COMBO_DROP_IMG);
			
			resortImgCombo();
		}*/
		
		
		function resetComboWidth( combo:ComboBox, max_w:Number) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "a:resetComboWidth");			
			if( combo.length == 0) return;
			// ドロップダウンリストのテキストの長さに基づいて dropdownWidth プロパティを設定
			var tmp = combo.selectedItem; // ちょっととっておく
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", "b:resetComboWidth");			
			var maxLength:Number = 0;
			var i:uint;
			for (i = 0; i < combo.length; i++) {
				combo.selectedIndex = i;
				combo.drawNow();
				var currText:String = combo.text;
				var currWidth:Number = combo.textField.textWidth;
				maxLength = Math.max( currWidth, maxLength);
			}
			combo.dropdownWidth = maxLength + 30 > max_w ? max_w : maxLength + 30;
			combo.selectedItem = tmp;
		}
		
		public function clearDocName() {
			m_docId = "";
			m_docName.text = "---";
		}
		
		public function setSelector( bgtype:String, param, docname = "") { // overrideされてる
			switch( bgtype) {
				case WhiteboardContainer.BGTYPE_IMG :
					m_docId = param;
					m_docName.text = docname;
					m_radioImg.selected = true;
					break;
				case WhiteboardContainer.BGTYPE_CAMERA :
					// 注）コンボボックスの値を変更した後にラジオボタンの有効を設定すること！
					m_radioCam.selected = true;
					break;
				default :
					m_radioPlain.selected = true;
					break;
			}

		}
		
		public function setEnabledRadioImg( b:Boolean) {
			if( m_radioImgClickarea == null) {
				m_radioImgClickarea = new Sprite();
				m_radioImgClickarea.graphics.beginFill( 0, 0);
				m_radioImgClickarea.graphics.drawRect( 0, 0, m_radioImg.textField.textWidth + 30 /*適当*/, m_radioImg.height);
				m_radioImgClickarea.graphics.endFill();
				m_radioImgClickarea.x = m_radioImg.x;
				m_radioImgClickarea.y = m_radioImg.y;
			}
			if( b) {
				if( contains( m_radioImgClickarea)) removeChild( m_radioImgClickarea);
			} else {
				addChild( m_radioImgClickarea);
			}
			m_radioImg.enabled = b;
		}
		
		public function setEnabled( b:Boolean) {
			//m_radioImg.enabled = b; // 資料が追加されたときに始めてenabledにする（WhiteboardContainer がDocEvent.ADD_DOCをキャッチしたとき）
			m_radioCam.enabled = b;
			m_radioPlain.enabled = b;
		}
		
		function alertDialog( msg) {
			if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", String( msg));
		}
	}
}