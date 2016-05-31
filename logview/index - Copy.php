<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<title>ログ</title>
</head>
<body>
<?php
require_once "../conf.php";
$class_id = LIVECLASS_CLASS_ID;
$log_csv = ROOT_LOG . "/0916live_log_join.csv";
$answer_csv = ROOT_LOG . "/0916live_log_answer.csv";
$chat_csv = ROOT_LOG. "/0916live_log_chat.csv";
$uid_hash = array();
$uid_arr = array();
$buf = file_get_contents( ROOT_LOG . "/" . UID_CSV);
if( $buf) {
	$lines = explode("\r\n", $buf); 
	foreach ($lines as $line) {
		$records = explode(",",$line); 
		$uid_org = $records[0];
		// uidにカンマが含まれていた場合の対策
		if( count( $records) > 2) {
			for( $i = 1; $i < count( $records)-1; $i++) {
				$uid_org .= "," . $records[$i]; 
			}
		}
		array_push( $uid_arr, $uid_org);
		$uid_4_filename = $records[count( $records)-1];
		if( $uid_4_filename ==  md5( $uid_org)) $uid_hash[$uid_4_filename] = $uid_org;
	}
}

// 参加時間、デバイス
$jointime_device_hash = array();
foreach ($uid_hash as $uid_md5 => $uid){
	$jointime_device_hash[$uid_md5] = ",";
		$buf = file_get_contents(ROOT_LOG . "/join/".$uid_md5.".csv");
		if($buf) {
			$lines = explode("\r\n", $buf);
			//$records = explode(",",$lines[1]);
			$all_lines = "";
			for( $i = 1; $i < count( $lines); $i++) {
				if($lines[$i] != "") $all_lines .= '"' . $uid . '",'. $lines[$i] . "\r\n";
			}
			$jointime_device_hash[$uid_md5] = $all_lines;
		}
}

if( is_file( $log_csv )) unlink( $log_csv );
$header = "uid,入室時刻,デバイス,HTTP_USER_AGENT";

file_put_contents($log_csv, mb_convert_encoding( $header, "SJIS-win", "UTF-8") . "\r\n", LOCK_EX);
foreach ($uid_hash as $uid_md5 => $uid){
	$line = $jointime_device_hash[$uid_md5];
	file_put_contents($log_csv, $line, FILE_APPEND | LOCK_EX);
}
?>
<p>参加時間、デバイスのログを以下に再生成しました:<br><?=str_replace( ROOT_LOG, "ROOT_LOG + ", $log_csv)?></p>

<?php
// アンケート
$answer_hash = array();
foreach ($uid_hash as $uid_md5 => $uid){
	$answer_hash[$uid_md5] = "";
		$buf_answer = file_get_contents(ROOT_LOG . "/answer/".$uid_md5.".csv");
		if($buf_answer) {
			$lines = explode("\r\n", $buf_answer);
			$answer_hash[$uid_md5] = $lines[0];
		}
}

if( is_file( $answer_csv )) unlink( $answer_csv );
$header = "uid,アンケート回答時刻,Q1:今回のWEBライブセミナーはいかがでしたか。,Q2:普段、医療用医薬品に関する情報はどこから入手していますか。,Q3:医療用医薬品に関する情報の望ましい提供方法は何ですか。,Q4:軟膏などを混合することはありますか。,Q5:Q4にて「はい」と回答された方で良く混合している処方を教えてください。,Q6:混合後に問題のあった処方を教えてください。,Q7:混合には何を使用していますか。,QQ8:配合可否は何で調べていますか。,Q9:混合不可等の場合は処方医の先生に問い合わせますか。,Q10:問い合わせた結果について教えて下さい。,Q11:Q10にて「変更になる」と回答された先生で変更前後の組み合わせを教えて下さい。問合わせ前,Q11:問合わせ後,Q12:外用剤の調剤や製剤で困っていること等がありましたら教えて下さい。";

file_put_contents($answer_csv, mb_convert_encoding( $header, "SJIS-win", "UTF-8") . "\r\n", LOCK_EX);
foreach ($uid_hash as $uid_md5 => $uid){
	$line = $uid . "," . $answer_hash[$uid_md5];
	//echo $line . "<br />";
	file_put_contents($answer_csv, $line . "\r\n", FILE_APPEND | LOCK_EX);
}
?>
<p>アンケートのログを以下に再生成しました:<br><?=str_replace( ROOT_LOG, "ROOT_LOG + ", $answer_csv)?></p>

<?php
// チャット
ini_set("date.timezone","Asia/Tokyo");
$buf_chat = file_get_contents(ROOT_LOG . "/chat_all.html");
if( $buf_chat) {
	$buf_all .= $buf_chat;
}

if( is_file( $chat_csv )) unlink( $chat_csv );

$key_date_hash = array();
$key_line_hash = array();
$chat = new SimpleXMLElement( "<?xml version='1.0' standalone='yes'?><data>".$buf_all."</data>");
$key = 0;
foreach ($chat->div as $div) {
	$unixtime = (int)($div->span[0])/1000;
	$md5_uid = str_replace( "set ", "", (string) $div['class']);
	$key_date_hash[(string)$key] = $unixtime;
	
	$line = $uid_hash[$md5_uid] . "," . date('Y/m/d H:i:s', $unixtime). "," . getSjisStr($div->p[1]);
	$key_line_hash[(string)$key] = $line;
	$key ++;
}
asort( $key_date_hash);
touch($chat_csv);
foreach ($key_date_hash as $key => $val) {
	file_put_contents($chat_csv, $key_line_hash[$key] . "\n", FILE_APPEND | LOCK_EX);
}
function getSjisStr( $utf8Str) {
	$utf8Str = str_replace(array("\r\n","\r","\n"), ' ', $utf8Str);
	$utf8Str = str_replace('"', "'", $utf8Str);
	$utf8Str = str_replace(',', '，', $utf8Str);
	return mb_convert_encoding( $utf8Str, "SJIS-win", "UTF-8");
}
	
?>
<p>チャットのログを以下に再生成しました:<br><?=str_replace( ROOT_LOG, "ROOT_LOG + ", $chat_csv)?></p>

</body>
</html>
