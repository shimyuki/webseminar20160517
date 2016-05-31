﻿package window.video.list.parts {	import flash.display.*;	import flash.geom.*;	import common.*;	import window.*;	import window.setting.MemberSettingContents;	import flash.text.*;	import flash.events.*;	import fl.controls.CheckBox;	import flash.net.*;	import flash.utils.*;	import caurina.transitions.*;	import window.video.VoiceMeter;	// 受講生一覧のメンバー表示コンテナ	// サムネイル表示と一覧表示の２パターン	public class MemberContainer extends Sprite {				static public const STATUS_ABSENCE:uint = 0;		static public const STATUS_ATTEND:uint = 1;		static public const STATUS_HERE:uint = 2;		public var status:uint = STATUS_ABSENCE; // AllListでのソート用		public var firstAttendTime:Number = Number.MAX_VALUE; // AllListでのソート用、最初に参加した時刻のUNIXタイム															//MainのonSyncSo1stJoinTimeからAllListのset1stAttendTime経由で呼ばれる		public var lastAttendTime:Number = Number.MIN_VALUE; // AllListでのソート用、最新参加時刻のUNIXタイム		public var lastHereTime:Number = Number.MAX_VALUE; // AllListでのソート用、最新挙手時刻のUNIXタイム				public var available:Boolean = true;		public var uid:String;				private var m_listtype:String;				// サムネイル表示用パーツ		private var m_thuCon:ThumbCon;				// テキスト表示用パーツ		private var m_textCon:TextCon;				private var m_blinkingTimer:Timer;						//public function MemberContainer( uid:String, useAsPickup:Boolean = false) {		public function MemberContainer( uid:String) {			this.uid = uid;						// サムネイル表示用パーツ			/*			if( useAsPickup) m_thuCon = new ThumbCon_pickup( uid);			else m_thuCon = new ThumbCon_all( uid);			*/			m_thuCon = new ThumbCon_all( uid);			m_thuCon.addEventListener( MemberEvent.POPUP_SETTING, reDispatchMemberEvent);			m_thuCon.addEventListener( MemberEvent.POPUP_SETTING_CHAT, reDispatchMemberEvent);						// 講師が受講生の不具合を報告する			if( Main.USE_RECEIVE_IDLE_CHECK_BY_LEC && Main.CONF.isPro( Main.CONF.UID))  {				m_thuCon.addEventListener( MemberEvent.SOMETHING_WRONG_WITH_FPSMETER, reDispatchMemberEvent);			}						// テキスト表示用パーツ			m_textCon = new TextCon( uid);			m_textCon.addEventListener( MemberEvent.POPUP_SETTING, reDispatchMemberEvent);			m_textCon.addEventListener( MemberEvent.POPUP_SETTING_CHAT, reDispatchMemberEvent);						//----------------------------			// chatポップアップボタンをチカチカさせる			//----------------------------			m_blinkingTimer = new Timer( 2500);			m_blinkingTimer.addEventListener( TimerEvent.TIMER, onTimer);						//if( useAsPickup) attend( 0);			//else absence();			 absence();		}				public function startBlinkChatBtn() {			m_blinkingTimer.start();		}		public function stopBlinkChatBtn() {			m_blinkingTimer.stop();		}		function onTimer( e:TimerEvent) {			m_thuCon.blinkChatBtn();		}		// LiveStatusManager経由で呼ばれる		public function setTerminalStatus( terminalType:String) {			m_textCon.setTerminalStatus( terminalType);			m_thuCon.setTerminalStatus( terminalType);		}				// 挙手状況の変更。Main:onSyncHere()からLiveStatusManager、ListContainer、AllList経由で呼ばれる		public function changeHereStatus( hereFlag:Boolean, nowTime:Number) {			if( hereFlag) {				here( nowTime);			} else {				hereOff();			}		}		// 参加不参加状況の変更。Main:onSyncJoin()からLiveStatusManager、ListContainer、AllList経由で呼ばれる		public function changeJoinStatus( joinFlag:Boolean, nowTime:Number) {			if( joinFlag) {				attend( nowTime);			} else {				absence();			}		}		// ハイ		function here( nowTime:Number) {			status = STATUS_HERE;			lastHereTime = nowTime;			m_textCon.here();			m_thuCon.here();		}		// 挙手取りやめ		function hereOff() {			status = STATUS_ATTEND;			m_textCon.hereOff();			m_thuCon.hereOff();		}		// 欠席		function absence() {			status = STATUS_ABSENCE;			m_textCon.absence();			m_thuCon.absence();		}		// 出席		function attend( nowTime:Number) {			status = STATUS_ATTEND;			lastAttendTime = nowTime;			m_textCon.attend();			m_thuCon.attend();		}				public function setStatusDisconnect() {			absence();		}		public function setCamera( camera) {			m_thuCon.setCamera( camera);		}				public function getNetStream() : MyNetStream {			return m_thuCon.getNetStream();		}				public function showAsThumblist() {			if( contains( m_textCon)) removeChild( m_textCon);			addChild( m_thuCon);			m_listtype = ListTypeBtn.THUMB_CLICKED;			//m_thuCon.startVideo();		}				public function showAsTextlist( bgColor:uint) { // テキスト表示関連の関数			if( contains( m_thuCon)) removeChild( m_thuCon);			addChild( m_textCon);						m_textCon.setBg( bgColor);						m_listtype = ListTypeBtn.TEXT_CLICKED;						//m_thuCon.stopVideo();		}			public function setVolume( volume:Number) {			m_textCon.setVolume( volume);			m_thuCon.setVolume( volume);		}		public function resetNetStream() : void {			//m_textCon.resetNetStream();			m_thuCon.resetNetStream();		}		public function initSo( nc:NetConnection, so_here:SharedObject) : void {			m_textCon.initSo( nc);			m_thuCon.initSo( nc, so_here);		}		public function setFpsMeter() {			m_thuCon.setFpsMeter();		}		public function getNameW(){ // テキストコンテナ表示関連の関数			return m_textCon.getNameW();		}		public function getAttendW(){ // テキストコンテナ表示関連の関数			return m_textCon.getAttendW();		}		public function getCamW(){ // テキストコンテナ表示関連の関数			return m_textCon.getCamW();		}		public function getMicW(){ // テキストコンテナ表示関連の関数			return m_textCon.getMicW();		}		public function getWbW(){ // テキストコンテナ表示関連の関数			return m_textCon.getWbW();		}		public function setNameW( w){ // テキストコンテナ表示関連の関数			m_textCon.setNameW( w);		}		public function setAttendW( w){ // テキストコンテナ表示関連の関数			m_textCon.setAttendW( w);		}		public function setCamW( w){ // テキストコンテナ表示関連の関数			m_textCon.setCamW( w);		}		public function setMicW( w){ // テキストコンテナ表示関連の関数			m_textCon.setMicW( w);		}		public function setWbW( w){ // テキストコンテナ表示関連の関数			m_textCon.setWbW( w);		}				function getText( str:String) : TextField {			var txt = new TextField();			txt.defaultTextFormat = new TextFormat( Main.CONF.getMainFont(), 11);			txt.text = str;			txt.width = txt.textWidth + 4;			txt.height = txt.textHeight + 4;			return txt;		}								public function setViewWidth( w:Number):void {			if( m_listtype == ListTypeBtn.TEXT_CLICKED) m_textCon.setViewWidth( w);			else m_thuCon.setViewWidth( w);		}				/*		public function setViewHeight( h:Number):void {			if( m_listtype == ListTypeBtn.TEXT_CLICKED) m_textCon.setViewHeight( h);			else m_thuCon.setViewHeight( h);		}*/				public function getViewWidth():Number {			if( m_listtype == ListTypeBtn.TEXT_CLICKED) return m_textCon.getViewWidth();			else return m_thuCon.getViewWidth();		}		public function getViewHeight():Number {			if( m_listtype == ListTypeBtn.TEXT_CLICKED) return TextCon.TEXT_CON_H;			else return m_thuCon.getViewHeight();		}				function alertDialog( str:String) {			Main.addErrMsg(  "MemberContainer:" + str);		}		function reDispatchMemberEvent( e:MemberEvent) {			dispatchEvent( new MemberEvent( e.type, e.uid));		}	}}