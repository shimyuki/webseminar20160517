package window.video {
    import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
    public class MicBtn extends VideoBtn {
		public function MicBtn() {
			super();
			m_base.addChild( new Mic());
		}
	}
}









