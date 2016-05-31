package window.whiteboard.imgdoc {
	import flash.events.*;
		
	public class ImgdocEvent extends Event {
		static public const ADDED:String = "ADDED";
		public var imgpath:String;
		public function ImgdocEvent( type:String, imgpath:String) {
			super( type);
			this.imgpath = imgpath;
		}
	}
}