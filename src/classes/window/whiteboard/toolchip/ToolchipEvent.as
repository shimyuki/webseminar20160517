package window.whiteboard.toolchip {
	import flash.events.*;
		
	public class ToolchipEvent extends Event {
		static public const SELECTED = "SELECTED";
		static public const SHOW_PANEL = "SHOW_PANEL";
		static public const HIDE_PANEL = "HIDE_PANEL";
		public var tool_name:String;
		public var panel;
		public var targetBtnX:Number;
		public var targetBtnY:Number;
		public function ToolchipEvent( type:String, tool_name:String = "", panel = null, targetBtnX:Number = 0, targetBtnY:Number = 0) {
			super( type);
			this.tool_name = tool_name;
			this.panel = panel;
			this.targetBtnX = targetBtnX;
			this.targetBtnY = targetBtnY;
		}
	}
}