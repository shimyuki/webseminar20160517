package window.setting {
	import flash.events.*;
	import partition.Layout;
	public class LayoutEvent extends Event {
		static public const ADD_NEW_LAYOUT:String = "ADD_NEW_LAYOUT";
		public var layout:Layout;
		public function LayoutEvent( type:String, layout:Layout) {
			super( type);
			this.layout = layout;
		}
	}
}