package window {
	import flash.events.*;
		
	public class SizeHandleEvent extends Event {
		public var diffX:Number;
		public var diffY:Number;
		public function SizeHandleEvent( type:String, diffX:Number, diffY:Number) {
			super( type);
			this.diffX = diffX;
			this.diffY = diffY;
		}
	}
}