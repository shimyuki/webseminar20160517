<?php
class UserAgent{

	private $ua;
	private $device;
	
	public function UserAgent(){
		$this->deviceCheck();
	}
	
	public function deviceCheck(){
	
		//ユーザーエージェント取得
		$this->ua = $_SERVER['HTTP_USER_AGENT'];
		
		if(strpos($this->ua,'iPhone') !== false){
			//iPhone
			$this->device = 'iphone';
		}
		elseif(strpos($this->ua,'iPad') !== false){
			//iPad
			$this->device = 'ipad';
		}
		elseif((strpos($this->ua,'Android') !== false) && (strpos($this->ua, 'Mobile') !== false)){
			//Android
			$this->device = 'android_m';
		}
		elseif(strpos($this->ua,'Android') !== false){
			//Android
			$this->device = 'android_t';
		}
		else{
			$this->device = 'pc';
		}
	}
	
	public function getDevice(){
		return $this->device;
	}
}
?>