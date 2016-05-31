<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja" xml:lang="ja">
	<head>
		<title>0916live</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script language="JavaScript" type="text/javascript" src="js/swfobject.js"></script>
<META NAME="ROBOTS" CONTENT="NOINDEX,NOFOLLOW,NOARCHIVE" />
<?php
require_once "conf.php";
require_once "functions.php";
mkdirRootLog();

$uid_org = isset($_REQUEST['uid']) ? $_REQUEST['uid'] : "no_uid";
$uid_4_filename = md5($uid_org);
registerUid( $uid_org, $uid_4_filename);
saveJoinTime( $uid_org, $uid_4_filename);

$updateanswer_url = "updateAnswer.php";
?>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>

<script language="javascript" type="text/javascript">
function flashFunc_log( msg) {
	if(window.console && typeof window.console.log === 'function') {
		console.log( msg);
	}
}
function onClickAnswer(){
	//var uid_4_filename = '<?= $uid_4_filename ?>';
	$.post("<?= $updateanswer_url ?>" + "?" + Math.random(), { 
				q1:$('input[name="q1"]:checked').val(),
				q2:$('textarea[name="q2"]').val(),
				q3:$('input[name="q3"]:checked').val(),
				q4:$('input[name="q4"]:checked').val(),
				q5:$('input[name="q5"]:checked').val(),
				uid_4_filename:"<?= $uid_4_filename?>"}, function(ret) {
		alert(ret);
	});
}
$(function(){
	$("#rightcolum").height( $("#leftcolum").height());
	
	
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
swfobject.embedSWF( "0916live.swf?" + min + sec, "flashAlternativeContent", "100%", "100%", "11.0.0", false, flashvars, params, attributes);

});


//-->
</script>
<style type="text/css" media="screen">
	html, body { height:100%; background-color: #f0f0f0;}
	body { margin:0; padding:0; overflow:hidden;	font-family: verdana, helvetica, arial, "Hiragino Maru Gothic Pro", "ヒラギノ丸ゴ Pro W4", Osaka,"ＭＳ Ｐゴシック", "ＭＳ ゴシック", "MS UI Gothic", sans-serif;}

	#flashAlternativeContent { width:100%; height:100%; }
	#body {
		margin:0 auto;
		padding:0 1px;
		width:943px;
		border-left:#d9d9d9 1px solid;
		border-right:#d9d9d9 1px solid;
		background-color: #fff;
		font-size:13px;
	}
	#main {
		
	}
	#leftcolum {
		float:left;
		width:500px;
	}
	#ustream {
		background:#fff;/*#fcf7ed;*/
		padding:10px  10px 0;
	}
	#question {
		margin:30px 10px 10px;
		padding:10px;
		background:#f3e1be;
	}
	#question h2 {
		font-weight:bold;
		color:#000;
		font-size:14px;
		background:#f3e1be;
		padding:0 10px 0px;
		margin:0;
	}
	#question h2 span {
		color:#FF6600;
	}
	#rightcolum {
		float:right;
		width:440px;
		height:800px;
		border-left:#d9d9d9 1px solid;
		padding-left:1px;
	}
	.tb_q {
		margin:10px 0 0 0;
		padding:10px;
		background:#FCF7ED;
		width:100%;
		border:#fff 1px solid;
	}
	.tb_q th{
		border-top:#fff 1px solid;
		text-align:left;
		padding-top:10px;
	}
	.tb_q th.th1{
		color:#FF6600;
	}
	.tb_q td{
		text-align:left;
		padding-top:10px;
		padding-bottom:10px;
		border-bottom:#d9d9d9 1px solid;
	}
	.tb_q .first th{
		border-top:none;
		padding-top:0px;
	}
.clearfix {
	overflow: hidden;
}

.clearfix:after {
	content: "";
	display: block;
	clear: both;
	height: 1px;
	overflow: hidden;
}

* html .clearfix {
	height: 1em;
	overflow: visible;
}

</style>
</head>
<body>

<div id="body">

<div id="main" class="clearfix">
<div id="leftcolum">
<div id="ustream">
<iframe width="480" height="302" src="http://www.ustream.tv/embed/17305725?v=3&amp;wmode=direct" scrolling="no" frameborder="0" style="border: 0px none transparent;">    </iframe>
<br /><a href="http://www.ustream.tv" style="font-size: 12px; line-height: 20px; font-weight: normal; text-align: left;" target="_blank">Broadcast live streaming video on Ustream</a>
</div><!-- /#ustream -->

<div id="question">
<?php
if( answered($uid_org, $uid_4_filename)) {
?>
<?php
} else {
?>
<h2><span>●</span> 講義が終わりましたら以下の質問にお答えください</h2>
<p style="margin:3px 0px 0px 1.5rem">入力後「回答する」ボタンを押してください。</p>
<form>
<table cellpadding="0" cellspacing="0" class="tb_q">
<tr class="first">
<th class="th1">Q1</th><th>今日のライブはいかがでしたか？</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="大変役にたった" name="q1" />大変役にたった</label>　
<label><input type="radio" value="ふつう" name="q1" />ふつう</label>　
<label><input type="radio" value="役にたたなかった" name="q1" />役にたたなかった</label></td>
</tr>

<tr>
<th class="th1">Q2</th><th>今日のライブの内容でご質問があれば記入ください</th>
</tr>
<tr>
<td>&nbsp;</td><td><textarea rows="5" cols="40" name="q2"></textarea></td>
</tr>

<tr>
<th class="th1">Q3</th><th>質問はいる</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="回答１" name="q3" />回答１</label>　
<label><input type="radio" value="回答２" name="q3" />回答２</label>　
<label><input type="radio" value="回答３" name="q3" />回答３</label></td>
</tr>

<tr>
<th class="th1">Q4</th><th>質問はいる</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="回答１" name="q4" />回答１</label>　
<label><input type="radio" value="回答２" name="q4" />回答２</label>　
<label><input type="radio" value="回答３" name="q4" />回答３</label></td>
</tr>

<tr>
<th class="th1">Q5</th><th>質問はいる</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="回答１" name="q5" />回答１</label>　
<label><input type="radio" value="回答２" name="q5" />回答２</label>　
<label><input type="radio" value="回答３" name="q5" />回答３</label></td>
</tr>


<tr>
<th colspan="2" style="text-align:center"><input type="button" onclick="onClickAnswer()" value="回答する" /></th>
</tr>


</table>
</form>
<?php
}
?>

</div><!-- /#question -->
</div><!-- /#leftcolum -->
<div id="rightcolum">
<div id="flashAlternativeContent">
<div style="border:#f0f0f0 5px solid;padding:30px;">
<h2 align="center">このコンテンツを視聴するには Flash が必要です</h2>
<p align="center">このコンテンツを視聴するには、JavaScript が有効になっていることと、最新バージョンの Adobe Flash Player を利用していることが必要です。</p>
<p align="center"><a href="http://www.adobe.com/go/getflashplayer">今すぐ無償 Flash Player をダウンロード！<br>
<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" width="112" height="33" /></a></p>
</div>
</div><!-- /#flashAlternativeContent -->

</div><!-- /#rightcolum -->
</div><!-- /#main -->
</div><!-- /#body -->
</body>
</html>
