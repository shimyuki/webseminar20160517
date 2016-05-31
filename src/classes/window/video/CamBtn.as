package window.video {
    import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	
    public class CamBtn extends VideoBtn {
		public function CamBtn() {
			super();
			m_base.addChild( new Cam());
		}
	}
}









