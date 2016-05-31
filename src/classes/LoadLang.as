﻿package {	import flash.events.*;	import flash.net.*;	import flash.text.*;	import common.*;	import partition.*;	import window.questionnaire.*;	    public class LoadLang extends EventDispatcher	// XMLを読み込んで、データをm_param_hashに保存する	{		public static const LOAD_COMPLETE = "LOAD_COMPLETE";		static public const UNDEF:String = "UNDEF";		private var m_param_hash:Object = null;		private var m_lang_type:String;		//static public var FONTNAME:String = "";				public function LoadLang( lang_type:String, langFilePath:String) {			m_lang_type = lang_type;						var dateObj:Date = new Date();			var cacheClear = "?dummy=" + dateObj.getMonth() + dateObj.getDate() + dateObj.getHours() + dateObj.getMinutes() + dateObj.getSeconds(); // 一秒ごとにキャッシュクリア						var req:URLRequest = new URLRequest( langFilePath + cacheClear);						var loader:URLLoader = new URLLoader();			if( langFilePath != "") loader.load( req);			loader.addEventListener( Event.COMPLETE, onComplete);			loader.addEventListener( IOErrorEvent.IO_ERROR, onDispatchError);			loader.addEventListener( SecurityErrorEvent.SECURITY_ERROR, onDispatchError);											}				public function getImgdocCloseText() {			switch( m_lang_type) {				case "english" :					return new ImgdocCloseText_en();					break;				case "japanese":				default:					return new ImgdocCloseText();					break;			}		}		public function getToolchipCloseText() {			switch( m_lang_type) {				case "english" :					return new ToolchipCloseText_en();					break;				case "japanese":				default:					return new ToolchipCloseText();					break;			}		}		public function getIconHere() {			switch( m_lang_type) {				case "english" :					return new IconHere_en();					break;				case "japanese":				default:					return new IconHere();					break;			}		}		public function getIconAbsence() {			switch( m_lang_type) {				case "english" :					return new IconAbsence_en();					break;				case "japanese":				default:					return new IconAbsence();					break;			}		}		public function getIconAttend() {			switch( m_lang_type) {				case "english" :					return new IconAttend_en();					break;				case "japanese":				default:					return new IconAttend();					break;			}		}		public function getFlagHere() {			switch( m_lang_type) {				case "english" :					return new FlagHere_en();					break;				case "japanese":				default:					return new FlagHere();					break;			}		}		public function getParam( pname:String):String {			if( ! m_param_hash) return UNDEF;			if( m_param_hash[pname] == undefined) {				alertDialog( "undefined:" + pname);				return UNDEF + ":" + pname;			}			return m_param_hash[pname];		}		public function getReplacedSentence( pname:String, replace:String):String {			if( ! m_param_hash) return UNDEF;			if( m_param_hash[pname] == undefined) {				alertDialog( "undefined:" + pname);				return UNDEF + ":" + pname;			}			return String( m_param_hash[pname]).replace( "%s", replace);		}		function onComplete(e:Event):void {			m_param_hash = new Object();			var loader:URLLoader = e.target as URLLoader;			var xml:XML = XML( loader.data);			var elm:XML;			var hasErr:Boolean = false;						// ---------------			// paramの取得			if( xml.hasOwnProperty("param")) {				for each ( elm in xml.param) {					if( elm.hasOwnProperty("@default") && elm.hasOwnProperty("@change")) {						if( String( elm.@change) != "") m_param_hash[ elm.@default] = elm.@change;						else m_param_hash[ elm.@default] = elm.@default;					} else if( elm.hasOwnProperty("@default")) {						m_param_hash[ elm.@default] = elm.@default;					} else {						hasErr = true;					}				}				if( hasErr) alertDialog( "XML_LOAD_ERR_01");			} else {				alertDialog( "XML_LOAD_ERR_02");			}			dispatchEvent( new Event( LOAD_COMPLETE));		}				function onDispatchError( e:*) { dispatchEvent( e);}				function alertDialog( str) {			Main.addErrMsg( "LoadLang:" + String( str));		}	}}