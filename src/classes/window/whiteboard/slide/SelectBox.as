﻿package window.whiteboard.slide {	import flash.display.*;	import flash.events.*;	import flash.geom.*;		// ペイントパーツを選択したときに現れる四角いボックス。	// こいつ自身をマウスドラッグすることで、親（ペイントパーツ）の位置やサイズを変更させたりする	public class SelectBox extends Sprite {		static public const POSI_CHANGE:String = "POSI_CHANGE";		static public const SIZE_CHANGE:String = "SIZE_CHANGE";				private const SMALL_BOX_SIZE:Number = 5;				private var m_color:uint;		private var m_base:Shape;		private var m_topleft:Sprite;		private var m_topright:Sprite;		private var m_btmleft:Sprite;		private var m_btmright:Sprite;		private var m_mid:Sprite;				//private var m_x0:Number;		//private var m_y0:Number;		private var m_mouseX0:Number;		private var m_mouseY0:Number;		private var m_w0:Number;		private var m_h0:Number;		private var m_xBias:Number;		private var m_yBias:Number;				private var m_scaleCheck:Sprite; // 各ペイントパーツのスケールチェック用のコンテナ				private var m_paintPartsArr:Array; // WbSlideにてクリックで選択されたペイントパーツの配列		private var m_paintPartsArr_keep:Array; // ペイントパーツの配列（ドラッグ完了後はm_paintPartsArrは空になってしまうため）		private var m_oldPpParamArr:Array; // リサイズ開始直前の、ペイントパーツの位置とスケールの配列（MouseMove中の計算時用）				public function SelectBox( scaleCheck:Sprite, color:uint = 0x00cc00) {			m_scaleCheck = scaleCheck;			m_color = color;						m_base = Shape( addChild( new Shape()));			m_topleft = Sprite( addChild( getSmallBox()));			m_topright = Sprite( addChild( getSmallBox()));			m_btmleft = Sprite( addChild( getSmallBox()));			m_btmright = Sprite( addChild( getSmallBox()));			m_mid = Sprite( addChild( getSmallBox()));						m_mid.addEventListener( MouseEvent.MOUSE_DOWN, ready4Drag);			m_btmright.addEventListener( MouseEvent.MOUSE_DOWN, ready4Resize_btmright);			m_btmleft.addEventListener( MouseEvent.MOUSE_DOWN, ready4Resize_btmleft);			m_topleft.addEventListener( MouseEvent.MOUSE_DOWN, ready4Resize_topleft);			m_topright.addEventListener( MouseEvent.MOUSE_DOWN, ready4Resize_topright);						m_paintPartsArr = new Array();			m_paintPartsArr_keep = new Array();			m_oldPpParamArr = new Array();					}		function ready4Resize_common( basePoint:Sprite) {						while( m_paintPartsArr_keep.length) m_paintPartsArr_keep.pop();			while( m_oldPpParamArr.length) m_oldPpParamArr.pop();			for each( var pp:PaintParts in m_paintPartsArr) {				// キープ用のペイントパーツ配列の取得し直し				m_paintPartsArr_keep.push( pp);				// 保存用のペイントパーツパラメータの取得し直し				var keep_scaleX = pp.scaleX;				var keep_scaleY = pp.scaleY;				pp.scaleX = pp.scaleY = 1;				var rect:Rectangle = pp.getBounds( pp);				m_oldPpParamArr.push( { 									 x:pp.getPaintPartsData().posi_x,									 y:pp.getPaintPartsData().posi_y,									 rect_x_scale1:rect.x,									 rect_y_scale1:rect.y,									 scaleX:pp.getPaintPartsData().scaleX,									 scaleY:pp.getPaintPartsData().scaleY									 });				pp.scaleX = keep_scaleX;				pp.scaleY = keep_scaleY;			}			// マウスのスタート位置を記憶しておく			m_mouseX0 = mouseX;			m_mouseY0 = mouseY;						// リサイズ前のサイズを記憶しておく			m_w0 = m_topright.x - m_topleft.x;			m_h0 = m_btmright.y - m_topright.y;						m_xBias = basePoint.x - mouseX;			m_yBias = basePoint.y - mouseY;		}		// 右下の四角BOXを押下時、リサイズの準備をする		function ready4Resize_btmright( e:MouseEvent) {			ready4Resize_common( m_btmright);			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_btmright);			stage.addEventListener( MouseEvent.MOUSE_UP, stopResize);			stage.addEventListener( MouseEvent.ROLL_OUT, stopResize);		}		// 右上の四角BOXを押下時、リサイズの準備をする		function ready4Resize_topright( e:MouseEvent) {			ready4Resize_common( m_topright);			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_topright);			stage.addEventListener( MouseEvent.MOUSE_UP, stopResize);			stage.addEventListener( MouseEvent.ROLL_OUT, stopResize);		}		// 左下の四角BOXを押下時、リサイズの準備をする		function ready4Resize_btmleft( e:MouseEvent) {			ready4Resize_common( m_btmleft);			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_btmleft);			stage.addEventListener( MouseEvent.MOUSE_UP, stopResize);			stage.addEventListener( MouseEvent.ROLL_OUT, stopResize);		}		// 左上の四角BOXを押下時、リサイズの準備をする		function ready4Resize_topleft( e:MouseEvent) {			ready4Resize_common( m_topleft);			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_topleft);			stage.addEventListener( MouseEvent.MOUSE_UP, stopResize);			stage.addEventListener( MouseEvent.ROLL_OUT, stopResize);		}				function onMouseMove_common01( new_w_all, new_h_all) {			// ベースの枠を描き直す			m_base.graphics.clear();			m_base.graphics.lineStyle( 1, m_color, 1, false, "none");			m_base.graphics.drawRect( 0, 0, new_w_all, new_h_all);						m_base.x = m_topleft.x;			m_base.y = m_topleft.y;		}		function onMouseMove_common02( pp:PaintParts, oldPpParam:Object, new_scaleX_all:Number, new_scaleY_all:Number):Array {						// リサイズ前の見た目上のサイズ（size*scale）			var old_w:Number = pp.getPaintPartsData().size_w * oldPpParam.scaleX;			var old_h:Number = pp.getPaintPartsData().size_h * oldPpParam.scaleY;						// 新しい見た目上のサイズ			var new_w:Number = old_w * new_scaleX_all;			var new_h:Number = old_h * new_scaleY_all;			// 新しい見た目上のサイズとデフォルトサイズから、新しいスケールを算出			var new_scaleX:Number = new_w / pp.getPaintPartsData().size_w;			var new_scaleY:Number = new_h / pp.getPaintPartsData().size_h;						return [ new_scaleX, new_scaleY];		}				function onMouseMove_common03( pp:PaintParts, oldPpParam, new_scaleX:Number, new_scaleY:Number, _lastUpdateTime:Number) {			// スケールと位置を更新			pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新			//TODO							//複数のときにうまくいかないよー			// 位置調整			var new_x_scale1:Number = m_topleft.x - oldPpParam.rect_x_scale1 * new_scaleX;			var new_y_scale1:Number = m_topleft.y - oldPpParam.rect_y_scale1 * new_scaleY;						var dx = new_x_scale1 - oldPpParam.x;			var dy = new_y_scale1 - oldPpParam.y;						//var dx_selfsizechange = 						var new_x:Number = oldPpParam.x + dx / m_scaleCheck.scaleX;			var new_y:Number = oldPpParam.y + dy / m_scaleCheck.scaleY;			pp.setPosi( new_x, new_y);						pp.setUpdateTime( _lastUpdateTime);						// 終了後用のペイントパーツにも値の変更を反映させる			for each( var _pp:PaintParts in m_paintPartsArr_keep) {							if( _pp.id == pp.id) {					_pp.setScale( new_scaleX, new_scaleY);					_pp.setPosi( new_x, new_y);					_pp.setUpdateTime( _lastUpdateTime);					break;				}			}		}/*		function onMouseMove_common03( pp:PaintParts, new_x, new_y, new_scaleX:Number, new_scaleY:Number, _lastUpdateTime:Number) {			// スケールと位置を更新			pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新						pp.setPosi( new_x, new_y);						pp.setUpdateTime( _lastUpdateTime);						// 終了後用のペイントパーツにも値の変更を反映させる			for each( var _pp:PaintParts in m_paintPartsArr_keep) {							if( _pp.id == pp.id) {					_pp.setScale( new_scaleX, new_scaleY);					_pp.setPosi( new_x, new_y);					_pp.setUpdateTime( _lastUpdateTime);					break;				}			}		}*/		// 右下の四角BOX、リサイズ中		function onMouseMove_btmright( e:MouseEvent) {			m_btmright.x = mouseX + m_xBias;			m_btmright.y = mouseY + m_yBias;						// マイナスにはならないように最小サイズで制限する// TODO						// 対角の四角BOX以外を動かす			m_topright.x = m_btmright.x;			m_btmleft.y = m_btmright.y;			m_mid.x = m_btmleft.x + ( m_btmright.x - m_btmleft.x) / 2;			m_mid.y = m_topright.y + ( m_btmright.y - m_topright.y) / 2;						// 新しいサイズ（全体）			var new_w_all:Number = m_btmright.x - m_btmleft.x;			var new_h_all:Number = m_btmright.y - m_topright.y;						// リサイズ前から見た、新しい見た目上のスケール（全体）			var new_scaleX_all:Number = new_w_all / m_w0;			var new_scaleY_all:Number = new_h_all / m_h0;//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", String(new_scaleX_all) + "," + String(new_scaleY_all));						// ベースの枠を描き直す			onMouseMove_common01( new_w_all, new_h_all);						// ペイントパーツを拡大縮小する			// 見た目上変えるだけで、共有オブジェクトはまだ変更しない			var _lastUpdateTime = ( new Date()).getTime();			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				var pp:PaintParts = m_paintPartsArr[ i];				var oldPpParam:Object = m_oldPpParamArr[ i];				// 新しい見た目上のサイズとデフォルトサイズから、新しいスケールを算出				var arr = onMouseMove_common02( pp, oldPpParam, new_scaleX_all, new_scaleY_all);				var new_scaleX = arr[0];				var new_scaleY = arr[1];				//pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新																//var dx = w1 - w2;				// topleftからの距離：デフォルトサイズ時				var w1 = oldPpParam.x - oldPpParam.rect_x_scale1;				var h1 = oldPpParam.y - oldPpParam.rect_y_scale1;								// topleftからの距離：スケール変更後				var w2 = w1 * new_scaleX;				var h2 = h1 * new_scaleY;				//var dx = w2 - w1;				//var dy = h2 - h1;								//var new_x = oldPpParam.x + dx / m_scaleCheck.scaleX;				//var new_y = oldPpParam.y + dy / m_scaleCheck.scaleY;				//var new_x = m_topleft.x + w2 / m_scaleCheck.scaleX;				//var new_y = m_topleft.y + h2 / m_scaleCheck.scaleY;				var new_x = m_topleft.x + w2;				var new_y = m_topleft.y + h2;								var dx = new_x - oldPpParam.x;				var dy = new_y - oldPpParam.y;								new_x = oldPpParam.x + dx / m_scaleCheck.scaleX;				new_y = oldPpParam.y + dy / m_scaleCheck.scaleY;								//var pt_selectbox:Point = new Point();				//m_topleft.localToGlobal( 												// スケールと位置を更新				//onMouseMove_common03( pp, new_x, new_y, new_scaleX, new_scaleY, _lastUpdateTime);				onMouseMove_common03( pp, oldPpParam, new_scaleX, new_scaleY, _lastUpdateTime);							}		}				// 右上の四角BOX、リサイズ中		function onMouseMove_topright( e:MouseEvent) {			m_topright.x = mouseX + m_xBias;			m_topright.y = mouseY + m_yBias;						// マイナスにはならないように最小サイズで制限する// TODO						// 対角の四角BOX以外を動かす			m_btmright.x = m_topright.x;			m_topleft.y = m_topright.y;			m_mid.x = m_btmleft.x + ( m_btmright.x - m_btmleft.x) / 2;			m_mid.y = m_topright.y + ( m_btmright.y - m_topright.y) / 2;						// 新しいサイズ（全体）			var new_w_all:Number = m_btmright.x - m_btmleft.x;			var new_h_all:Number = m_btmright.y - m_topright.y;						// リサイズ前から見た、新しい見た目上のスケール（全体）			var new_scaleX_all:Number = new_w_all / m_w0;			var new_scaleY_all:Number = new_h_all / m_h0;//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", String(new_scaleX_all) + "," + String(new_scaleY_all));						// ベースの枠を描き直す			onMouseMove_common01( new_w_all, new_h_all);						// ペイントパーツを拡大縮小する			// 見た目上変えるだけで、共有オブジェクトはまだ変更しない			var _lastUpdateTime = ( new Date()).getTime();			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				var pp:PaintParts = m_paintPartsArr[ i];				var oldPpParam:Object = m_oldPpParamArr[ i];				// 新しい見た目上のサイズとデフォルトサイズから、新しいスケールを算出				var arr = onMouseMove_common02( pp, oldPpParam, new_scaleX_all, new_scaleY_all);				var new_scaleX = arr[0];				var new_scaleY = arr[1];				//pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新								// マウスの移動量				var mouseDx = mouseX - m_mouseX0;				var mouseDy = mouseY - m_mouseY0;								var new_x = oldPpParam.x;				var new_y = oldPpParam.y;								// スケールと位置を更新				//onMouseMove_common03( pp, new_x, new_y, new_scaleX, new_scaleY, _lastUpdateTime);				onMouseMove_common03( pp, oldPpParam, new_scaleX, new_scaleY, _lastUpdateTime);			}		}		// 左上の四角BOX、リサイズ中		function onMouseMove_topleft( e:MouseEvent) {			m_topleft.x = mouseX + m_xBias;			m_topleft.y = mouseY + m_yBias;						// マイナスにはならないように最小サイズで制限する// TODO						// 対角の四角BOX以外を動かす			m_btmleft.x = m_topleft.x;			m_topright.y = m_topleft.y;			m_mid.x = m_btmleft.x + ( m_btmright.x - m_btmleft.x) / 2;			m_mid.y = m_topright.y + ( m_btmright.y - m_topright.y) / 2;						// 新しいサイズ（全体）			var new_w_all:Number = m_btmright.x - m_btmleft.x;			var new_h_all:Number = m_btmright.y - m_topright.y;						// リサイズ前から見た、新しい見た目上のスケール（全体）			var new_scaleX_all:Number = new_w_all / m_w0;			var new_scaleY_all:Number = new_h_all / m_h0;//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", String(new_scaleX_all) + "," + String(new_scaleY_all));						// ベースの枠を描き直す			onMouseMove_common01( new_w_all, new_h_all);						// ペイントパーツを拡大縮小する			// 見た目上変えるだけで、共有オブジェクトはまだ変更しない			var _lastUpdateTime = ( new Date()).getTime();			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				var pp:PaintParts = m_paintPartsArr[ i];				var oldPpParam:Object = m_oldPpParamArr[ i];				// 新しい見た目上のサイズとデフォルトサイズから、新しいスケールを算出				var arr = onMouseMove_common02( pp, oldPpParam, new_scaleX_all, new_scaleY_all);				var new_scaleX = arr[0];				var new_scaleY = arr[1];				//pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新								// マウスの移動量				var mouseDx = mouseX - m_mouseX0;				var mouseDy = mouseY - m_mouseY0;								var new_x = oldPpParam.x + mouseDx;				var new_y = oldPpParam.y + mouseDy;								// スケールと位置を更新				//onMouseMove_common03( pp, new_x, new_y, new_scaleX, new_scaleY, _lastUpdateTime);				onMouseMove_common03( pp, oldPpParam, new_scaleX, new_scaleY, _lastUpdateTime);			}		}		// 左下の四角BOX、リサイズ中		function onMouseMove_btmleft( e:MouseEvent) {			m_btmleft.x = mouseX + m_xBias;			m_btmleft.y = mouseY + m_yBias;						// マイナスにはならないように最小サイズで制限する// TODO						// 対角の四角BOX以外を動かす			m_topleft.x = m_btmleft.x;			m_btmright.y = m_btmleft.y;			m_mid.x = m_btmleft.x + ( m_btmright.x - m_btmleft.x) / 2;			m_mid.y = m_topright.y + ( m_btmright.y - m_topright.y) / 2;						// 新しいサイズ（全体）			var new_w_all:Number = m_btmright.x - m_btmleft.x;			var new_h_all:Number = m_btmright.y - m_topright.y;						// リサイズ前から見た、新しい見た目上のスケール（全体）			var new_scaleX_all:Number = new_w_all / m_w0;			var new_scaleY_all:Number = new_h_all / m_h0;//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", String(new_scaleX_all) + "," + String(new_scaleY_all));						// ベースの枠を描き直す			onMouseMove_common01( new_w_all, new_h_all);						// ペイントパーツを拡大縮小する			// 見た目上変えるだけで、共有オブジェクトはまだ変更しない			var _lastUpdateTime = ( new Date()).getTime();			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				var pp:PaintParts = m_paintPartsArr[ i];				var oldPpParam:Object = m_oldPpParamArr[ i];				// 新しい見た目上のサイズとデフォルトサイズから、新しいスケールを算出				var arr = onMouseMove_common02( pp, oldPpParam, new_scaleX_all, new_scaleY_all);				var new_scaleX = arr[0];				var new_scaleY = arr[1];				//pp.setScale( new_scaleX, new_scaleY); // 位置より先にスケールを更新								// マウスの移動量				var mouseDx = mouseX - m_mouseX0;				var mouseDy = mouseY - m_mouseY0;								var new_x = oldPpParam.x + mouseDx;				var new_y = oldPpParam.y + mouseDy;								// スケールと位置を更新				//onMouseMove_common03( pp, new_x, new_y, new_scaleX, new_scaleY, _lastUpdateTime);				onMouseMove_common03( pp, oldPpParam, new_scaleX, new_scaleY, _lastUpdateTime);			}		}		// リサイズ終了（MOUSE_UPされているので、この時点でm_paintPartsArrは空っぽ）		function stopResize( e:MouseEvent) {			if( stage) {				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_btmright);				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_btmleft);				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_topright);				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMove_topleft);				stage.removeEventListener( MouseEvent.MOUSE_UP, stopResize);				stage.removeEventListener( MouseEvent.ROLL_OUT, stopResize);			}			// ペイントパーツの値変更情報を共有オブジェクトに反映させる			// WBSlide経由でWhiteboard経由でWhiteboardContainerに知らせる			dispatchEvent( new PaintPartsEvent( PaintPartsEvent.MULTI_CHANGE, m_paintPartsArr_keep));		}				// 中心の四角BOXを押下時、ドラッグの準備をする		function ready4Drag( e:MouseEvent) {			// キープ用のペイントパーツ配列の取得し直し			while( m_paintPartsArr_keep.length) m_paintPartsArr_keep.pop();			for each( var pp:PaintParts in m_paintPartsArr) {				m_paintPartsArr_keep.push( pp);			}						m_xBias = m_base.x - mouseX;			m_yBias = m_base.y - mouseY;						addEventListener( Event.ENTER_FRAME, onEnterFrame_drag);			stage.addEventListener( MouseEvent.MOUSE_UP, stop_drag);			stage.addEventListener( MouseEvent.ROLL_OUT, stop_drag);		}		// ドラッグ中		function onEnterFrame_drag( e:Event) {			var dx:Number = ( mouseX + m_xBias) - m_base.x;			var dy:Number = ( mouseY + m_yBias) - m_base.y;						// 選択BOXを動かす			m_base.x += dx;			m_base.y += dy;			m_topleft.x += dx;			m_topleft.y += dy;			m_topright.x += dx;			m_topright.y += dy;			m_btmleft.x += dx;			m_btmleft.y += dy;			m_btmright.x += dx;			m_btmright.y += dy;			m_mid.x += dx;			m_mid.y += dy;						// ペイントパーツを動かす			// 見た目上変えるだけで、共有オブジェクトはまだ変更しない			var _lastUpdateTime = ( new Date()).getTime();			for each( var pp:PaintParts in m_paintPartsArr) {				var _x = pp.x + dx / m_scaleCheck.scaleX;				var _y = pp.y + dy / m_scaleCheck.scaleY;				pp.setPosi( _x, _y);				pp.setUpdateTime( _lastUpdateTime);								// ドラッグ終了後用のペイントパーツにも値の変更を反映させる				for each( var pp_drag:PaintParts in m_paintPartsArr_keep) {					if( pp_drag.id == pp.id) {						pp_drag.setPosi( _x, _y);						pp_drag.setUpdateTime( _lastUpdateTime);						break;					}				}			}		}				// ドラッグ終了（MOUSE_UPされているので、この時点でm_paintPartsArrは空っぽ）		function stop_drag( e:MouseEvent) {			removeEventListener( Event.ENTER_FRAME, onEnterFrame_drag);			if( stage) {				stage.removeEventListener( MouseEvent.MOUSE_UP, stop_drag);				stage.removeEventListener( MouseEvent.ROLL_OUT, stop_drag);			}			//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SelectBox:stop_drag() " + String( m_paintPartsArr_keep));			// ペイントパーツの値変更情報を共有オブジェクトに反映させる			// WBSlide経由でWhiteboard経由でWhiteboardContainerに知らせる			dispatchEvent( new PaintPartsEvent( PaintPartsEvent.MULTI_CHANGE, m_paintPartsArr_keep));			/*			for each( var pp_drag:PaintParts in m_paintPartsArr_keep) {				dispatchEvent( new PaintPartsEvent( PaintPartsEvent.CHANGED, pp_drag.getPaintPartsData()));			}*/		}				// ペイントパーツがクリックされたときにWbSlide:onClickPP()から呼ばれる		public function addPaintParts( pp:PaintParts) {			m_paintPartsArr.push( pp);			if( m_paintPartsArr.length > 1) {				m_paintPartsArr[0].setBoundsBox( true);				pp.setBoundsBox( true);			}			resetBox();		}				public function removePaintParts( pp:PaintParts) {			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				if( PaintParts( m_paintPartsArr[i]).id == pp.id) {					pp.setBoundsBox( false);					m_paintPartsArr.splice( i, 1);				}			}			resetBox();		}		public function isAdded( pp:PaintParts) : Boolean {			for( var i:uint = 0; i < m_paintPartsArr.length; i++) {				if( PaintParts( m_paintPartsArr[i]).id == pp.id) return true;			}			return false;		}				public function removeAllPaintParts() {			while( m_paintPartsArr.length) {				var pp = m_paintPartsArr.pop();				pp.setBoundsBox( false);			}			resetBox();		}				function resetBox() {						if( m_paintPartsArr.length == 0) {				m_base.graphics.clear();				m_topleft.visible = false;				m_topright.visible = false;				m_btmleft.visible = false;				m_btmright.visible = false;				m_mid.visible = false;				return;			} else if( m_paintPartsArr.length == 1) {				m_topleft.visible = true;				m_topright.visible = true;				m_btmleft.visible = true;				m_btmright.visible = true;				m_mid.visible = true;			} else {// TODO// 複数同時の拡大縮小がどうにもうまくいかないので、とりあえず4コーナーの□は非表示にしちゃう。				m_topleft.visible = false;				m_topright.visible = false;				m_btmleft.visible = false;				m_btmright.visible = false;				/*m_topleft.visible = true;				m_topright.visible = true;				m_btmleft.visible = true;				m_btmright.visible = true;*/				m_mid.visible = true;							}						//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SelectBox:resetBox() " + String( m_paintPartsArr.length));						// 全選択ペイントパーツの左上座標を求める			var posi_x:Number = Number.MAX_VALUE;			var posi_y:Number = Number.MAX_VALUE;			var pp:PaintParts;			var bounds:Rectangle;			for each( pp in m_paintPartsArr) {				bounds = pp.getBounds( pp.parent);				if( bounds.x < posi_x) posi_x = bounds.x;				if( bounds.y < posi_y) posi_y = bounds.y;			}//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SelectBox:resetBox() bounds.x:" + String( bounds.x) + " bounds.width:" + String( bounds.width));						// 全選択ペイントパーツのサイズを求める			var bounds_w:Number = 0;			var bounds_h:Number = 0;			for each( pp in m_paintPartsArr) {				bounds = pp.getBounds( pp.parent);				if( ( bounds.x + bounds.width) - posi_x > bounds_w) bounds_w = ( bounds.x + bounds.width) - posi_x;				if( ( bounds.y + bounds.height) - posi_y > bounds_h) bounds_h = ( bounds.y + bounds.height) - posi_y;			}			//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SelectBox:resetBox() x:" + String( _x) + " scale:" + m_scaleCheck.scaleX);				// 拡大縮小の影響を考慮			posi_x *= m_scaleCheck.scaleX;			posi_y *= m_scaleCheck.scaleY;			bounds_w *= m_scaleCheck.scaleX;			bounds_h *= m_scaleCheck.scaleY;						m_base.graphics.clear();			m_base.graphics.lineStyle( 1, m_color, 1, false, "none");			m_base.graphics.drawRect( 0, 0, bounds_w, bounds_h);			m_base.x = posi_x;			m_base.y = posi_y;						m_topleft.x = m_btmleft.x = posi_x;			m_topleft.y = m_topright.y = posi_y;			m_topright.x = m_btmright.x = posi_x + bounds_w;			m_btmleft.y = m_btmright.y = posi_y + bounds_h;						m_mid.x = posi_x + bounds_w / 2;			m_mid.y = posi_y + bounds_h / 2;					}		function getSmallBox() : Sprite {			var box:Sprite = new Sprite();			box.graphics.beginFill( 0xffffff);			box.graphics.lineStyle( 1, m_color, 1, false, "none");			box.graphics.drawRect( -SMALL_BOX_SIZE / 2, -SMALL_BOX_SIZE / 2, SMALL_BOX_SIZE, SMALL_BOX_SIZE);			box.graphics.endFill();			box.visible = false;			box.buttonMode = true;			return box;		}	}}