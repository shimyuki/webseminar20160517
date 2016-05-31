package window.video {
    import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
    public class VideoBtn extends Sprite {

		private var _status:Boolean = false; // trueはon
		protected var m_base;
		private var m_off;
		private var _enabled = false;
		public function VideoBtn() {
			m_base = addChild( new Sprite());
			m_off = addChild( new Off());
			m_off.visible = !_status;
			buttonMode = _enabled;
		}
		public function setEnabled( b:Boolean):void{
			_enabled = b;
			buttonMode = _enabled;
		}
		public function set status( b:Boolean):void{
			_status = b;
			m_off.visible = !_status;
		}
		public function get status():Boolean{
			return _status;
		}
	}
}









