﻿package window.questionnaire {	import flash.display.*;	import fl.events.*;	import common.*;	import window.*;	import fl.controls.CheckBox;	import flash.events.Event;	import flash.text.*;	import flash.events.*;	import flash.net.*;	import partition.Layout;	import common.AlertManager;		// アンケートのコンポーネントセット　集計中／集計結果表示中用	// タイトル、質問文、集計グラフ（選択肢込み）や集計詳細を表示。	public class QComponentsResult extends QComponents {		static public const SHOW_ALL_CHANGED = "SHOW_ALL_CHANGED";		static public const CLICK_STOP:String = "CLICK_STOP";				// ラベル、見出し		private const LABEL_SHOW = Main.LANG.getParam( "アンケート集計結果を生徒に表示する");				private var m_desc:TextField;		private var m_select:TextField;		private var m_chkShow:CheckBox;		private var m_graph:QSelectionGraph;		private var m_memberList:MemberListCon;		private var m_btnStop:DynamicTextBtn = null;		private var m_clickObj:Sprite;		private var m_icon:DynamicTextIcon; // 集計中もしくは集計終了アイコン				public function QComponentsResult( questionnaire:Questionnaire) {						super();			m_questionnaire = questionnaire;			// タイトルのテキスト			m_title.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 13);			m_title.background = false;			m_title.border = false;			m_title.type = TextFieldType.DYNAMIC;			m_title.text = questionnaire.title;						// 質問文のテキスト			m_desc = TextField( addChild( new TextField()));			m_desc.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 12);			m_desc.multiline = true;			m_desc.wordWrap = true;			m_desc.x = m_title.x;			m_desc.y = m_title.y + m_title.height + 17;			m_desc.width = W - ( m_desc.x + PAD);			m_desc.text = questionnaire.description;			m_desc.height = m_desc.textHeight + 8;						// 集計グラフ			if( questionnaire.selection == null) {				errDialog( Main.LANG.getReplacedSentence( "%sには選択肢が設定されていません。", questionnaire.title));return;			}			m_graph = QSelectionGraph( addChild( new QSelectionGraph( m_desc.width, questionnaire.selection)));			m_graph.x = m_desc.x;			m_graph.y = m_desc.y + m_desc.height + PAD;									// アンケート集計結果を生徒に表示するかどうかのCheckBox			m_chkShow = CheckBox( addChild( new CheckBox()));			m_chkShow.label = LABEL_SHOW;			m_chkShow.width += m_chkShow.textField.textWidth;			m_chkShow.x = m_desc.x;			m_chkShow.y = m_graph.y + m_graph.height + PAD;			m_chkShow.addEventListener( Event.CHANGE, function( e:Event) { m_questionnaire.showall = m_chkShow.selected ? 1 : 0;dispatchEvent( new Event( SHOW_ALL_CHANGED));});			m_chkShow.selected = questionnaire.showall == 1 ? true : false;					// 回答者一覧			m_memberList = MemberListCon( addChild( new MemberListCon( m_desc.width, m_questionnaire.selection)));			m_memberList.x = m_desc.x;			m_memberList.y = m_chkShow.y + m_chkShow.height + PAD;			m_memberList.addEventListener( MemberListCon.CHANGE_HEIGHT, changeHeight);						// 集計中アイコンの設置			m_icon = DynamicTextIcon( addChild( 						new DynamicTextIcon( STATUS_LABEL_NOWON, STATUS_LABEL_W, STATUS_LABEL_H, 0xf50000, 0xf50000, 0xffffff)));			m_icon.x = W - m_icon.width - PAD;			m_icon.y = m_title.y + ( m_title.height - m_icon.height) / 2;						// 終了してDB保存ボタンの設置			m_btnStop = DynamicTextBtn( addChild( new DynamicTextBtn( LABEL_STOP)));			m_btnStop.x = m_icon.x - PAD - m_btnStop.width;			m_btnStop.y = m_title.y + ( m_title.height - m_btnStop.height) / 2;			m_btnStop.setEnabled( true);			m_btnStop.addEventListener( MouseEvent.CLICK, onClickStop);						m_title.width = W - ( m_title.x + m_icon.width + PAD * 3 + m_btnStop.width);									// タイトル周辺に開く閉じるの透明ボタンを設置			m_clickObj = Sprite( addChild( new Sprite()));			m_clickObj.graphics.beginFill( 0, 0);			m_clickObj.graphics.drawRect( 0, m_title.y, m_title.x + m_title.width, m_title.height);			m_clickObj.graphics.endFill();			m_clickObj.buttonMode = true;			m_clickObj.addEventListener( MouseEvent.CLICK,				function( e:*) {					if( m_opened) close();					else open();				});						resetData( questionnaire.uidAnswerHash);						super.status4sort = super.SORT_STATUS_NOWON;								super.changeHeight();		}				override protected function getOpenedHeight():Number {			return m_memberList.y + m_memberList.getViewHeight();		}				public function resetData( uidAnswerHash:Object) {			// グラフに反映			m_graph.resetData( uidAnswerHash);						// 回答者一覧に反映			m_memberList.resetData( uidAnswerHash);		}				function onClickStop( e:MouseEvent) {						// 内容をm_questionnaireに反映させる			m_questionnaire.showall = m_chkShow.selected ? 1 : 0;			//m_questionnaire.uidAnswerHash = xxx; // 回答結果は生徒が個々にSOにアップしてくれている、はず					dispatchEvent( new Event( CLICK_STOP)); // QComponentsConに知らせてSOに反映、回答結果含めてDBに保存						finished();					}		public function finished() {			// 集計中アイコンを集計終了に変更			m_icon.resetText( STATUS_LABEL_FINISH);			m_icon.resetBase( 0xaaaaaa, 0x999999);			if( contains( m_btnStop)) removeChild( m_btnStop);			m_btnStop.removeEventListener( MouseEvent.CLICK, onClickStop);			m_title.width = W - ( m_title.x + m_icon.width + PAD * 2);			super.status4sort = super.SORT_STATUS_FINISH;		}		public function getObjectLength( obj:Object) {			var cnt = 0;			for each( var val in obj) {				cnt++;			}			return cnt;		}		function errDialog( str) {			AlertManager.createAlert( this, str);		}	}}