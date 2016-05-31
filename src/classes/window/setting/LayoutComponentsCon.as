package window.setting {
	import flash.display.*;
	import fl.controls.RadioButton;
	import fl.controls.ComboBox;
	import fl.events.*;
	import common.*;
	import window.*;
	import fl.controls.RadioButtonGroup;
	import flash.events.Event;
	import flash.text.*;
	import flash.events.*;
	import flash.net.*;
	import partition.Layout;
	import common.AlertManager;
	
	// 環境設定の画面モード編集（ビュー）用コンポーネントセットを複数格納するコンテナ
	public class LayoutComponentsCon extends Sprite {
		
		private var m_arr:Array;
		private const PAD = 10;
		private var so_layoutHashArr:SharedObject = null;
		
		public function LayoutComponentsCon() {
			m_arr = new Array();
		}
		public function addLayoutCompo( layoutCompo:LayoutComponents) {
			m_arr.push( layoutCompo);
			addChild( layoutCompo);
			layoutCompo.addEventListener( DrawerEvent.CONTENTS_H_CHANGED, onSizeChanged);
			layoutCompo.addEventListener( LayoutComponents.CLICK_SAVE, onClickUpdate); // 更新
			layoutCompo.addEventListener( LayoutComponents.CLICK_DEL, onClickDel); // 削除
			
			replace();
		}
		
		public function setLayoutHashArrSo( so_layoutHashArr:SharedObject) {
			// 全画面モードの全情報（連想配列の配列）
			this.so_layoutHashArr = so_layoutHashArr;
			//if( so_layoutHashArr == null) so_layoutHashArr = SharedObject.getRemote( Main.CONF.SO_NAME_LAYOUT_HASH_ARR, nc.uri, false);
			//so_layoutHashArr.connect( nc);
		}
		function onClickUpdate( e:Event) {
			// MainのonSyncLayoutHashArrを更新すれば、Mainが更新イベントを監視しているのでぜんぶやってくれるはず。
			var layoutCompo:LayoutComponents = LayoutComponents( e.target);
			var updatedLayout:Layout = layoutCompo.getLayout();
			
			if( so_layoutHashArr != null && so_layoutHashArr.data.hashArr != undefined) {
				var oldArr:Array = so_layoutHashArr.data.hashArr;
				var newArr:Array = new Array();
				for each( var old:Object in oldArr) {
					if( old.createDate == updatedLayout.createDate) {
						// 更新されたレイアウト
						newArr.push( updatedLayout.getDataHash());
msgDialog( Main.LANG.getParam( "保存しました"));
					} else {
						newArr.push( old);
					}
				}
				so_layoutHashArr.data.hashArr = newArr;
				so_layoutHashArr.setDirty( "hashArr");
			} else {
				alertDialog( Main.LANG.getParam( "通信エラーにより、変更を反映できませんでした"));
			}
			
			// とりあえず全部閉じる
			for( var i = 0; i < m_arr.length; i++) {
				var lc:LayoutComponents = m_arr[ i];
				lc.close();
			}
			// settingContentsに知らせる
			dispatchEvent( new Event( "scrollup"));
			
			// settingContentsのdrawer04:Drawerに知らせる
			dispatchEvent( new DrawerEvent( DrawerEvent.CONTENTS_H_CHANGED, getViewHeight()));
			
		}
		function onClickDel( e:Event) {
//alertDialog( "DBからの削除はLayoutComponentsクラス内でやっているが、SOへの反映（とプルダウンへの反映）がまだ。");
			// MainのonSyncLayoutHashArrを更新すれば、Mainが更新イベントを監視しているのでぜんぶやってくれるはず。
			var layoutCompo:LayoutComponents = LayoutComponents( e.target);
			var updatedLayout:Layout = layoutCompo.getLayout();
			
			if( so_layoutHashArr != null && so_layoutHashArr.data.hashArr != undefined) {
				var oldArr:Array = so_layoutHashArr.data.hashArr;
				var newArr:Array = new Array();
				for each( var old:Object in oldArr) {
					if( old.createDate == updatedLayout.createDate) {
						// 削除されたレイアウト
						continue;
					} else {
						newArr.push( old);
					}
				}
				so_layoutHashArr.data.hashArr = newArr;
				so_layoutHashArr.setDirty( "hashArr");
			} else {
				alertDialog( Main.LANG.getParam( "通信エラーにより、変更を反映できませんでした"));
			}
			
			// 表示内容を変更
			// とりあえず全部閉じて、対象のやつは配列から削除
			for( var i = 0; i < m_arr.length; i++) {
				var lc:LayoutComponents = m_arr[ i];
				lc.close();
				if( lc == layoutCompo) {
					m_arr.splice( i, 1); // 削除
					if( contains( layoutCompo)) removeChild( layoutCompo);
					i--;
				}
			}
			replace();
			
			// settingContentsに知らせる
			dispatchEvent( new Event( "scrollup"));
			
			// settingContentsのdrawer04:Drawerに知らせる
			dispatchEvent( new DrawerEvent( DrawerEvent.CONTENTS_H_CHANGED, getViewHeight()));
		}
		function onSizeChanged( e:DrawerEvent) {
			replace();
			
			// settingContentsのdrawer04:Drawerに知らせる
			dispatchEvent( new DrawerEvent( DrawerEvent.CONTENTS_H_CHANGED, getViewHeight()));
		}
		function replace() {
			var posi_y:Number = 0;
			for( var i = 0; i < m_arr.length; i++) {
				var layoutCompo:LayoutComponents = m_arr[ i];
				layoutCompo.y = posi_y;
				posi_y += layoutCompo.H + PAD;
			}
		}
		public function getViewHeight() : Number {
			// 全LayoutComponentsの高さを足した合計
			var ttlHeight: Number = 0;
			for each( var layoutCompo:LayoutComponents in m_arr) {
				ttlHeight += layoutCompo.H + PAD;
			}
			return ttlHeight;
		}
		function alertDialog( str:String) {
			Main.addErrMsg( "LayoutComponentsCon:" + str);
		}
		function msgDialog( str:String) {
			AlertManager.createAlert( this , str);
		}
	}
}

