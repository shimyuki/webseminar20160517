package {

	import common.AlertManager;
    public class Client {
		

		public function onBWCheck(... rest):Number { 
			return 0; 
		} 
		public function onBWDone(... rest):void { 
			var bandwidthTotal:Number; 
			
			if (rest.length > 0){ 
				bandwidthTotal = rest[0]; 
				// This code runs 
				// when the bandwidth check is complete. 
				//trace( "bandwidth = " + bandwidthTotal + " Kbps."); 
				if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title",  "bandwidth = " + bandwidthTotal + " Kbps.");
			} else {
				if( ExternalInterface.available) ExternalInterface.call( "flashFunc_title",  "onBWDone" + String( rest.length));
			}
		}

	}
}









