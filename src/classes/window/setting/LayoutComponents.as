package window.setting {
	import flash.display.*;
	import fl.controls.RadioButton;
	import fl.controls.ComboBox;
	import fl.events.*;
	import partition.*;
	import common.*;
	import window.*;
	import fl.controls.RadioButtonGroup;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import common.AlertManager;
	
	// 環境設定の画面モード作成／編集（ビュー）用コンポーネントセット
	public class LayoutComponents extends MovieClip {
		public var H:Number = 600;
		static public const SUBMAIN = "SUBMAIN";
		static public const MAINSUB = "MAINSUB";
		static public const FULL = "FULL";
		
		static public const CLICK_SAVE:String = "CLICK_SAVE";
		static public const CLICK_DEL:String = "CLICK_DEL";
		
		// 見出し、ラベル
		private var LABEL_LEC_LAYOUT:String;
		private var LABEL_STU_LAYOUT:String;
		private var LABEL_LEC_POSI:String;
		private var LABEL_STU_POSI:String;
		private var LABEL_ALLLIST:String;
		private var LABEL_PICKUP:String;
		private var LABEL_COLSPAN:String;
		private var LABEL_COLSPAN_UNIT:String;// 1列 2列 3列...
		static public var LABEL_ADD_ROW:String;
		static public var LABEL_REMOVE_CELL:String;
		static public var LABEL_REMOVE_CELL_CAPTION:String;
		static public var LABEL_USE:String;
		static public var LABEL_NOUSE:String;
		
		// エラーメッセージ
		private var ERRMSG_NAMAE:String;
		private var ERRMSG_LEC_LAYOUT:String;
		private var ERRMSG_STU_LAYOUT:String;
		private var ERRMSG_ALLCOL:String;
		private var ERRMSG_PICKUPCOL:String;
		
		// ボタン
		private var LABEL_SAVE:String;
		private var LABEL_CHANGE:String;
		private var LABEL_DEL:String;
		private var m_btnSave:DynamicTextBtn = null;
		private var m_btnChange:DynamicTextBtn = null;
		private var m_btnDel:DynamicTextBtn = null;
		
		// カラムレイアウト選択のラジオボタン
		static public var LABEL_LEFTCOLUM:String;
		static public var LABEL_RIGHTCOLUM:String;
		static public var LABEL_FULLCOLUM:String;
		private var LABEL_SUBMAIN_RADIO:String;
		private var LABEL_MAINSUB_RADIO:String;
		private var m_lecLayoutRadioG:RadioButtonGroup;
		private var m_stuLayoutRadioG:RadioButtonGroup;
		
		// レイアウトを示す、青い四角
		private var m_lecBlueLayoutBox:BlueLayoutBox;
		private var m_stuBlueLayoutBox:BlueLayoutBox;
		
		// コンテンツ配置を示す、コンボボックスのセット
		private var m_lecComboSet:WinComboSet;
		private var m_stuComboSet:WinComboSet;
		
		// メンバー一覧の分割方法選択ラジオボタン
		private const MAX_COLSPAN = 5;
		private var m_alllistColRadioG:RadioButtonGroup;
		private var m_pickupColRadioG:RadioButtonGroup;
		
		// メンバー一覧のレイアウト表示
		private var m_memberListCon:Sprite;
		private var m_pickupCon:Sprite;
		private var m_alllistLayout:MemberListLayout_all;
		private var m_pickupLayout:MemberListLayout_pickup;
		
		// マスク
		private var m_mask:Shape;
		
		private var m_opened:Boolean;
				
		// デフォルトLayout。init()で設定される。isNew==trueの場合はnullのままなのでボタンクリック時に生成される。
		private var m_layout:Layout = null; 

		private var m_clickObj:Sprite = null
		
		public function LayoutComponents( isNew:Boolean = false /*新規作成*/) :void{
			LABEL_LEC_LAYOUT = Main.LANG.getParam( "講師画面レイアウト");
			LABEL_STU_LAYOUT = Main.LANG.getParam( "受講生画面レイアウト");
			LABEL_LEC_POSI = Main.LANG.getParam( "講師画面コンテンツ配置");
			LABEL_STU_POSI = Main.LANG.getParam( "受講生画面コンテンツ配置");
			LABEL_ALLLIST = Main.LANG.getParam( "受講生一覧の映像表示方法（1）全員表示");
			LABEL_PICKUP = Main.LANG.getParam( "受講生一覧の映像表示方法（2）ピックアップ表示");
			LABEL_COLSPAN = Main.LANG.getParam( "分割方法");
			LABEL_COLSPAN_UNIT = Main.LANG.getParam( "列");// 1列 2列 3列...
			LABEL_ADD_ROW = Main.LANG.getParam( "1行追加");
			LABEL_REMOVE_CELL = Main.LANG.getParam( "使用しないブロックを詰める");
			LABEL_REMOVE_CELL_CAPTION = Main.LANG.getParam( "※ 保存時に使用しないブロックは自動で詰められます");
			LABEL_USE = Main.LANG.getParam( "使用する");
			LABEL_NOUSE = Main.LANG.getParam( "使用しない");
			
			// エラーメッセージ
			ERRMSG_NAMAE = Main.LANG.getParam( "画面モード名を入力してください");
			ERRMSG_LEC_LAYOUT = Main.LANG.getParam( "講師画面レイアウト／コンテンツ配置が不正です");
			ERRMSG_STU_LAYOUT = Main.LANG.getParam( "受講生画面レイアウト／コンテンツ配置が不正です");
			ERRMSG_ALLCOL = Main.LANG.getParam( "受講生一覧の映像表示方法（1）全員表示の指定が不正です");
			ERRMSG_PICKUPCOL = Main.LANG.getParam( "受講生一覧の映像表示方法（2）ピックアップ表示の指定が不正です");
			
			// ボタン
			LABEL_SAVE = Main.LANG.getParam( "保存する");
			LABEL_CHANGE = Main.LANG.getParam( "変更を適用する");
			LABEL_DEL = Main.LANG.getParam( "削除");
			
			// カラムレイアウト選択のラジオボタン
			LABEL_LEFTCOLUM = Main.LANG.getParam( "左カラム");
			LABEL_RIGHTCOLUM = Main.LANG.getParam( "右カラム");
			LABEL_FULLCOLUM = Main.LANG.getParam( "フルカラム");
			LABEL_SUBMAIN_RADIO = LABEL_LEFTCOLUM + " < " + LABEL_RIGHTCOLUM;
			LABEL_MAINSUB_RADIO = LABEL_LEFTCOLUM + " > " + LABEL_RIGHTCOLUM;
		
			m_lecLayoutLabel.text = LABEL_LEC_LAYOUT;
			m_stuLayoutLabel.text = LABEL_STU_LAYOUT;
			m_lecPosiLabel.text = LABEL_LEC_LAYOUT;
			m_stuPosiLabel.text = LABEL_STU_LAYOUT;
			m_allListLabel.text = LABEL_ALLLIST;
			m_pickupLabel.text = LABEL_PICKUP;
			
			// レイアウト名のインプットテキスト
			var fmt:TextFormat = new TextFormat( Main.CONF.getMainFont(), 13);
			fmt.leftMargin = 1;
			m_layoutName.multiline = m_layoutName.wordWrap = false;
			m_layoutName.defaultTextFormat = fmt;
			m_layoutName.background = true;
			m_layoutName.border = true;
			m_layoutName.backgroundColor = 0xffffff;
			m_layoutName.borderColor = 0xcccccc;
			
			// レイアウトラジオボタンのラベルとデータ
			m_lecSubMainRadio.label = LABEL_SUBMAIN_RADIO;
			m_lecSubMainRadio.value = SUBMAIN;
			m_lecMainSubRadio.label = LABEL_MAINSUB_RADIO;
			m_lecMainSubRadio.value = MAINSUB;
			m_lecFullRadio.label = LABEL_FULLCOLUM;
			m_lecFullRadio.value = FULL;
			m_stuSubMainRadio.label = LABEL_SUBMAIN_RADIO;
			m_stuSubMainRadio.value = SUBMAIN;
			m_stuMainSubRadio.label = LABEL_MAINSUB_RADIO;
			m_stuMainSubRadio.value = MAINSUB;
			m_stuFullRadio.label = LABEL_FULLCOLUM;
			m_stuFullRadio.value = FULL;
			
			// ラジオボタンのラベルのサイズを文字長さに合わせる
			m_lecSubMainRadio.width = m_lecSubMainRadio.textField.textWidth + 50;
			m_lecMainSubRadio.width = m_lecMainSubRadio.textField.textWidth + 50;
			m_lecFullRadio.width = m_lecFullRadio.textField.textWidth + 50;
			m_stuSubMainRadio.width = m_stuSubMainRadio.textField.textWidth + 50;
			m_stuMainSubRadio.width = m_stuMainSubRadio.textField.textWidth + 50;
			m_stuFullRadio.width = m_stuFullRadio.textField.textWidth + 50;

			// レイアウトラジオボタングループ
			var rand:String = String( Math.random());
			m_lecSubMainRadio.groupName = m_lecMainSubRadio.groupName = m_lecFullRadio.groupName = "lecLayout" + rand;
			m_stuSubMainRadio.groupName = m_stuMainSubRadio.groupName = m_stuFullRadio.groupName = "stuLayout" + rand;
			m_lecLayoutRadioG = m_lecSubMainRadio.group;
			m_stuLayoutRadioG = m_stuSubMainRadio.group;
			// レイアウトラジオボタンが選択されたらの挙動
			m_lecLayoutRadioG.addEventListener( Event.CHANGE, onChangeLecLayout);
			m_stuLayoutRadioG.addEventListener( Event.CHANGE, onChangeStuLayout);
				
			// レイアウトを示す、青い四角の配置
			m_lecBlueLayoutBox = BlueLayoutBox( addChild( new BlueLayoutBox()));
			m_lecBlueLayoutBox.x = m_lecSubMainRadio.x + m_lecSubMainRadio.width + 20;
			m_lecBlueLayoutBox.y = m_lecSubMainRadio.y;
			
			m_stuBlueLayoutBox = BlueLayoutBox( addChild( new BlueLayoutBox()));
			m_stuBlueLayoutBox.x = m_stuSubMainRadio.x + m_stuSubMainRadio.width + 20;
			m_stuBlueLayoutBox.y = m_stuSubMainRadio.y;
			
			// コンテンツ配置のコンボボックスリストの配置
			m_lecComboSet = WinComboSet( addChild( new WinComboSet( true)));
			//m_lecComboSet.initAsPreset( false);
			m_lecComboSet.x = m_lecPosiLabel.x + 5;
			m_lecComboSet.y = m_lecPosiLabel.y + m_lecPosiLabel.height + 10;
			m_lecComboSet.addEventListener( Event.CHANGE, onChangeLecWinCombo);
			
			m_stuComboSet = WinComboSet( addChild( new WinComboSet( false)));
			//m_stuComboSet.initAsPreset( false);
			m_stuComboSet.x = m_stuPosiLabel.x + 5;
			m_stuComboSet.y = m_stuPosiLabel.y + m_stuPosiLabel.height + 10;
			m_stuComboSet.addEventListener( Event.CHANGE, onChangeStuWinCombo);
			
			// 受講生一覧の分割設定のコンテナ
			m_memberListCon = Sprite( addChild( new Sprite()));
			m_memberListCon.addChild( m_allListLabel);
			
			
			// 受講生一覧の映像表示方法（1）全員表示
			// 分割方法のラジオボタン
			var alllistColLab = m_memberListCon.addChild( getLabel( LABEL_COLSPAN)); // ラベル「分割方法」
			alllistColLab.x = m_allListLabel.x + 5;
			alllistColLab.y = m_allListLabel.y + m_allListLabel.height + 8;
			var posi_x = alllistColLab.x + alllistColLab.width + 15;
			var radio:RadioButton;
			for( var i = 0; i < MAX_COLSPAN; i++) {
				radio = RadioButton( m_memberListCon.addChild( new RadioButton()));
				radio.label = String( i+1) + LABEL_COLSPAN_UNIT;
				radio.value = i+1;//{ label:String( i+1) + LABEL_COLSPAN_UNIT, data: i+1};
				radio.groupName = "alllistColRadio" + rand;
				radio.x = posi_x;
				radio.y = alllistColLab.y + ( alllistColLab.height - radio.height) / 2;
				radio.width = radio.textField.textWidth + 35;
				posi_x += radio.width;
				m_alllistColRadioG = radio.group;
			}
			
			m_alllistColRadioG.selection = radio;
			m_alllistColRadioG.addEventListener( Event.CHANGE, onChangeAlllistCol);
			
			// 受講生一覧(全員表示)のレイアウト表示
			m_alllistLayout = MemberListLayout_all( m_memberListCon.addChild( new MemberListLayout_all()));
			m_alllistLayout.x = alllistColLab.x;
			m_alllistLayout.y = alllistColLab.y + alllistColLab.height + 10;
			m_alllistLayout.addEventListener( Event.CHANGE, changeHeight);
			
			
			// 受講生一覧の映像表示方法（2）ピックアップ表示
			m_pickupCon = Sprite( m_memberListCon.addChild( new Sprite()));
			m_pickupCon.y = m_alllistLayout.y + m_alllistLayout.getViewHeight() + 20;
			m_pickupCon.addChild( m_pickupLabel);
			m_pickupLabel.y = 0;
			// 分割方法のラジオボタン
			var pickupColLab = m_pickupCon.addChild( getLabel( LABEL_COLSPAN)); // ラベル「分割方法」
			pickupColLab.x = alllistColLab.x;
			pickupColLab.y = m_pickupLabel.y + m_pickupLabel.height + 8;
			posi_x = pickupColLab.x + pickupColLab.width + 15;
			for( i = 0; i < MAX_COLSPAN; i++) {
				radio = RadioButton( m_pickupCon.addChild( new RadioButton()));
				radio.label = String( i+1) + LABEL_COLSPAN_UNIT;
				radio.value = i+1;//{ label:String( i+1) + LABEL_COLSPAN_UNIT, data: i+1};
				radio.groupName = "pickupColLab" + rand;
				radio.x = posi_x;
				radio.y = pickupColLab.y + ( pickupColLab.height - radio.height) / 2;
				radio.width = radio.textField.textWidth + 35;
				posi_x += radio.width;
				
				if( radio.value == 2) radio.selected = true;
				else radio.selected = false;
			}
			m_pickupColRadioG = radio.group;
			m_pickupColRadioG.addEventListener( Event.CHANGE, onChangePickupCol);
			
			// 受講生一覧(ピックアップ)のレイアウト表示
			m_pickupLayout = MemberListLayout_pickup( m_pickupCon.addChild( new MemberListLayout_pickup()));
			m_pickupLayout.x = pickupColLab.x;
			m_pickupLayout.y = pickupColLab.y + pickupColLab.height + 10;
			m_pickupLayout.addEventListener( Event.CHANGE, changeHeight);
			
			
			// 全体の長さ
			m_bg.height = H = 600; // TODO
			
			// マスク
			m_mask = Shape( addChild( new Shape()));
			m_mask.graphics.beginFill( 0);
			m_mask.graphics.drawRect( 0, 0, m_bg.width, H);
			m_mask.graphics.endFill();
			mask = m_mask;
			
			if( isNew) {
				// thisは新規作成画面として表示
				
				// 保存ボタン
				m_btnSave = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_SAVE)));
				m_btnSave.x = ( m_bg.width - m_btnSave.width) / 2;
				m_btnSave.y = H - m_btnSave.height - 10;
				m_btnSave.setEnabled( true);
				m_btnSave.addEventListener( MouseEvent.CLICK, onClickSave);
			
				m_lecSubMainRadio.selected = true;
				m_stuSubMainRadio.selected = true;
				
				// 分割方法の選択
				//m_alllistColRadioG.selection = m_alllistColRadioG.getRadioButtonAt( m_alllistColRadioG.numRadioButtons - 1);
				//m_pickupColRadioG.selection = m_pickupColRadioG.getRadioButtonAt( m_pickupColRadioG.numRadioButtons - 1);

				// メンバー一覧の表示
				m_alllistLayout.init( int( m_alllistColRadioG.selection.value), null);
				m_pickupLayout.init( int( m_pickupColRadioG.selection.value), []); // ０人表示
				
				m_lecComboSet.initAsPreset( false);
				m_stuComboSet.initAsPreset( false);
				
				open();
			} else {
				// thisは登録済みの一覧リストとして表示
				
				// 保存ボタン
				m_btnChange = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_CHANGE)));
				m_btnChange.x = ( m_bg.width - m_btnChange.width) / 2;
				m_btnChange.y = H - m_btnChange.height - 10;
				m_btnChange.setEnabled( true);
				m_btnChange.addEventListener( MouseEvent.CLICK, onClickSave);
				
				// 削除ボタン
				m_btnDel = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_DEL)));
				m_btnDel.y = m_btnChange.y;
				m_btnDel.setEnabled( true);
				m_btnDel.addEventListener( MouseEvent.CLICK, onClickDel);
				
				// ボタンの位置をちょっとずらしてセンター揃えに
				m_btnChange.x = ( m_bg.width - ( m_btnChange.width + m_btnDel.width + 5)) / 2; 
				m_btnDel.x = m_btnChange.x + m_btnChange.width + 5;
				
				close();
			
				// m_arrow周辺に開く閉じるの透明ボタンを設置
				m_clickObj = Sprite( addChild( new Sprite()));
				m_clickObj.graphics.beginFill( 0, 0);
				m_clickObj.graphics.drawCircle( 0, 0, m_arrow.width + 2);
				m_clickObj.graphics.endFill();
				m_clickObj.x = m_arrow.x;
				m_clickObj.y = m_arrow.y;
				m_clickObj.buttonMode = true;
				m_clickObj.addEventListener( MouseEvent.CLICK,
					function( e:*) {
						if( m_opened) close();
						else open();
					});
			}
		}
		
		public function setNotNew() {
			// 保存ボタン
			if( m_btnChange == null) {
				m_btnChange = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_CHANGE)));
				m_btnChange.x = ( m_bg.width - m_btnChange.width) / 2;
				m_btnChange.y = H - m_btnChange.height - 10;
				m_btnChange.setEnabled( true);
				m_btnChange.addEventListener( MouseEvent.CLICK, onClickSave);
			}			
			// 削除ボタン
			if( m_btnDel == null) {
				m_btnDel = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_DEL)));
				m_btnDel.y = m_btnChange.y;
				m_btnDel.setEnabled( true);
				m_btnDel.addEventListener( MouseEvent.CLICK, onClickDel);
			}
			
			// ボタンの位置をちょっとずらしてセンター揃えに
			m_btnChange.x = ( m_bg.width - ( m_btnChange.width + m_btnDel.width + 5)) / 2; 
			m_btnDel.x = m_btnChange.x + m_btnChange.width + 5;
			
			if( m_btnSave != null) m_btnSave.visible = false;
			
			close();
		
			// m_arrow周辺に開く閉じるの透明ボタンを設置
			if( m_clickObj == null) {
				m_clickObj = Sprite( addChild( new Sprite()));
				m_clickObj.graphics.beginFill( 0, 0);
				m_clickObj.graphics.drawCircle( 0, 0, m_arrow.width + 2);
				m_clickObj.graphics.endFill();
				m_clickObj.x = m_arrow.x;
				m_clickObj.y = m_arrow.y;
				m_clickObj.buttonMode = true;
				m_clickObj.addEventListener( MouseEvent.CLICK,
					function( e:*) {
						if( m_opened) close();
						else open();
					});
			}
		}
		
		function onClickSave( e:MouseEvent) {
			var i :int;
			// フォームの内容チェック
			var errMsg:String = "";
			// タイトル
			var title:String = m_layoutName.text;
			title = title.replace( /\n/g, "" );
			title = title.replace( /\r/g, "" );
			if( title == "") errMsg = ERRMSG_NAMAE;
			if( errMsg != "") {
				msgDialog( errMsg);
				return;
			}
			
			// カラム分けに従ってコンテンツ配置を取得
			// 講師のカラム
			var lecLeftArr:Array = null;
			var lecRightArr:Array = null;
			if( m_lecLayoutRadioG.selectedData == LayoutComponents.SUBMAIN) {
				lecLeftArr = m_lecComboSet.getSelectedData_sub();
				lecRightArr = m_lecComboSet.getSelectedData_main();
			} else if( m_lecLayoutRadioG.selectedData == LayoutComponents.MAINSUB) {
				lecLeftArr = m_lecComboSet.getSelectedData_main();
				lecRightArr = m_lecComboSet.getSelectedData_sub();
			} else if( m_lecLayoutRadioG.selectedData == LayoutComponents.FULL) {
				lecLeftArr = m_lecComboSet.getSelectedData_full();
				lecRightArr = [];
			} else {
				errMsg = ERRMSG_LEC_LAYOUT;
			}
			if( lecLeftArr == null || lecLeftArr.length == 0) errMsg = ERRMSG_LEC_LAYOUT;
			if( m_lecLayoutRadioG.selectedData != LayoutComponents.FULL && lecRightArr.length == 0)  errMsg = ERRMSG_LEC_LAYOUT;
			// 受講生のカラム
			var stuLeftArr:Array = null;
			var stuRightArr:Array = null;
			if( m_stuLayoutRadioG.selectedData == LayoutComponents.SUBMAIN) {
				stuLeftArr = m_stuComboSet.getSelectedData_sub();
				stuRightArr = m_stuComboSet.getSelectedData_main();
			} else if( m_stuLayoutRadioG.selectedData == LayoutComponents.MAINSUB) {
				stuLeftArr = m_stuComboSet.getSelectedData_main();
				stuRightArr = m_stuComboSet.getSelectedData_sub();
			} else if( m_stuLayoutRadioG.selectedData == LayoutComponents.FULL) {
				stuLeftArr = m_stuComboSet.getSelectedData_full();
				stuRightArr = [];
			} else {
				errMsg = ERRMSG_STU_LAYOUT;
			}
			if( stuLeftArr == null || stuLeftArr.length == 0) errMsg = ERRMSG_STU_LAYOUT;
			if( m_stuLayoutRadioG.selectedData != LayoutComponents.FULL && stuRightArr.length == 0) errMsg = ERRMSG_STU_LAYOUT;

			// 受講生一覧
			var videolistCol:int;
			var videolistArr:Array = null;
			var videopickupCol:int;
			var videopickupArr:Array = null;
			if( m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected()) {
				// 分割数チェック
				if( m_alllistColRadioG.selectedData == null) {
					errMsg = ERRMSG_ALLCOL;
				} else {
					videolistCol = int( m_alllistColRadioG.selectedData);
				}
				if( m_pickupColRadioG.selectedData == null) {
					errMsg = ERRMSG_PICKUPCOL;
				} else {
					videopickupCol = int( m_pickupColRadioG.selectedData);
				}
				// UID配列取得（ゼロなら空の配列が入る）
				videolistArr = m_alllistLayout.getSelectedUidArr();
				videopickupArr = m_pickupLayout.getSelectedUidArr();
			}
			
			if( errMsg != "") {
				msgDialog( errMsg);
				return;
			}
			
			var mode:String = "";
			if( m_layout == null) {
				// 新規作成
				mode = "new";
				// フォームの内容でm_layoutを生成
				var dateObj:Date = new Date();
				var createDate = dateObj.getFullYear() + "-" +
								dateObj.getMonth() + "-" + 
								dateObj.getDate() + " " + 
								dateObj.getHours() + ":" +
								dateObj.getMinutes() + ":"+ 
								dateObj.getSeconds();
				m_layout = new Layout( title,
									  lecLeftArr,
									  lecRightArr,
									  stuLeftArr,
									  stuRightArr,
									  createDate,
									  Layout.P_UNLOCK);
				if( m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected()) {
					m_layout.memberCol = videolistCol;
					m_layout.memberCol_pickup = videopickupCol;
					m_layout.memberUids = videolistArr;
					m_layout.memberUids_pickup = videopickupArr;
				}
									  								
			} else {
				// 更新
				mode = "mod";
				// フォームの内容をm_layoutに反映させる
				m_layout.name = title;
				m_layout.lecLeftWinNames = lecLeftArr;
				m_layout.lecRightWinNames = lecRightArr;
				m_layout.stuLeftWinNames = stuLeftArr;
				m_layout.stuRightWinNames = stuRightArr;
				if( m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected()) {
					m_layout.memberCol = videolistCol;
					m_layout.memberCol_pickup = videopickupCol;
					m_layout.memberUids = videolistArr;
					m_layout.memberUids_pickup = videopickupArr;
				}
			}
			dispatchEvent( new Event( CLICK_SAVE)); // 新規の場合はSettingContentsに、更新の場合はLayoutComponentsConに知らせる

			var pattern:RegExp = new RegExp( Layout.DEFAULT_LAYOUT_CDATE);
//AlertManager.createAlert( this ,pattern.exec( m_layout.createDate));
			if( pattern.exec( m_layout.createDate) == null) {
				// プリセットでなければDBにも保存
//AlertManager.createAlert( this ,"LayoutComponents: プリセットではないのでDBに保存します");

				var url = Main.CONF.getParam( "SETLAYOUT_URL");
				if( url == LoadConf.NOTFOUND) {
					alertDialog( Main.LANG.getReplacedSentence( "%sが設定されていないためDBに保存できませんでした", "SETLAYOUT_URL"));
					return;
				}

				var val:URLVariables = new URLVariables();
				val.class_id = Main.CONF.CLASS_ID;
				val.mode = mode;
				val.date = m_layout.createDate;
				val.title = m_layout.name;
				
				for( i = 0; i < m_layout.lecLeftWinNames.length; i++) {
					val["lecturer_left_arr[" + i + "]"] = m_layout.lecLeftWinNames[i];
				}
				for( i = 0; i < m_layout.lecRightWinNames.length; i++) {
					val["lecturer_right_arr[" + i + "]"] = m_layout.lecRightWinNames[i];
				}
				for( i = 0; i < m_layout.stuLeftWinNames.length; i++) {
					val["student_left_arr[" + i + "]"] = m_layout.stuLeftWinNames[i];
				}
				for( i = 0; i < m_layout.stuRightWinNames.length; i++) {
					val["student_right_arr[" + i + "]"] = m_layout.stuRightWinNames[i];
				}

				if( m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected()) {
					val.videolist_colspan = m_layout.memberCol;
					val.videopickup_colspan = m_layout.memberCol_pickup;
					for( i = 0; i < m_layout.memberUids.length; i++) {
						val["videolist_arr[" + i + "]"] = m_layout.memberUids[i];
					}
					for( i = 0; i < m_layout.memberUids_pickup.length; i++) {
						val["videopickup_arr[" + i + "]"] = m_layout.memberUids_pickup[i];
					}
				}
				var req:URLRequest = new URLRequest( url);
				req.method = URLRequestMethod.POST;
				req.data = val;
				var loader:URLLoader = new URLLoader();
				loader.addEventListener( IOErrorEvent.IO_ERROR, function( e:*) { alertDialog( "IO_ERROR: " + url);});
				loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function( e:*) { alertDialog( "SECURITY_ERROR: " + url);});
				loader.load( req);
								
			} else {
//AlertManager.createAlert( this ,"LayoutComponents: プリセットなのでDBには保存しません");

			}
		}
		
		function onClickDel( e:MouseEvent) {
			var pattern:RegExp = new RegExp( Layout.DEFAULT_LAYOUT_CDATE);
			if( m_layout == null || pattern.exec( m_layout.createDate) != null) {
			//if( m_layout == null || m_layout.createDate == Layout.DEFAULT_LAYOUT_DATE) {
				// 新規作成（m_layout == null）やプリセットの場合はこの関数は呼ばれないはず
				alertDialog( "ERROR : cannot delete.");
				return;
			}
			dispatchEvent( new Event( CLICK_DEL));// LayoutComponentsConに知らせる
			
			// DBに投げる
			var url = Main.CONF.getParam( "SETLAYOUT_URL");
			if( url == LoadConf.NOTFOUND) {
				alertDialog( Main.LANG.getReplacedSentence( "%sが設定されていないためDBに保存できませんでした", "SETLAYOUT_URL"));
				return;
			}
			
			var val:URLVariables = new URLVariables();
			val.class_id = Main.CONF.CLASS_ID;
			val.mode = "del";
			val.date = m_layout.createDate;
			var req:URLRequest = new URLRequest( url);
			req.method = URLRequestMethod.POST;
			req.data = val;
			var loader:URLLoader = new URLLoader();
			loader.addEventListener( IOErrorEvent.IO_ERROR, function( e:*) { alertDialog( "IO_ERROR: " + url);});
			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, function( e:*) { alertDialog( "SECURITY_ERROR: " + url);});
			loader.load( req);
			
		}
		
		// CLICK_SAVEやCLICK_DELをListenした人から呼ばれる。
		// なのでこの時点でm_layoutは絶対にnullではない、はず
		public function getLayout() : Layout {
			if( m_layout == null) {
				alertDialog( "ERROR : layout is null.");
			}
			return m_layout;
		}
		
		// 講師画面の表示ウィンドウのコンボボックスの内容が変わった
		function onChangeLecWinCombo( e:Event) {
//trace(m_lecComboSet.isMemberSelected());
			// 受講生一覧が含まれていたら、受講生一覧の分割設定フォームを表示する
			m_memberListCon.visible = m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected();
			changeHeight();
		}
		// 受講生画面の表示ウィンドウのコンボボックスの内容が変わった
		function onChangeStuWinCombo( e:Event) {
			// 受講生一覧が含まれていたら、受講生一覧の分割設定フォームを表示する
			m_memberListCon.visible = m_lecComboSet.isMemberSelected() || m_stuComboSet.isMemberSelected();
			changeHeight();
		}
		
		// 受講生一覧（全体表示）の分割方法が変わった
		function onChangeAlllistCol( e:Event) {
//trace( "受講生一覧（全体表示）の分割方法:", String( ));
			m_alllistLayout.changeCols( m_alllistColRadioG.selectedData);
			changeHeight();
		}
		
		// 受講生一覧（ピックアップ）の分割方法が変わった
		function onChangePickupCol( e:Event) {
			m_pickupLayout.changeCols( m_pickupColRadioG.selectedData);
			changeHeight();
		}
		
		// 受講生一覧の高さ（行数）が変わった可能性があるので、全体を配置し直す
		function changeHeight( e:* = null) {
			if( m_opened) {
				if( ! m_memberListCon.visible) {
					// そもそも受講生一覧は表示しない
					H = m_allListLabel.y;
				} else {
					// 受講生一覧の映像表示方法（2）ピックアップ表示の高さを合わせる
					m_pickupCon.y = m_alllistLayout.y + m_alllistLayout.getViewHeight() + 20;
					
					H = m_pickupCon.y + m_pickupLayout.y + m_pickupLayout.getViewHeight();
				}
				
				if( m_btnSave != null) {
					H += m_btnSave.height + 30;
					m_btnSave.y = H - m_btnSave.height - 15;
					if( m_btnDel != null) m_btnDel.y = m_btnSave.y;
				}
				if( m_btnChange != null) {
					H += m_btnChange.height + 30;
					m_btnChange.y = H - m_btnChange.height - 15;
					if( m_btnDel != null) m_btnDel.y = m_btnChange.y;
				}
			} else {
				H = 55;
			}
			
			m_bg.height = H;
			
			m_mask.graphics.clear();
			m_mask.graphics.beginFill( 0);
			m_mask.graphics.drawRect( 0, 0, m_bg.width, H);
			m_mask.graphics.endFill();

			dispatchEvent( new DrawerEvent( DrawerEvent.CONTENTS_H_CHANGED, H));

		}
		
		public function open() {
			m_opened = true;
			m_arrow.rotation = 90;
			changeHeight();
		}
		public function close() {
			m_opened = false;
			m_arrow.rotation = 0;
			changeHeight();
		}
		
		// 講師画面のカラム構成の変更
		function onChangeLecLayout( e:Event) {
			m_lecBlueLayoutBox.setLine( m_lecLayoutRadioG.selectedData);
			m_lecComboSet.change( m_lecLayoutRadioG.selectedData);
//trace( "講師画面のカラム構成の変更", m_lecLayoutRadioG.selectedData);			
		}
		
		// 受講生画面のカラム構成の変更
		function onChangeStuLayout( e:Event) {
			m_stuBlueLayoutBox.setLine( m_stuLayoutRadioG.selectedData);
			m_stuComboSet.change( m_stuLayoutRadioG.selectedData);
		}
		
		// 選択状態を設定
		public function init( layout:Layout) {
			m_layout = layout;
			
			// 生成日からプリセットか否かを判別
			var pattern:RegExp = new RegExp( Layout.DEFAULT_LAYOUT_CDATE);
			if( pattern.exec( layout.createDate) != null) {
				// これはプリセットなので、
				// コンボボックスを生成しない形でinit
				m_lecComboSet.initAsPreset( true);
				m_stuComboSet.initAsPreset( true);
			} else {
				m_lecComboSet.initAsPreset( false);
				m_stuComboSet.initAsPreset( false);
			}
			
			m_layoutName.text = layout.name;
			
			//-----------------------------
			// 画面のカラム構成の設定と
			// 表示ウィンドウのコンボボックスの内容の設定
			switch( layout.lecLayout) {
				case Layout.LAYOUT_SUBMAIN:
					m_lecSubMainRadio.selected = true;
					m_lecComboSet.setComboSelection_sub( layout.lecLeftWinNames); // サブ=LEFT
					m_lecComboSet.setComboSelection_main( layout.lecRightWinNames); // メイン=RIGHT
					break;
				case Layout.LAYOUT_MAINSUB:
					m_lecMainSubRadio.selected = true;
					m_lecComboSet.setComboSelection_main( layout.lecLeftWinNames); // メイン=LEFT
					m_lecComboSet.setComboSelection_sub( layout.lecRightWinNames); // サブ=RIGHT
					break;
				case Layout.LAYOUT_FULL:
					m_lecFullRadio.selected = true;
					m_lecComboSet.setComboSelection_full( layout.lecLeftWinNames); // フル=LEFT
					break;
			}
			switch( layout.stuLayout) {
				case Layout.LAYOUT_SUBMAIN:
					m_stuSubMainRadio.selected = true;
					m_stuComboSet.setComboSelection_sub( layout.stuLeftWinNames); // サブ=LEFT
					m_stuComboSet.setComboSelection_main( layout.stuRightWinNames); // メイン=RIGHT
					break;
				case Layout.LAYOUT_MAINSUB:
					m_stuMainSubRadio.selected = true;
					m_stuComboSet.setComboSelection_main( layout.stuLeftWinNames); // メイン=LEFT
					m_stuComboSet.setComboSelection_sub( layout.stuRightWinNames); // サブ=RIGHT
					break;
				case Layout.LAYOUT_FULL:
					m_stuFullRadio.selected = true;
					m_stuComboSet.setComboSelection_full( layout.stuLeftWinNames); // フル=LEFT
					break;
			}
						
			
			//-----------------------------
			// 参加者一覧の分割方法の選択
			var i:uint;
			var radio:RadioButton;
			for( i = 0; i < m_alllistColRadioG.numRadioButtons; i++) {
				radio = m_alllistColRadioG.getRadioButtonAt( i);
				if( radio.value == layout.memberCol) {
					m_alllistColRadioG.selection = radio;
					break;
				}
			}
			for( i = 0; i < m_pickupColRadioG.numRadioButtons; i++) {
				radio = m_pickupColRadioG.getRadioButtonAt( i);
				if( radio.value == layout.memberCol_pickup) {
					m_pickupColRadioG.selection = radio;
					break;
				}
			}

			//-----------------------------
			// メンバー一覧の表示
			m_alllistLayout.init( int( m_alllistColRadioG.selection.value), layout.memberUids != null ? layout.memberUids : null);
			m_pickupLayout.init( int( m_pickupColRadioG.selection.value), layout.memberUids_pickup != null ? layout.memberUids_pickup : []);
		
			// 生成日からプリセットか否かを判別
			if( pattern.exec( layout.createDate) != null) {
				// これはプリセットなので、編集や削除はしない
				
				// 削除ボタンの非表示
				//m_btnSave.visible = false;
				if( m_btnDel != null) m_btnDel.visible = false;
				m_btnChange.x = ( m_bg.width - m_btnChange.width) / 2;
				
				// 見出しテキストを編集不可に
				m_layoutName.type = TextFieldType.DYNAMIC;
				m_layoutName.border = false;
				m_layoutName.background = false;
				
				// ラジオボタンを編集不可に
				for( i = 0; i < m_lecLayoutRadioG.numRadioButtons; i++) {
					m_lecLayoutRadioG.getRadioButtonAt( i).enabled = false;
				}
				for( i = 0; i < m_stuLayoutRadioG.numRadioButtons; i++) {
					m_stuLayoutRadioG.getRadioButtonAt( i).enabled = false;
				}
				for( i = 0; i < m_alllistColRadioG.numRadioButtons; i++) {
					m_alllistColRadioG.getRadioButtonAt( i).enabled = false;
				}
				for( i = 0; i < m_pickupColRadioG.numRadioButtons; i++) {
					m_pickupColRadioG.getRadioButtonAt( i).enabled = false;
				}
				
				// コンボボックスを編集不可に
				//m_lecComboSet.setEnabled( false);
				//m_stuComboSet.setEnabled( false);
			}
		}
		
		function getLabel( str:String) {
			var lab:TextField = new TextField();
			lab.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 10);
			lab.text = str;
			lab.autoSize = TextFieldAutoSize.LEFT;
			lab.selectable = lab.mouseEnabled = false;
			return lab;
		}
		function alertDialog( str:String) {
			Main.addErrMsg("LayoutComponents:" + str);
		}
		function msgDialog( str:String) {
			AlertManager.createAlert( this , str);
		}
	}
}
import window.setting.*;
import flash.display.*;
class BlueLayoutBox extends Sprite {
	private var m_line:Shape;
	public function BlueLayoutBox() {
		graphics.beginFill( 0x446787);
		graphics.drawRect( 0, 0, 75, 75);
		graphics.endFill();
		
		m_line = new Shape();
		m_line.graphics.lineStyle( 2, 0xf0f0f0);
		m_line.graphics.lineTo( 0, 75);
	}
	public function setLine( type) {
		switch( type) {
			case LayoutComponents.SUBMAIN:setSubMain(); break;
			case LayoutComponents.MAINSUB:setMainSub(); break;
			case LayoutComponents.FULL:setFull(); break;
		}
	}
	function setSubMain() {
		addChild( m_line);
		m_line.x = 25;
	}
	function setMainSub() {
		addChild( m_line);
		m_line.x = 50;
	}
	function setFull() {
		if( contains( m_line)) removeChild( m_line);
	}
}