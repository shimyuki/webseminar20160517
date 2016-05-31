package window.whiteboard.toolchip {
	import flash.events.*;
		
	public class ScaleComboEvent extends Event {
		static public const CHANGED = " ScaleComboCHANGED";
		public var tool_name:String;
		public var scale:Number;

		public function ScaleComboEvent( type:String, tool_name:String, scale:Number) {
			super( type);
			this.tool_name = tool_name;
			this.scale = scale;
		}
	}
}