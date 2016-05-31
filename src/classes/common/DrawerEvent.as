package common {
	import flash.events.*;
	public class DrawerEvent extends Event {
		static public const CONTENTS_H_CHANGED:String = "CONTENTS_H_CHANGED";
		public var h:Number;
		public function DrawerEvent( type:String, h:Number) {
			super( type);
			this.h = h;
		}
	}
}