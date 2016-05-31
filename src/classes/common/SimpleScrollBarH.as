package common {
    import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.text.*;
	
    public class SimpleScrollBarH extends Sprite {
		private const TARGET_PADDING_RIGHT = 0;
		static public var SIZE = 14;

		private var scrollTarget;
		public var scrollMask;
		private var m_base:Sprite;
		private var m_handle:Sprite;
		private var m_up:ScrollUp;
		private var m_down:ScrollDown;
		private var m_bar:Bar;
		private var m_scrollTarget_initX:Number;
		private var m_ttlW:Number;
		
		//private var test_text;
		
		public function SimpleScrollBarH( ) {
			// ベース
			m_base = addChild( new Sprite()) as Sprite;
			//m_base.graphics.lineStyle( 1, 0xcccccc, 1, false, LineScaleMode.NONE);
			m_base.graphics.beginFill( 0xcccccc);
			m_base.graphics.drawRect( 0, 0, 50, SIZE);
			m_base.graphics.endFill();
			m_base.graphics.beginFill( 0xe7e7e7);
			m_base.graphics.drawRect( 1, 1, 48, SIZE-2);
			m_base.graphics.endFill();
			
			// 矢印ボタン
			m_up = addChild( new ScrollUp()) as ScrollUp;
			m_down = addChild( new ScrollDown()) as ScrollDown;
			m_down.x = m_base.width - m_down.width;
			
			// バー
			m_bar = new Bar( m_up.x + m_up.width + 1, 1, 25, SIZE-1);
			m_bar.addEventListener( "barChange", onBarChange);
			
//			test_text = addChild( new TextField());
//			test_text.x = -200;
//			test_text.width = 200;
			
		}
		public function setScrollTarget( _scrollTarget) {
			scrollTarget = _scrollTarget;
			m_scrollTarget_initX = scrollTarget.x;
			
			m_ttlW = scrollTarget.width;

//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:setScrollTarget():koko");
		}
		public function setSize( w:Number, h:Number) {
			
			//m_base.width = w;
			//height = h;
			h -= 0.5;
			m_base.graphics.clear();
			//m_base.graphics.lineStyle( 1, 0xcccccc, 1, false, LineScaleMode.HORIZONTAL);
			m_base.graphics.beginFill( 0xcccccc);
			m_base.graphics.drawRect( 0, 0, w, h);
			m_base.graphics.endFill();
			m_base.graphics.beginFill( 0xe7e7e7);
			m_base.graphics.drawRect( 1, 1, w - 2, h - 2);
			m_base.graphics.endFill();
						
			m_down.x = w - m_down.width;
			//m_base.x = m_up.x + m_up.width;
			//m_base.width = m_down.x - m_up.x -  m_up.width;
			var new_baseW:Number = m_base.width - m_up.width - m_down.width - 2;
			
			m_bar.init( new_baseW);
			
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:setSize():" + new_baseH);
		}
		public function update() {
			if( scrollTarget == undefined || scrollMask == undefined) return;
			
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollMask.width) +","+ String(scrollTarget.width))
			//if( scrollMask.width >= scrollTarget.width + TARGET_PADDING_RIGHT) {
			if( scrollMask.width >= scrollTarget.width) {
				// マスク幅よりも小さい場合はスクロールバーは表示しない
				m_up.setEnable( false);
				m_down.setEnable( false);
				if( contains( m_bar)) removeChild( m_bar);
				return;
			}
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollMask.y) +","+ String(scrollTarget.y));			
			//m_base.buttonMode = true;
			m_up.addEventListener( MouseEvent.CLICK, onClickUp);
			m_down.addEventListener( MouseEvent.CLICK, onClickDown);
			m_base.addEventListener( MouseEvent.CLICK, onClickBase);

			
			
			m_up.setEnable( true);
			m_down.setEnable( true);
			if( ! contains( m_bar)) addChild( m_bar);
			
/*				// 全体の長さ
			m_ttlW = updateTotalWidth();
			m_bar.init( m_base.width - m_up.width - m_down.width - 2, scrollMask.width / m_ttlW);
			
			var yohaku:Number; // 余白
			if( scrollTarget.x > 0) {
				// 右側に、はみ出している
				
				
			} else if ( scrollTarget.x + scrollTarget.width < scrollMask.width) {
				// 左側にのみ、はみ出している
				if( scrollTarget.width > scrollMask.width) {
					m_scrollTarget_initX = scrollTarget.x;
				} else {
					yohaku = -scrollTarget.x;
					m_scrollTarget_initX = yohaku / 2;
				}
				
				// バーのX位置
				var baseW = m_base.width - m_up.width - m_down.width - 2;
				var barW = m_bar.width;
				m_bar.setX( m_bar.getMinX() + ( baseW - barW));
			} else {
				// 両側に、はみ出している
				m_scrollTarget_initX = scrollTarget.x;
				
				// バーのX位置
				var baseW = m_base.width - m_up.width - m_down.width - 2;
				var barW = m_bar.width;
				var rate = ( scrollMask.x - scrollTarget.x) / ( scrollTarget.width - scrollMask.width);
				m_bar.setX( m_bar.getMinX() + ( baseW - barW) * rate);
			}
*/

			// 基準のX位置
			m_scrollTarget_initX = scrollTarget.x > 0 ? 0 : scrollTarget.x;
			
			// 全体の長さ(コンテンツに対し、マスク内に余っている左右の余白幅も足す)	
			m_ttlW = updateTotalWidth();
			m_bar.init( m_base.width - m_up.width - m_down.width - 2, scrollMask.width / m_ttlW);
			//m_bar.init( m_base.width - m_up.width - m_down.width - 2, scrollMask.width / ( scrollTarget.width + TARGET_PADDING_RIGHT));
			
			
			// バーのX位置も変える
			var baseW = m_base.width - m_up.width - m_down.width - 2;
			var barW = m_bar.width;
			//m_bar.setX( m_bar.getMinX() + ( baseW - barW) * ( scrollMask.x - scrollTarget.x) / ( scrollTarget.width + TARGET_PADDING_RIGHT - scrollMask.width));
			//m_bar.setX( m_bar.getMinX() + ( baseW - barW) * ( scrollMask.x - scrollTarget.x) / ( m_ttlW - scrollMask.width));
			var rate = scrollTarget.x / ( m_ttlW - scrollMask.width);
			m_bar.setX( m_bar.getMinX() + ( baseW - barW) * rate);
			
		}
		function onClickUp( e:MouseEvent) { m_bar.setX( m_bar.x - 5);}
		function onClickDown( e:MouseEvent) { m_bar.setX( m_bar.x + 5);}
		//function onClickBase( e:MouseEvent) { m_bar.setX( m_bar.x + ( mouseX - m_bar.x)/2);}
		function onClickBase( e:MouseEvent) {
			if( contains( m_bar)) {
				if( mouseX < m_bar.x) m_bar.setX( mouseX);
				else m_bar.setX( mouseX - m_bar.width);
			}
		}
		function onBarChange( e:BarEvent) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "SimpleScrollBar:update():" + String(scrollTarget.height) +","+ String(scrollMask.height) +","+ String(e.ratio));
			scrollTarget.x = m_scrollTarget_initX - ( m_ttlW - scrollTarget.width) * e.ratio;
		}
		
		
		function updateTotalWidth() : Number {
			var ttl_w = scrollTarget.width;
			ttl_w += scrollTarget.x > 0 ? scrollTarget.x : 0; // マスク内に余っている余白幅(左側)も足す
			ttl_w += scrollTarget.x + scrollTarget.width < scrollMask.width ?
						scrollMask.width - ( scrollTarget.width + scrollTarget.x) : 0; // マスク内に余っている余白幅(右側)も足す
			return ttl_w;
		}
		
		// この関数は、scrollTargetを強制的に左端に移動させたときに、明示的に呼んでください。
		// バーの位置を強制的に左端に戻します。
		public function setBarXMin() {
			m_bar.setXMin();
		}
	}
}


import common.AlertManager;
import flash.display.*;
import flash.events.*;
import flash.geom.*;
import common.*;

class Bar extends Sprite {
	private var m_base_width:Number;
	private var MIN_X:Number;
	
	private var m_clickMouseX:Number;
	private var m_preX:Number;
	
	public function Bar( posi_x:Number, posi_y:Number, w:Number, h:Number) {
		// グラデーション
		var fillType:String = GradientType.LINEAR;
		var colors:Array = [ 0xB3DCF3, 0x6ABAE8];
		var alphas:Array = [1, 1];
		var ratios:Array = [0x00, 0xFF];
		var matr:Matrix = new Matrix();
		matr.createGradientBox( w, h, Math.PI / 2);
			
		graphics.beginGradientFill( fillType, colors, alphas, ratios, matr, SpreadMethod.PAD);
		graphics.drawRect( 0, 0, w, h);
		graphics.endFill();
		x = MIN_X = posi_x;
		y = posi_y;
		//buttonMode = true;

		addEventListener( MouseEvent.MOUSE_DOWN, function(e:MouseEvent) {
			m_clickMouseX = stage.mouseX;
			m_preX = x;
			stage.addEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveScroll);
		});
		
		addEventListener( Event.ADDED_TO_STAGE, function(e:*) {
			stage.addEventListener( MouseEvent.MOUSE_UP, function(e:*) {
				stage.removeEventListener( MouseEvent.MOUSE_MOVE, onMouseMoveScroll);
			});
			stage.addEventListener( MouseEvent.MOUSE_OUT, function(e:*) {
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
	
	public function init( base_width:Number, ratio:Number = 0.5) {
		m_base_width = base_width;
		width = m_base_width * ratio;
	}
	
	// ドラッグ
	function onMouseMoveScroll( e:MouseEvent) {
		setX( m_preX + stage.mouseX - m_clickMouseX);
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Bar:onMouseMoveScroll():" + String( m_preY + stage.mouseY - m_clickMouseY));
		//e.updateAfterEvent();
	}
	public function setX( posi_x:Number) {
//if( ExternalInterface.available) ExternalInterface.call( "flashFunc_alert", "Bar:setY():" + posi_y);
		x = posi_x;
		checkPosition();
		dispatchEvent( new BarEvent( "barChange", x - MIN_X, m_base_width - width));
	}
	
	public function getMinX():Number { return MIN_X;}

	// バーの位置調整
	function checkPosition() {
		if( x < MIN_X) x = MIN_X;
		if( x > MIN_X + m_base_width - width) x = MIN_X + m_base_width - width;
	}

	public function setXMin() {
		x = MIN_X;
	}
	
}

class BarEvent extends Event {
	public var ratio:Number;
	public function BarEvent( type:String, posi_x:Number, ttl_width:Number) {
		super( type);
		ratio = posi_x / ttl_width;
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
		matr.createGradientBox( SimpleScrollBarH.SIZE-1, SimpleScrollBarH.SIZE , Math.PI/2, 0, 0);
		
		graphics.lineStyle( 1, 0xcccccc, 1, false, LineScaleMode.NONE);
		graphics.beginGradientFill( fillType, colors, alphas, ratios, matr, SpreadMethod.PAD);
		graphics.drawRect( 0, 0, SimpleScrollBarH.SIZE-1, SimpleScrollBarH.SIZE);
		graphics.endFill();
		
		// 矢印
		var color = 0xff999999;
		var bmpArrow:BitmapData = new BitmapData( 4, 7, true, 0);
		bmpArrow.setPixel32( 0, 3, color);
		var i:uint;
		for( i = 2; i <= 4; i++) { bmpArrow.setPixel32( 1, i, color);}
		for( i = 1; i <= 5; i++) { bmpArrow.setPixel32( 2, i, color);}
		for( i = 0; i <= 6; i++) { bmpArrow.setPixel32( 3, i, color);}
		arrow = new Bitmap( bmpArrow);
		arrow.x = 4;
		arrow.y = 4;
		
		if( Main.CONF.TERMINAL == Main.TERMINAL_ANDROID) arrow.scaleX = arrow.scaleY = 2;
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
		arrow.x = 10;
		arrow.y = 10;
	}
}






