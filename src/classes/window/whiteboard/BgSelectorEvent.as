package window.whiteboard {
	import flash.events.*;
		
	public class BgSelectorEvent extends Event {
		static public const SELECTED:String = "BG_SELECTED";
		public var bgtype:String;
		public var imgpath_or_cameraid_or_color;
		public function BgSelectorEvent( type:String, bgtype:String, imgpath_or_cameraid_or_color) {
			super( type);
			this.bgtype = bgtype;
			this.imgpath_or_cameraid_or_color = imgpath_or_cameraid_or_color;
		}
	}
}