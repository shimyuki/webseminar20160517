<?php
require_once "conf.php";
require_once "UserAgent.php";
function updateAnswer( $uid_4_filename) {
}
function answered($uid_org, $uid_4_filename) {
	return false;
}
function mkdirRootLog() {
	if (! file_exists(ROOT_LOG)) {
	   if( mkdir( ROOT_LOG, 0755, true)) {
	   } else {
		   error_log("can't mkdir ". ROOT_LOG);
		   echo ROOT_LOG. " 生成失敗<br />";
	   }
	}
}
function registerUid( $uid_org) {
	$uid_4_filename = md5($uid_org);
	$filepath = ROOT_LOG . "/" . UID_CSV;
	$exist = 0;
	if(file_exists($filepath)) {
		$fp = fopen( $filepath, 'r' );
		while( $lines = fgetcsv( $fp) ) {
			$loaded_uid_org = $lines[0];
			if( $loaded_uid_org== $uid_org) {
				$exist = 1;
				break;
			}
		}
		fclose( $fp );
	}
	// uidとuid_4_logの突き合わせcsvを更新
	@touch($filepath);
	if( $exist == 0) {
		$fp = fopen( $filepath, 'a');
		if (flock($fp, LOCK_EX)){
			fputcsv($fp, array( $uid_org,$uid_4_filename));
			flock($fp, LOCK_UN);
		}
		fclose($fp);
	}
	//if( $exist == 0) @file_put_contents($filepath, '"'.encodeForCsv($uid_org) . '",' .$uid_4_filename . "\r\n", FILE_APPEND | LOCK_EX);
}

function saveJoinTime( $uid_org) {
	$uid_4_filename = md5($uid_org);
		// 参加時刻保存
		ini_set("date.timezone", "Asia/Tokyo");
		$dir_join = ROOT_LOG . "/join";
		if (! file_exists($dir_join)) {
		   if( mkdir( $dir_join, 0755, true)) {
			   
		   } else {
			   error_log("can't mkdir ". $dir_join);
			   die("can't mkdir ". $dir_join);
		   }
		}
		$ua = new UserAgent();
		$joinlog = date('Y/m/d H:i:s', time()) .','.$ua->getDevice(). ',"' . $_SERVER['HTTP_USER_AGENT'] . '"';
	   $join_csv = $dir_join. "/" . $uid_4_filename . ".csv";
	   
	   $file_exists = file_exists($join_csv);
	   $fp = fopen( $join_csv, 'a');
		if (flock($fp, LOCK_EX)){
			if( ! $file_exists) {
				fputcsv($fp, array( $uid_org));
			}
			fputcsv($fp, array(date('Y/m/d H:i:s', time()),$ua->getDevice(),$_SERVER['HTTP_USER_AGENT']));
			flock($fp, LOCK_UN);
		}
		fclose($fp);
		/*
	  if (! file_exists($join_csv)) {
		  // 新規作成
		  @file_put_contents($join_csv, '"'.encodeForCsv($uid_org)  . '"' . "\r\n". $joinlog  . "\r\n", LOCK_EX);
	  } else {
		  // 追記
		  @file_put_contents($join_csv, $joinlog  . "\r\n", FILE_APPEND | LOCK_EX);
	  }*/
}

?>