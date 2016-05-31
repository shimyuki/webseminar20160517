package window.whiteboard.slide {
	import flash.events.*;
		
	public class PaintPartsEvent extends Event {
		// paintPartsData の値は、typeがMULTI_CHANGEの場合はPaintPartsの配列、
		// それ以外の場合はPaintPartsDataとなる。

		static public const ADDED:String = "ADDED";
		static public const REMOVED:String = "REMOVED";
		static public const CHANGED:String = "CHANGED";
		static public const MULTI_CHANGE:String = "MULTI_CHANGE";
		public var paintPartsData; // Object or Array
		public function PaintPartsEvent( type:String, paintPartsData) {
			super( type);
			this.paintPartsData = paintPartsData;
		}
	}
}