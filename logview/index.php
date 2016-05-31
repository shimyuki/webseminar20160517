<!doctype html>
<html>
<head>
<meta charset="UTF-8">
<title>ログ</title>
</head>
<body>
<?php
require_once "../conf.php";
require_once "../functions.php";
$class_id = LIVECLASS_CLASS_ID;
$log_csv = ROOT_LOG . "/0916live_log_join.csv";
$answer_csv = ROOT_LOG . "/0916live_log_answer.csv";
$chat_csv = ROOT_LOG. "/0916live_log_chat.csv";
$uid_hash = array();


$fp_1 = fopen( ROOT_LOG . "/" . UID_CSV, 'r' );
while( $lines = fgetcsv( $fp_1) ) {
	if($lines[1] == md5($lines[0])) $uid_hash[$lines[1]] = $lines[0];
}
fclose( $fp_1 );


// 参加時間、デバイス
if( is_file( $log_csv )) unlink( $log_csv );
$header = "uid,入室時刻,デバイス,HTTP_USER_AGENT";
file_put_contents($log_csv, mb_convert_encoding( $header, "SJIS-win", "UTF-8") . "\r\n", LOCK_EX);

$fp = fopen( $log_csv, 'a');
if (flock($fp, LOCK_EX)){		
	foreach ($uid_hash as $uid_md5 => $uid){
		$fp_r = fopen( ROOT_LOG . "/join/".$uid_md5.".csv", 'r' );
		while( $lines = fgetcsv( $fp_r) ) {
			if( count($lines) == 1) continue;
			fputcsv($fp, array_merge( array( $uid), $lines));
		}
		fclose( $fp_r);
	}
	flock($fp, LOCK_UN);
}
fclose($fp);

?>
<p>参加時間、デバイスのログを以下に再生成しました:<br><?=str_replace( ROOT_LOG, "ROOT_LOG + ", $log_csv)?></p>

<?php
// アンケート
if( is_file( $answer_csv )) unlink( $answer_csv );
$header = "uid,アンケート回答時刻,Q1:今回のWEBライブセミナーはいかがでしたか。,Q2:普段、医療用医薬品に関する情報はどこから入手していますか。,Q3:医療用医薬品に関する情報の望ましい提供方法は何ですか。,Q4:軟膏などを混合することはありますか。,Q5:Q4にて「はい」と回答された方で良く混合している処方を教えてください。,Q6:混合後に問題のあった処方を教えてください。,Q7:混合には何を使用していますか。,QQ8:配合可否は何で調べていますか。,Q9:混合不可等の場合は処方医の先生に問い合わせますか。,Q10:問い合わせた結果について教えて下さい。,Q11:Q10にて「変更になる」と回答された先生で変更前後の組み合わせを教えて下さい。問合わせ前,Q11:問合わせ後,Q12:外用剤の調剤や製剤で困っていること等がありましたら教えて下さい。";

file_put_contents($answer_csv, mb_convert_encoding( $header, "SJIS-win", "UTF-8") . "\r\n", LOCK_EX);


setlocale(LC_ALL, 'ja_JP.UTF-8');

$fp_2 = fopen( $answer_csv, 'a');
if (flock($fp_2, LOCK_EX)){		
	foreach ($uid_hash as $uid_md5 => $uid){
		//文字コードをロケールに合わせて変える
		$fp_tmp = tmpfile();
		fwrite($fp_tmp, mb_convert_encoding(file_get_contents(ROOT_LOG . "/answer/".$uid_md5.".csv"), 'UTF-8', 'sjis-win'));
		rewind($fp_tmp);

		//$fp_r2 = fopen( ROOT_LOG . "/answer/".$uid_md5.".csv", 'r' );
		while( $lines = fgetcsv( $fp_tmp) ) {
			$lines_sjis = array();
			foreach( $lines  as $data) {
				array_push( $lines_sjis,  getSjisStr( $data));
			}
			fputcsv($fp_2, array_merge( array( $uid), $lines_sjis));
		}
		fclose( $fp_tmp);
	}
	flock($fp_2, LOCK_UN);
}
fclose($fp_2);

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
	
	$line = array( $uid_hash[$md5_uid] , date('Y/m/d H:i:s', $unixtime) , getSjisStr($div->p[1]));
	$key_line_hash[(string)$key] = $line;
	$key ++;
}
asort( $key_date_hash);
$fp_3 = fopen( $chat_csv, 'a');
if (flock($fp_3, LOCK_EX)){
	foreach ($key_date_hash as $key => $val) {
		fputcsv($fp_3, $key_line_hash[$key]);
	}
	flock($fp_3, LOCK_UN);
}
fclose($fp_3);
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
