﻿package window.questionnaire {		import flash.display.Sprite;	import flash.text.*;	import common.DynamicTextBtn;	import fl.controls.SelectableList;	import flash.events.Event;	import flash.events.MouseEvent;		// アンケート選択肢の集計結果表示	public class QSelectionGraph extends Sprite {		private const LABEL = Main.LANG.getParam( "投票数／全投票数");		private const PAD = 5;		private var W:Number;		private var m_selection:Array;		private var m_selArr:Array;				public function QSelectionGraph( w:Number, selection:Array) {			W = w;			m_selection = selection;			/*var tmp = "";for each( var t in m_selection) { tmp += String( t) + ",";}Main.addDebugMsg( "QSelectionGraph: " + tmp);*/						// グラフ部分のタイトル見出し			var lab:TextField = TextField( addChild( getLabelText( LABEL)));			lab.x = W - GraphBar.W + ( GraphBar.W - lab.width)/ 2;						// 個々の選択肢に対する選択肢テキスト＋グラフバーを生成			var posi_y = lab.y + lab.height + PAD;			m_selArr = new Array();			for( var i = 0; i < selection.length; i++) {				var new_sel:SelSummary = SelSummary( addChild( new SelSummary( selection[i], W)));				new_sel.y = posi_y;				posi_y += SelSummary.H + 2;				m_selArr.push( new_sel);			}		}				public function resetData( uidAnswerHash:Object) {			var i:uint;			if( uidAnswerHash == null || getObjectLength( uidAnswerHash) == 0 ) {				// 全部ゼロ%に				for( i = 0; i < m_selArr.length; i++) {					SelSummary( m_selArr[i]).setData( 0);				}			} else {				// 全投票数				var ttlCnt = getObjectLength( uidAnswerHash);								// 個々の選択肢に対する投票数				for( i = 0; i < m_selection.length; i++) {					var cnt = 0;					for each( var answer:String in uidAnswerHash) {						if( answer == m_selection[i]) cnt++;					}					SelSummary( m_selArr[i]).setData( cnt / ttlCnt);				}			}		}				public function getObjectLength( obj:Object) {			var cnt = 0;			for each( var val in obj) {				cnt++;			}			return cnt;		}				public function getSummary() : Array {			var arr:Array = new Array();			for( var i = 0; i < m_selArr.length; i++) {				var sel:SelSummary = m_selArr[ i];				arr.push( sel.getData());			}			return arr;		}		function getLabelText( str:String):TextField {			var lab:TextField = TextField( addChild( new TextField()));			var fmt:TextFormat = new TextFormat( Main.CONF.getMainFont(), 10, 0);			lab.defaultTextFormat = fmt;			lab.autoSize = TextFieldAutoSize.LEFT;			lab.text = str;			return lab;		}		function alertDialog( str) {			Main.addErrMsg( "QSelectionGraph:" + String( str));		}	}}import flash.display.*;import flash.events.*;import common.DynamicTextBtn;import flash.text.*;class SelSummary extends Sprite {	static public const H = 25;	private var m_text:TextField;	private var m_bar:GraphBar;		public function SelSummary( str:String, w:Number) {		graphics.beginFill( 0xe0e0e0);		graphics.drawRect( 0, 0, w, H);		graphics.endFill();				m_text = TextField( addChild( new TextField()));		m_text.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 11);		m_text.text = str;		m_text.height = m_text.textHeight + 2;		m_text.x = 10;		m_text.y = ( H - m_text.height) / 2;		m_text.width = w - GraphBar.W - 20;				var arrow01 = addChild( new Arrow01());		arrow01.x = w - GraphBar.W - 7;		arrow01.y = H / 2;		arrow01.scaleX = arrow01.scaleY = 0.6;				m_bar = GraphBar( addChild( new GraphBar( H)));		m_bar.x = w - GraphBar.W;		m_text.y = ( H - m_text.height) / 2;	}	public function setData( data:Number) {				m_bar.setData( data);	}	public function getData():Number {		return m_bar.getData();	}}class GraphBar extends Sprite {	static public const W:Number = 200;	private var m_text:TextField;	private var m_data:Number;	private var m_bar:Shape;	public function GraphBar( h:Number) {		graphics.beginFill( 0xffffff);		graphics.drawRect( 0, 0, W, h);		graphics.endFill();				m_bar = Shape( addChild( new Shape()));		m_bar.graphics.beginFill( Main.LIGHT_GREEN);		m_bar.graphics.drawRect( 0, 0, W, h);		m_bar.graphics.endFill();		m_bar.scaleX = 0;				m_text = TextField( addChild( new TextField()));		m_text.width = W - 5;		var fmt:TextFormat = new TextFormat( Main.CONF.getMainFont(), 10);		fmt.align = "right";		m_text.defaultTextFormat = fmt;		m_text.text = "0%";		m_text.height = m_text.textHeight + 4;		m_text.y = ( h - m_text.height) / 2;			}	public function setData( data:Number) {		m_data = data;		m_text.text = String( Math.floor( data * 100)) + "%";		m_bar.scaleX = data;	}	public function getData():Number {		return m_data;	}}