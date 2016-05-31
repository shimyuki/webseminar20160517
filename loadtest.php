<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja" xml:lang="ja">
<head>
<title>0916live</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script language="JavaScript" type="text/javascript" src="js/swfobject.js"></script>
<META NAME="ROBOTS" CONTENT="NOINDEX,NOFOLLOW,NOARCHIVE" />
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>
<?php
require_once "conf.php";
require_once "functions.php";
require_once "UserAgent.php";
mkdirRootLog();
$start_num = intval( isset($_REQUEST['start_num']) ? $_REQUEST['start_num'] : "0");
$end_num = intval( isset($_REQUEST['end_num']) ? $_REQUEST['end_num'] : "9");

for( $num = $start_num; $num <= $end_num; $num++) {
	$uid_org = "loadtest_" . $num;
	$uid_4_filename = md5($uid_org);
	registerUid( $uid_org, $uid_4_filename);
	saveJoinTime( $uid_org, $uid_4_filename);
?>

<script language="javascript" type="text/javascript">
$(function(){
	
	// Flashへの引数セット
	var flashvars = {};
	flashvars.conf_url = "getparam.php";
	flashvars.uid_4_filename = "<?= $uid_4_filename ?>";
	flashvars.uid_org = "<?= $uid_org ?>";
	flashvars.class_id = "<?= LIVECLASS_CLASS_ID ?>";
	flashvars.language = "japanese";
	flashvars.text_url = "jp.xml";
	var params = {};
	//params.salign = "lt";
	//params.scale = "noscale";
	params.allowScriptAccess = "always";
	var attributes = {};
	
	var now = new Date();
	var min = now.getMinutes();
	var sec = now.getSeconds();
	swfobject.embedSWF( "0916live.swf?" + min + sec, "flashAlternativeContent<?= $num ?>", "435px", "900px", "11.0.0", false, flashvars, params, attributes);

});
//-->
</script>
<style>
#flashAlternativeContent<?= $num ?> {
	float:left;width:435px;height:900px;border:#737373 5px solid;
}</style>
<?php
}
?>
</head>
<body>
<?php
for( $num = $start_num; $num <= $end_num; $num++) {
?>

<div id="flashAlternativeContent<?= $num ?>">
<div style="border:#fff 5px solid;padding:30px;">
<h2 align="center">このコンテンツを視聴するには Flash が必要です</h2>
<p align="center">このコンテンツを視聴するには、JavaScript が有効になっていることと、最新バージョンの Adobe Flash Player を利用していることが必要です。</p>
<p align="center"><a href="http://www.adobe.com/go/getflashplayer">今すぐ無償 Flash Player をダウンロード！<br>
<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" width="112" height="33" /></a></p>
</div>

<h2 class="blue">ライブアンケート</h2>
<p style="margin:10px;min-height:100px">iPhoneやiPadなどのiOS端末ではライブアンケートがご利用できません。ライブアンケート機能をご利用いただくには、このページをパソコンまたはAndroid端末でご覧下さい。</p>
<h2 class="blue">チャット</h2>
<p style="margin:10px;min-height:100px">iPhoneやiPadなどのiOS端末ではチャットがご利用できません。チャット機能をご利用いただくには、このページをパソコンまたはAndroid端末でご覧下さい。</p>

</div><!-- /#flashAlternativeContent -->
<?php
}
?>

</body>
</html>
