<?php
require_once "conf.php";
require_once "functions.php";
$enc_inner_tmp = mb_internal_encoding();
mb_language("japanese");
mb_internal_encoding("UTF-8");

// アンケート保存
ini_set("date.timezone","Asia/Tokyo");
$dir_answer = ROOT_LOG . "/answer";
if (! file_exists($dir_answer)) {
   if( mkdir( $dir_answer, 0755, true)) {
	   
   } else {
	   error_log("can't mkdir ". $dir_answer);
	   die("can't mkdir ". $dir_answer);
   }
}
$return = "\r\n"; // 改行コード

$filepath = ROOT_LOG . "/" . UID_CSV;

// $_POST["uid_4_filename"]の妥当性を確かめる
$exist = 0;
if(file_exists($filepath)) {
	$fp = fopen( $filepath, 'r' );
	while( $lines = fgetcsv( $fp) ) {
		if( $lines[1] == $_POST["uid_4_filename"] && md5($lines[0]) == $_POST["uid_4_filename"]) {
			$exist = 1;
			break;
		}
	}
	fclose( $fp );
}
if( $exist==0) {
	return;
}
$uid_4_filename = $_POST["uid_4_filename"];


$post_q1 =  $_POST["q1"];
if( $post_q1 == "その他") $post_q1 = "その他: " . $_POST["q1b"];
$post_q2 =  $_POST["q2"];
if( $post_q2 == "その他") $post_q2 = "その他: " . $_POST["q2b"];
$post_q3 =  $_POST["q3"];
if( $post_q3 == "その他") $post_q3 = "その他: " . $_POST["q3b"];

$log_arr = array(date('Y/m/d H:i:s', time()),getSjisStr($post_q1),getSjisStr($post_q2),getSjisStr($post_q3),getSjisStr($_POST["q4"]),getSjisStr($_POST["q5"]),getSjisStr($_POST["q6"]),getSjisStr($_POST["q7"]),getSjisStr($_POST["q8"]),getSjisStr($_POST["q9"]),getSjisStr($_POST["q10"]),getSjisStr($_POST["q11_a"]),getSjisStr($_POST["q11_b"]),getSjisStr($_POST["q12"]));
$csv = $dir_answer. "/" .  $uid_4_filename . ".csv";
if ( file_exists($csv)) {
  // 削除
	@unlink($csv);
}
// 新規作成
$fp = fopen( $csv, 'a');
if (flock($fp, LOCK_EX)){
	fputcsv($fp, $log_arr);
	flock($fp, LOCK_UN);
}
fclose($fp);

echo("ご回答ありがとうございました");

mb_internal_encoding($enc_inner_tmp);

function getSjisStr( $utf8Str) {
	$utf8Str = str_replace(array("\r\n","\r","\n"), ' ', $utf8Str);
	$utf8Str = str_replace('"', "'", $utf8Str);
	$utf8Str = str_replace(',', '，', $utf8Str);
	return mb_convert_encoding( $utf8Str, "SJIS-win", "UTF-8");
}
?>