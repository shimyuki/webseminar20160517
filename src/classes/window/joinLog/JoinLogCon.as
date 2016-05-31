﻿package window.joinLog {	import flash.display.*;	import flash.geom.*;	import common.*;	import window.*;	import flash.text.*;	import flash.events.*;	import flash.net.*;	// 入室ログ（講師用）	public class JoinLogCon extends ResizableContainer {		private const INIT_Y = 10;		private const PAD = 8;		private var m_container:Sprite;		private var m_containerMask:Sprite;		private var m_scroll:SimpleScrollBar = null;		private var m_preW:Number = 0;		private var m_preH:Number = 0;				private var m_text:TextField;		private var SCROLL_PAD_BOTTOM = 15;		private var so:SharedObject = null;				public function JoinLogCon()		{			super( 100, 100, 100, 100); // min_w は後で設定し直すのでとりあえずゼロ			// 表示コンテナ			m_container = Sprite( addChild( new Sprite()));			m_container.y = INIT_Y;						// 表示コンテナのマスク			m_containerMask = Sprite( addChild( new Sprite()));			m_containerMask.graphics.beginFill(0);			m_containerMask.graphics.drawRect( 0, 0, 1, 1);			m_containerMask.y = m_container.y;			m_container.mask = m_containerMask;						// ログテキスト			m_text = new TextField();			m_text.wordWrap = true;			m_text.multiline = true;			m_text.condenseWhite = true;			m_text.defaultTextFormat = new TextFormat( "_ゴシック", 11);			m_text.width = 100;			m_container.addChild( m_text);			m_text.x = m_text.y = PAD;												// チャットテキストのCSS			var style:StyleSheet = new StyleSheet();						// class無し（ログや名前）            var p:Object = new Object();			p.fontSize = 11;			p.color = "#333333";			p.leading = 3;			p.marginTop = 11;			p.marginLeft = 10;						// 時刻            var span_time:Object = new Object();            span_time.color = "#999999";						// タイトル            var h1:Object = new Object();            h1.color = "#000000";			h1.fontSize = 13;			h1.marginLeft = 10;			h1.leading = 10;						style.setStyle("p", p);            style.setStyle("span", span_time);			style.setStyle("h1", h1);					m_text.styleSheet = style;						addEventListener( Event.ADDED, initScroll);			addEventListener( Event.ADDED_TO_STAGE,				function( e:Event) {					// ポップアップとの切り替え時など。					// スクロールバーを一番上の状態に。					m_container.y = INIT_Y;					if( m_scroll) m_scroll.setBarYMin();									});		}		function initScroll( e:Event) {			removeEventListener( Event.ADDED, initScroll);						// 表示コンテナのスクロールバー			if( m_scroll == null) {								m_scroll = addChild( new SimpleScrollBar()) as SimpleScrollBar;				m_scroll.y = INIT_Y;				m_scroll.setSize( m_scroll.width, 200);								m_scroll.setScrollTarget( m_container);				m_scroll.scrollMask = m_containerMask;			}		}				public function reset( so_log:SharedObject) {			var tmp_arr:Array = new Array();			for( var key:String in so_log.data) {				if( key.indexOf( MyJoinLog.FIRST_JOING_TIME) > 0) {					var _uid = key.replace( MyJoinLog.FIRST_JOING_TIME, "");									var tmp_obj = { uid: _uid,									date: so_log.data[ key]									};					tmp_arr.push( tmp_obj);				}			}			tmp_arr.sortOn( [ "date"], [Array.DESCENDING|Array.NUMERIC,null]);									var htmlLogText:String = "<h1>"+Main.LANG.getParam( "入室時間") + "</h1>";			for( var i = 0; i < tmp_arr.length; i++) {				if( !Main.CONF.isStudent( tmp_arr[i].uid)) continue;				htmlLogText += "<p><span>" + tmp_arr[i].date + "</span>　　" + tmp_arr[i].uid + "</p>";			}						m_text.htmlText = htmlLogText;			m_text.height = m_text.textHeight + 8;						// スクロールバーを一番上の状態に。			if( m_scroll) {				m_container.y = INIT_Y;				m_scroll.setBarYMin();				m_scroll.update();			}		}		/*		function addLog( normalText:String) {						var now:Date = new Date();			var hour:String = now.getHours() < 10 ? "0" + String( now.getHours()) : String( now.getHours());			var min:String = now.getMinutes() < 10 ? "0" + String( now.getMinutes()) : String( now.getMinutes());			var htmlLogText:String = "<p><span>" + hour + ":" + min + "</span> " + normalText + "</p>";						m_text.htmlText = htmlLogText + m_text.htmlText;			m_text.height = m_text.textHeight + 8;						// スクロールバーを一番上の状態に。			if( m_scroll) {				m_container.y = INIT_Y;				m_scroll.setBarYMin();				m_scroll.update();			}		}*/				override public function setViewWidth( w:Number, debug:String = ""):void {			if( w < MIN_W) w = MIN_W;			super.setViewWidth( w);						if( m_scroll) m_containerMask.width = w - m_scroll.width;			if( m_scroll) m_scroll.x = w - m_scroll.width;								m_text.width = w - PAD * 2 - m_scroll.width;						m_text.height = m_text.textHeight + 8;						// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、			// サイズがかわらないのであればここでリターン			if( w != m_preW && m_scroll) {				m_preW = w;				m_scroll.update();			}					}				override public function setViewHeight( h:Number):void {			if( h < MIN_H) h = MIN_H;			super.setViewHeight( h);			m_containerMask.height = h - INIT_Y - PAD * 2;						//m_inputText.y = h - INPUT_H;			//m_line.y = m_inputText.y - PAD;			//m_inputBtn.y = m_inputText.y + ( m_inputText.height - m_inputBtn.height) / 2;						m_text.height = m_text.textHeight + 8;						// なんどもスクロールのupdate()を呼ぶと何故かちょっとずつずれてしまうので、			// サイズがかわらないのであればここでリターン			if( h != m_preH  && m_scroll) {				m_preH = h;				m_scroll.setSize( m_scroll.width, h - INIT_Y - SCROLL_PAD_BOTTOM);				m_scroll.update();			}		}	}}