package window.whiteboard.slide {
	import flash.events.*;
		
	public class TextPaintPartsEvent extends Event {
		// テキストペイントパーツがダブルクリックで編集されるとき

		static public const START_CHANGE:String = "START_CHANGE";
		public var ppd:PaintPartsData; // Object
		public function TextPaintPartsEvent( type:String, ppd:PaintPartsData) {
			super( type);
			this.ppd = ppd;
		}
	}
}