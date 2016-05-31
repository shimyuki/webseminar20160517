package window.whiteboard {
	import common.SimpleScrollBar;
    import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	import common.AlertManager;
	
    public class WbScrollBar extends Sprite {
		private const TARGET_PADDING_BTM = 0;
		static public var SIZE = SimpleScrollBar.SIZE;

		private var scrollTarget;
		public var scrollMask;
		private var m_base:Sprite;
		private var m_handle:Sprite;
		private var m_up:ScrollUp;
		private var m_down:ScrollDown;
		private var m_bar:Bar;
		private var m_scrollTarget_initY:Number;
		
		//private var test_text;
		
		public function WbScrollBar( ) {
			if( Main.CONF.TERMINAL == Main.TERMINAL_ANDROID) {
				SIZE = SimpleScrollBar.SIZE_ANDROID;
			}
			// ベース
			m_base = addChild( new Sprite()) as Sprite;
			m_base.graphics.beginFill( 0xcccccc);
			m_base.graphics.drawRect( 0, 0, SIZE, 50);
			m_base.graphics.endFill();
			m_base.graphics.beginFill( 0xe7e7e7);
			m_base.graphics.drawRect( 1, 1, SIZE-2, 48);
			m_base.graphics.endFill();
			
			// 矢印ボタン
			m_up = addChild( new ScrollUp()) as ScrollUp;
			m_down = addChild( new ScrollDown()) as ScrollDown;
			m_down.y = m_base.height - m_down.height;
			
			// バー
			m_bar = new Bar( 1, m_up.y + m_up.height + 1, SIZE-1, 25);
			m_bar.addEventListener( "barChange", onBarChange);
			
//			test_text = addChild( new TextField());
//			test_text.x = -200;
//			test_text.width = 200;
			
		}
		public function setScrollTarget( _scrollTarget) {
			scrollTarget = _scrollTarget;
			m_scrollTarget_initY = scrollTarget.y;

//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:setScrollTarget():koko");
		}
		public function setSize( w:Number, h:Number) {
			//var pre_baseH:Number = m_base.height - m_up.height - m_down.height - 2;
			
			//width = w;
			//m_base.height = h;
			
			w -= 0.5;
			m_base.graphics.clear();
			//m_base.graphics.lineStyle( 1, 0xcccccc, 1, false, LineScaleMode.HORIZONTAL);
			m_base.graphics.beginFill( 0xcccccc);
			m_base.graphics.drawRect( 0, 0, w, h);
			m_base.graphics.endFill();
			m_base.graphics.beginFill( 0xe7e7e7);
			m_base.graphics.drawRect( 1, 1, w - 2, h - 2);
			m_base.graphics.endFill();
			
			m_down.y = h - m_down.height;
			var new_baseH:Number = m_base.height - m_up.height - m_down.height - 2;
			
//if(new_baseH != pre_baseH) if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:setSize():koko");
			m_bar.init( new_baseH);
			
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:setSize():" + new_baseH);
		}
		public function update() {
			if( scrollTarget == undefined || scrollMask == undefined) return;
			
			if( scrollMask.height >= scrollTarget.height + TARGET_PADDING_BTM) {
				m_up.setEnable( false);
				m_down.setEnable( false);
				if( contains( m_bar)) removeChild( m_bar);
				
				// 領域内に収まっていても、同期はとる必要があるので、dispatch
				dispatchEvent( new Event( "updated"));
				return;
			}
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollMask.y) +","+ String(scrollTarget.y));			
			//m_base.buttonMode = true;
			m_up.addEventListener( MouseEvent.CLICK, onClickUp);
			m_down.addEventListener( MouseEvent.CLICK, onClickDown);
			m_base.addEventListener( MouseEvent.CLICK, onClickBase);

			//m_scrollTarget_initY = scrollTarget.y;
			
			m_up.setEnable( true);
			m_down.setEnable( true);
			if( ! contains( m_bar)) addChild( m_bar);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollMask.height) + String(scrollTarget.height));
			m_bar.init( m_base.height - m_up.height - m_down.height - 2, scrollMask.height / ( scrollTarget.height + TARGET_PADDING_BTM));
			
			// バーのY位置も変える
			var baseH = m_base.height - m_up.height - m_down.height - 2;
			var barH = m_bar.height;
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollMask.y) +","+ String(scrollTarget.y));
			m_bar.setY( m_bar.getMinY() + ( baseH - barH) * ( scrollMask.y - scrollTarget.y) / ( scrollTarget.height + TARGET_PADDING_BTM - scrollMask.height));
			
		}
		
		// 同期モード用
		public function setScrollTargetPosi( _y:Number) {
			scrollTarget.y = _y;
			//update(); // これをやっちゃうとバウンド現象が起こる

			if( scrollMask.height >= scrollTarget.height + TARGET_PADDING_BTM) {
				m_up.setEnable( false);
				m_down.setEnable( false);
				if( contains( m_bar)) removeChild( m_bar);
				return;
			}
			//if( ! contains( m_bar)) addChild( m_bar);
			m_bar.init( m_base.height - m_up.height - m_down.height - 2, scrollMask.height / ( scrollTarget.height + TARGET_PADDING_BTM));
			
			// バーのY位置も変える
			var baseH = m_base.height - m_up.height - m_down.height - 2;
			var barH = m_bar.height;
			m_bar.y = m_bar.getMinY() + ( baseH - barH) * ( scrollMask.y - scrollTarget.y) / ( scrollTarget.height + TARGET_PADDING_BTM - scrollMask.height);
			//var ratio = barH / baseH;
			//scrollTarget.y = m_scrollTarget_initY - ( scrollTarget.height + TARGET_PADDING_BTM - scrollMask.height) * ratio;
		}
		
		// 同期モード用
		public function getScrollTargetPosi() : Number {
			return scrollTarget.y;
		}
		
		function onClickUp( e:MouseEvent) { if( contains( m_bar)) m_bar.setY( m_bar.y - 5);}
		function onClickDown( e:MouseEvent) { if( contains( m_bar)) m_bar.setY( m_bar.y + 5);}
		//function onClickBase( e:MouseEvent) { if( contains( m_bar)) m_bar.setY( m_bar.y + ( mouseY - m_bar.y)/2);}
		function onClickBase( e:MouseEvent) {
			if( contains( m_bar)) {
				if( mouseY < m_bar.y) m_bar.setY( mouseY);
				else m_bar.setY( mouseY - m_bar.height);
			}
		}
		function onBarChange( e:BarEvent) {
			if( visible == false) return; // 同期モード時の受講生対策
			scrollTarget.y = m_scrollTarget_initY - ( scrollTarget.height + TARGET_PADDING_BTM - scrollMask.height) * e.ratio;
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:onBarChange():" + String(scrollTarget.y));
			dispatchEvent( new Event( "updated"));
		}
		
		// この関数は、scrollTargetを強制的にトップに移動させたときに、明示的に呼んでください。
		// バーの位置を強制的にトップに戻します。
		public function setBarYMin() {
			m_bar.setYMin();
		}
	}
}


import common.AlertManager;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import window.whiteboard.WbScrollBar;

class Bar extends Sprite {
	private var m_base_height:Number;
	private var MIN_Y:Number;
	
	private var m_clickMouseY:Number;
	private var m_preY:Number;
		
	public function Bar( posi_x:Number, posi_y:Number, w:Number, h:Number) {
		// グラデーション
		var fillType:String = GradientType.LINEAR;
		var colors:Array = [ 0xB3DCF3, 0x6ABAE8];
		var alphas:Array = [1, 1];
		var ratios:Array = [0x00, 0xFF];
		var matr:Matrix = new Matrix();
		matr.createGradientBox( w, h);
			
		graphics.beginGradientFill( fillType, colors, alphas, ratios, matr, SpreadMethod.PAD);
		graphics.drawRect( 0, 0, w, h);
		graphics.endFill();
		x = posi_x;
		y = MIN_Y = posi_y;
		//buttonMode = true;
		addEventListener( MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			m_clickMouseY = stage.mouseY;
			m_preY = y;
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveScroll);
		});
		
		addEventListener( Event.ADDED_TO_STAGE, function(e:*) {
			stage.addEventListener( MouseEvent.MOUSE_UP, function(e:*) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveScroll);
			});
			stage.addEventListener( MouseEvent.MOUSE_OUT, function(e:*) {
				//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title", stage.mouseX + " / " + stage.stageWidth);
				if( stage.mouseX < 0 || stage.mouseX > stage.stageWidth) stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveScroll);
			});
		});
		
		alpha = 0.85;
		addEventListener( MouseEvent.ROLL_OVER, function(e:MouseEvent) {
			alpha = 1;
		});
		addEventListener( MouseEvent.ROLL_OUT, function(e:MouseEvent) {
			alpha = 0.85;
		});
	}
	
	public function init( base_height:Number, ratio:Number = 0.5) {
		m_base_height = base_height;
		height = m_base_height * ratio;
	}
	
	// ドラッグ
	function onMouseMoveScroll( e:MouseEvent) {
		setY( m_preY + stage.mouseY - m_clickMouseY);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Bar:onMouseMoveScroll():" + String( m_preY + stage.mouseY - m_clickMouseY));
		//e.updateAfterEvent();
	}
	public function setY( posi_y:Number) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Bar:setY():" + posi_y);
		y = posi_y;
		checkPosition();
		dispatchEvent( new BarEvent( "barChange", y - MIN_Y, m_base_height - height));
	}
	
	public function getMinY():Number { return MIN_Y;}
	//public function getMinY():Number { return MIN_Y;}

	// バーの位置調整
	function checkPosition() {
		if( y < MIN_Y) y = MIN_Y;
		if( y > MIN_Y + m_base_height - height) y = MIN_Y + m_base_height - height;
	}

	public function setYMin() {
		y = MIN_Y;
	}
	
}

class BarEvent extends Event {
	public var ratio:Number;
	public function BarEvent( type:String, posi_y:Number, ttl_height:Number) {
		super( type);
		ratio = posi_y / ttl_height;
	}
}

class ScrollBtnBase extends Sprite {
	protected var arrow:Bitmap;
	public function ScrollBtnBase() {
		
		// グラデーション
		var fillType:String = GradientType.LINEAR;
		var colors:Array = [ 0xffffff, 0xe6e6e6];
		var alphas:Array = [1, 1];
		var ratios:Array = [0x00, 0xFF];
		var matr:Matrix = new Matrix();
		matr.createGradientBox( WbScrollBar.SIZE, WbScrollBar.SIZE-1 , Math.PI/2, 0, 0);
		
		graphics.lineStyle( 1, 0xcccccc, 1, false, LineScaleMode.NONE);
		graphics.beginGradientFill( fillType, colors, alphas, ratios, matr, SpreadMethod.PAD);
		graphics.drawRect( 0, 0, WbScrollBar.SIZE, WbScrollBar.SIZE-1);
		graphics.endFill();
		
		// 矢印
		var color = 0xff999999;
		var bmpArrow:BitmapData = new BitmapData( 7, 4, true, 0);
		bmpArrow.setPixel32( 3, 0, color);
		var i:uint;
		for( i = 2; i <= 4; i++) { bmpArrow.setPixel32( i, 1, color);}
		for( i = 1; i <= 5; i++) { bmpArrow.setPixel32( i, 2, color);}
		for( i = 0; i <= 6; i++) { bmpArrow.setPixel32( i, 3, color);}
		arrow = new Bitmap( bmpArrow);
		arrow.x = 4;
		arrow.y = 4;
		
		if( Main.CONF.TERMINAL == Main.TERMINAL_ANDROID) {
			arrow.scaleX = arrow.scaleY = 2;
			arrow.smoothing = true;
			arrow.x = 8;
			arrow.y = 9;
		}
	}
	public function setEnable( b:Boolean) {
		//buttonMode = b;
		if( b) {
			if( ! contains( arrow)) addChild( arrow);
		} else {
			if( contains( arrow)) removeChild( arrow);
		}
	}
}

class ScrollUp extends ScrollBtnBase {
	public function ScrollUp() {
		super();
	}
}

class ScrollDown extends ScrollBtnBase {
	public function ScrollDown() {
		super();
		
		// 矢印の向き反転
		arrow.rotation = 180;		
		arrow.x = 11;
		arrow.y = 9;
		
		if( Main.CONF.TERMINAL == Main.TERMINAL_ANDROID) {
			arrow.x = 24;
			arrow.y = 19;
		}
	}
}






