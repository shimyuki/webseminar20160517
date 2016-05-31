package window.header {
	import flash.events.*;
	public class HeaderEvent extends Event {
		public var winname:String;
		public function HeaderEvent( type:String, winname:String) {
			super( type);
			this.winname = winname;
		}
	}
}