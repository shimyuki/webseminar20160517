﻿package common {	import flash.display.*;	import flash.events.*;	import common.DynamicTextBtn;	import flash.geom.Matrix;	import caurina.transitions.*;		public class IconBtn extends Sprite {						static public const BLINK_COLOR_01:uint = DynamicTextBtn.BLINK_COLOR_01;		static public const BLINK_COLOR_02:uint = DynamicTextBtn.BLINK_COLOR_02;		private var m_on = null;		private var m_blink = null;		private var m_off;		private var m_clickObj:Sprite;				public function IconBtn( offObj, onObj = null, blinkObj = null) {			m_off = addChild( offObj);			if( onObj != null) {				m_on = addChild( onObj);				m_on.visible = false;			}						// チカチカベース			if( blinkObj != null) {				m_blink = addChild( blinkObj);				m_blink.alpha = 0;			}									m_clickObj = Sprite( addChild( new Sprite()));			m_clickObj.graphics.beginFill( 0, 0);			m_clickObj.graphics.drawRect( 0, 0, width, height);			m_clickObj.graphics.endFill();					}		// チカチカ1回（クイック一覧のMemberConから呼ばれる）		public function blink() {			if( m_blink == null) {				throw new ArgumentError( "IconBtn:blink()はコンストラクタでm_blinkを指定した場合に実行してください！"); 				return;			}			Tweener.removeTweens( m_blink);			m_blink.alpha = 1;			Tweener.addTween( m_blink, { alpha: 0, transition:"liner", time:1, delay:1});		}		public function setEnabled( b:Boolean):void {			buttonMode = b;			if( b) {				m_clickObj.addEventListener( MouseEvent.ROLL_OVER, onRollOVER);				m_clickObj.addEventListener( MouseEvent.ROLL_OUT, onRollOUT);			} else {				m_clickObj.removeEventListener( MouseEvent.ROLL_OVER, onRollOVER);				m_clickObj.removeEventListener( MouseEvent.ROLL_OUT, onRollOUT);				onRollOUT();			}		}		function onRollOVER( e:MouseEvent) {			if( m_on == null) return;						m_off.visible = false;			m_on.visible = true;		}		function onRollOUT( e:MouseEvent = null) {			if( m_on == null) return;						m_off.visible = true;			m_on.visible = false;		}	}}