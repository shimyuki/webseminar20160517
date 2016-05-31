package {
	import flash.events.*;
	public class StreamCheckerEvent extends Event {
		//static public const STATUS_START:String = MyNetStream.STATUS_START;
		//static public const STATUS_MAYBE_STOPED:String = MyNetStream.STATUS_MAYBE_STOPED;
		//static public const STATUS_STOPED:String = MyNetStream.STATUS_STOPED;
		static public const STATUS_ALIVE:String = "STATUS_ALIVE";
		static public const STATUS_DIE:String = "STATUS_DIE";
		public var uid:String;
		public function StreamCheckerEvent( type:String, uid:String) {
			super( type);
			this.uid = uid;
		}
	}
}