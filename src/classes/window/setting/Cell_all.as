﻿package window.setting {	import flash.display.*;	import fl.controls.ComboBox;	import flash.text.*;	import flash.net.URLRequest;	import flash.events.Event;	import fl.controls.CheckBox;		public class Cell_all extends Cell {				private var m_black:Shape = null;		private var m_chkbox:CheckBox;		public function Cell_all( uid:String, _w:Number) {						H = 2+HEADER_H+1+IMG_H+1+FOOTER_H+2;						m_black = new Shape();// 使用しないのときに画像にかぶせる半透明のグレーマスク									m_chkbox = CheckBox( addChild( new CheckBox()));			m_chkbox.label = LayoutComponents.LABEL_USE;			m_chkbox.addEventListener(Event.CHANGE, onChange);			m_chkbox.x = 5;			m_chkbox.y = H - 2 - FOOTER_H + 3;			m_chkbox.setSize( _w - 10, 15);						super( uid, _w);			//m_combo.addItem( { label:LayoutComponents.LABEL_USE}); // 使用する			//m_combo.addItem( { label:LayoutComponents.LABEL_NOUSE}); // 使用しない			//m_combo.addEventListener( Event.CHANGE, onChange);		}				override public function getSelectedUid():String { 			// このユーザを使用するか否か			if( contains( m_black)) return null;			return m_selectedUid;		}		public function getUid():String { 			// このユーザを使用するか否かに関わらず、とにかく最初に設定されたuidを返す			return m_selectedUid;		}				override public function setWidth( _w:Number) {			super.setWidth( _w);						if( m_black != null && contains( m_black)) {				m_black.graphics.clear();				m_black.graphics.beginFill( 0, 0.5);				m_black.graphics.drawRect( 2, 2 + HEADER_H + 1, IMG_W, IMG_H);				m_black.graphics.endFill();			}										// チェックボックスサイズと位置			m_chkbox.y = H - 2 - FOOTER_H + 3;			m_chkbox.setSize( _w - 10, 15);		}				// 使用する／しないをセット（LoadConfでXML読み込み時にMemberListLayout_allのinit()経由で呼び出される）		public function setUse( b:Boolean) {			/*for( var i = 0; i < m_combo.length; i++) {				var item:Object = Object( m_combo.getItemAt( i));				if( b && item.label == LayoutComponents.LABEL_USE) m_combo.selectedItem = item;				else if( !b && item.label == LayoutComponents.LABEL_NOUSE) m_combo.selectedItem = item;			}*/			m_chkbox.selected = b;			onChange();		}				function onChange( e:Event = null) {			if( ! m_chkbox.selected) {				m_black.graphics.clear();				m_black.graphics.beginFill( 0, 0.5);				m_black.graphics.drawRect( 2, 2 + HEADER_H + 1, IMG_W, IMG_H);				m_black.graphics.endFill();				addChild( m_black);			} else {				if( contains( m_black)) removeChild( m_black);			}		}			}}