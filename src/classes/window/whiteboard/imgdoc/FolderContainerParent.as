﻿package window.whiteboard.imgdoc {	import flash.display.*;	import flash.events.*;	// サムネイル一覧コンテナの親コンテナ	public class FolderContainerParent extends Sprite {				static public const CHANGE_Y:String = "CHANGE_Y";				public function FolderContainerParent() {		}				override public function set y ( value:Number):void {			super.y = value;			dispatchEvent( new Event( CHANGE_Y));		}	}}