<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="ja" xml:lang="ja">
	<head>
		<title>0916live</title>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
        <meta name="viewport" content="width=1163">
<script language="JavaScript" type="text/javascript" src="js/swfobject.js"></script>
<META NAME="ROBOTS" CONTENT="NOINDEX,NOFOLLOW,NOARCHIVE" />
<?php
if(isset($_REQUEST['uid']) && preg_match('/^[a-zA-Z0-9_-]+$/', $_REQUEST['uid'])) {
?>
<?php
require_once "conf.php";
require_once "functions.php";
require_once "UserAgent.php";
mkdirRootLog();

$uid_org = isset($_REQUEST['uid']) ? $_REQUEST['uid']: "no_uid";
$uid_4_filename = md5($uid_org);
registerUid( $uid_org);
saveJoinTime( $uid_org);

$updateanswer_url = "updateAnswer.php";

$ua = new UserAgent();
?>
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.1/jquery.min.js"></script>

<script language="javascript" type="text/javascript">
function flashFunc_log( msg) {
	if(window.console && typeof window.console.log === 'function') {
		console.log( msg);
	}
}
function onClickAnswer(){
	$.post("<?= $updateanswer_url ?>" + "?" + Math.random(), { 
				q1:$('input[name="q1"]:checked').val(),
				q1b:$('input[name="q1b"]').val(),
				q2:$('input[name="q2"]:checked').val(),
				q2b:$('input[name="q2b"]').val(),
				q3:$('input[name="q3"]:checked').val(),
				q3b:$('input[name="q3b"]').val(),
				q4:$('input[name="q4"]:checked').val(),
				q5:$('textarea[name="q5"]').val(),
				q6:$('textarea[name="q6"]').val(),
				q7:$('input[name="q7"]:checked').val(),
				q8:$('input[name="q8"]:checked').val(),
				q9:$('input[name="q9"]:checked').val(),
				q10:$('input[name="q10"]:checked').val(),
				q11_a:$('input[name="q11_a"]').val(),
				q11_b:$('input[name="q11_b"]').val(),
				q12:$('textarea[name="q12"]').val(),
				uid_4_filename:"<?= $uid_4_filename?>"}, function(ret) {
		var r = alert(ret);
		if( r) {
			window.close();
		}
	});
}
$(function(){
	$("#rightcolum").height( $("#leftcolum").height());
	
	
	// Flashへの引数セット
	var flashvars = {};
	flashvars.conf_url = "getparam.php";
	flashvars.uid_4_filename = "<?= $uid_4_filename ?>";
	flashvars.uid_org = "<?= addslashes($uid_org) ?>";
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

//console.log();
	changeStatusQ1();
	$("input[name='q1']").on("change", changeStatusQ1);
	changeStatusQ2();
	$("input[name='q2']").on("change", changeStatusQ2);
	changeStatusQ3();
	$("input[name='q3']").on("change", changeStatusQ3);
	//var chk = $("name['q1']").prop('checked'),
	//obj = $('#test_input');
	//(chk) ? obj.prop('disabled',false) : obj.prop('disabled',true) ;
});
function changeStatusQ1() {
	if( $("input[name='q1']:checked").val() == "その他") {
		$("#q1b").prop("disabled", false);
	} else {
		$("#q1b").prop("disabled", true);
	}
}
function changeStatusQ2() {
	if( $("input[name='q2']:checked").val() == "その他") {
		$("#q2b").prop("disabled", false);
	} else {
		$("#q2b").prop("disabled", true);
	}
}
function changeStatusQ3() {
	if( $("input[name='q3']:checked").val() == "その他") {
		$("#q3b").prop("disabled", false);
	} else {
		$("#q3b").prop("disabled", true);
	}
}


//-->
</script>
<style type="text/css" media="screen">
	html, body { background-color: #f0f0f0;}
	html{overflow-y:scroll;}
	body { margin:0; padding:0; overflow:hidden;	font-family: verdana, helvetica, arial, "Hiragino Maru Gothic Pro", "ヒラギノ丸ゴ Pro W4", Osaka,"ＭＳ Ｐゴシック", "ＭＳ ゴシック", "MS UI Gothic", sans-serif;}

	/*#flashAlternativeContent { width:100%; height:100%; }*/
	#body {
		margin:0 auto;
		padding:0 1px;
		width:1163px;
		border-left:#d9d9d9 1px solid;
		border-right:#d9d9d9 1px solid;
		background-color: #fff;
		font-size:13px;
		line-height:155%;
	}
	#main {
		margin:0;
	}
	#leftcolum {
		float:left;
		width:720px;
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
		margin-top:10px;
	}
	h2.blue {
		padding:10px;
		margin:0;
		font-weight:bold;
		color:#000;
		font-size:14px;
		background:#d2e5f1;
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
		vertical-align:top;
	}
	.tb_q th.th1{
		color:#FF6600;
		width:3em;
		white-space:nowrap;
	}
	.tb_q td{
		text-align:left;
		padding-top:10px;
		padding-bottom:10px;
		border-bottom:#d9d9d9 1px solid;
		vertical-align:top;
	}
	.tb_q .first th{
		border-top:none;
	}
	.tb_q th.title {
		border-top:#fff 1px solid;
		text-align:center;
		padding:8px 0 8px 0;
		background:#FF6600;
		color:#fff;
	}
	
.btn {
	text-align:center;
}
.btn a {
	border:none;
	color:#fff !important;
	font-weight:bold;
	background-color: #d50107;
    background: -moz-linear-gradient(top, #f79169, #d50107); /* mozilla */
    background: -webkit-gradient(linear, center top, center bottom, from(#f79169), to(#d50107)); /* Webkit */
    filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0,startColorstr='#f79169', endColorstr='#d50107'); /* IE5.5 IE6 IE7 */
	-ms-filter: "progid:DXImageTransform.Microsoft.gradient (GradientType=0, startColorstr=#f79169, endColorstr=#d50107)"; /* IE8 */
	
	border-radius: 5px;        /* CSS3草案 */  
    -webkit-border-radius: 5px;    /* Safari,Google Chrome用 */  
    -moz-border-radius: 5px;   /* Firefox用 */
	
	display:inline-block;
	padding:20px 30px;	
	
	text-decoration:none;
	font-size:20px;
	text-shadow:none;
	color:#fff;
	text-decoration:none;
}
.btn a:hover {
	background-color: #f79169;
    background: -moz-linear-gradient(top, #d50107, #f79169); /* mozilla */
    background: -webkit-gradient(linear, center top, center bottom, from(#d50107), to(#f79169)); /* Webkit */
    filter: progid:DXImageTransform.Microsoft.gradient(GradientType=0,startColorstr='#d50107', endColorstr='#f79169'); /* IE5.5 IE6 IE7 */
	-ms-filter: "progid:DXImageTransform.Microsoft.gradient (GradientType=0, startColorstr=#d50107, endColorstr=#f79169)"; /* IE8 */
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

#q1b { width:150px;}
#q2b { width:70px;}
#q3b { width:70px;}
</style>
</head>
<body>

<div id="body">
<img src="img/banner004-1163.png" width="1163" height="60" />
<div id="main" class="clearfix">
<div id="leftcolum">
<div id="ustream">

<div>
<iframe width="700" height="437" frameborder="no" style="border: 0 none transparent;" src="//www.ustream.tv/embed/18822210?wmode=direct&amp;autoplay=true&amp;showtitle=false"></iframe>
</div>

</div><!-- /#ustream -->

<div id="question">
<?php
if( answered($uid_org, $uid_4_filename)) {
?>
<?php
} else {
?>
<h2><span>●</span>ライブセミナーが終わりましたら以下の質問にお答えください。</h2>
<p style="margin:3px 0px 0px 1.5rem">入力後「アンケートに回答して、ライブを終了します」ボタンを押してください。</p>
<form>
<table cellpadding="0" cellspacing="0" class="tb_q">
<tr>
<th class="title" colspan="2">本WEBライブセミナーに参加された先生全員にお伺いします</th>
</tr>
<tr class="first">
<th class="th1">Q1</th><th>今日のライブはいかがでしたか。</th>
</tr>
<tr>
<td>&nbsp;</td><td nowrap="nowrap"><label><input type="radio" value="大変良かった" name="q1" />大変良かった</label>　
<label><input type="radio" value="良かった" name="q1" />良かった</label>　
<label><input type="radio" value="普通" name="q1" />普通</label>　
<label><input type="radio" value="良くなかった" name="q1" />良くなかった</label>　<?php if($ua->getDevice()=="iPhone" || $ua->getDevice()=="android_m") ?><br /><?php ?>
<label><input type="radio" value="その他" name="q1" />その他</label> <input type="text" name="q1b" id="q1b" /></td>
</tr>
<tr>
<th class="th1">Q2</th><th>普段、医療用医薬品に関する情報はどこから入手していますか。</th>
</tr>
<tr>
<td>&nbsp;</td><td nowrap="nowrap">
<label><input type="radio" value="MR" name="q2" />MR</label>　
<label><input type="radio" value="本・雑誌" name="q2" />本・雑誌</label>　
<label><input type="radio" value="製薬会社ホームページ" name="q2" />製薬会社ホームページ</label>　<?php if($ua->getDevice()=="iPhone" || $ua->getDevice()=="android_m") ?><br /><?php ?>
<label><input type="radio" value="日経DI等情報サイト" name="q2" />日経DI等情報サイト</label>　
<label><input type="radio" value="その他" name="q2" />その他</label> <input type="text" name="q2b" id="q2b" />
</td>
</tr>

<tr>
<th class="th1">Q3</th><th>医療用医薬品に関する情報の望ましい提供方法は何ですか。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="MR" name="q3" />MR</label>　
<label><input type="radio" value="本・雑誌" name="q3" />本・雑誌</label>　
<label><input type="radio" value="製薬会社ホームページ" name="q3" />製薬会社ホームページ</label>　<?php if($ua->getDevice()=="iPhone" || $ua->getDevice()=="android_m") ?><br /><?php ?>
<label><input type="radio" value="日経DI等情報サイト" name="q3" />日経DI等情報サイト</label>　
<label><input type="radio" value="その他" name="q3" />その他</label> <input type="text" name="q3b" id="q3b" />
</td>
</tr>
</table>


<table cellpadding="0" cellspacing="0" class="tb_q">
<tr>
<th class="title" colspan="2">薬剤師の先生にお伺いします　<span style="color:#000000">外用剤の混合に関してお教えください</span></th>
</tr>
<tr>
<th class="th1">Q4</th><th>軟膏などを混合することはありますか。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="はい" name="q4" />はい</label>　
<label><input type="radio" value="いいえ" name="q4" />いいえ</label></td>
</tr>

<tr>
<th class="th1">Q5</th><th>Q4にて「はい」と回答された方で良く混合している処方を教えてください。<br />
<span style="font-weight:normal">回答例）アンテベート軟膏：白色ワセリン＝１：１</span></th>
</tr>
<tr>
<td>&nbsp;</td><td><textarea name="q5" cols="60" role="3"></textarea></td>
</tr>

<tr>
<th class="th1">Q6</th><th>混合後に問題のあった処方を教えてください。</th>
</tr>
<tr>
<td>&nbsp;</td><td><textarea name="q6" cols="60" role="3"></textarea></td>
</tr>
<tr>
<th class="th1">Q7</th><th>混合には何を使用していますか。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="軟膏板" name="q7" />軟膏板</label>　
<label><input type="radio" value="乳鉢・乳棒" name="q7" />乳鉢・乳棒</label>　
<label><input type="radio" value="自転・公転型混合機" name="q7" />自転・公転型混合機</label>　
<label><input type="radio" value="その他の機械" name="q7" />その他の機械</label></td>
</tr>
<tr>
<th class="th1">Q8</th><th>混合可否は何で調べていますか。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="本：配合変化ハンドブック等" name="q8" />本：配合変化ハンドブック等</label>　
<label><input type="radio" value="製薬会社への問い合わせ" name="q8" />製薬会社への問い合わせ</label>　
<label><input type="radio" value="独自に作成した表など" name="q8" />独自に作成した表など</label></td>
</tr>
<tr>
<th class="th1">Q9</th><th>混合不可等の場合は処方医の先生に問い合わせますか。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="毎回問い合わせる" name="q9" />毎回問い合わせる</label>　
<label><input type="radio" value="よく問い合わせる" name="q9" />よく問い合わせる</label>　
<label><input type="radio" value="あまり問い合わせない" name="q9" />あまり問い合わせない</label></td>
</tr>
<tr>
<th class="th1">Q10</th><th>問い合わせた結果について教えて下さい。</th>
</tr>
<tr>
<td>&nbsp;</td><td><label><input type="radio" value="変更になる" name="q10" />変更になる</label>　
<label><input type="radio" value="あまり変更にならない" name="q10" />あまり変更にならない</label></td>
</tr>
<tr>
<th class="th1">Q11</th><th>Q10にて「変更になる」と回答された先生で変更前後の組み合わせを教えて下さい。</th>
</tr>
<tr>
<td>&nbsp;</td><td>変更前：<input type="text" name="q11_a" size="60" /><br />
<p style="margin-top:3px;">変更後：<input type="text" name="q11_b"  size="60" /></p></td>
</tr>
<tr>
<th class="th1">Q12</th><th>外用剤の調剤や製剤で困っていること等がありましたら教えて下さい。</th>
</tr>
<tr>
<td>&nbsp;</td><td><textarea name="q12" cols="60" role="3"></textarea></td>
</tr>


</table>

<p class="btn"><a href="javascript:void(0)" onclick="onClickAnswer()" >アンケートに回答して、ライブを終了します</a></p>

</form>

<p>ご協力ありがとうございました。<br />
なお、本アンケートの集計結果等は、後日鳥居薬品（株）皮膚外用薬サイト”鳥居の外用薬”に掲載する予定です。</p>
<p><strong>鳥居の外用薬</strong> <a href="http://www.torii.co.jp/hifu/top.html" target="_blank">http://www.torii.co.jp/hifu/top.html</a></p>
<?php
}
?>

</div><!-- /#question -->
</div><!-- /#leftcolum -->
<div id="rightcolum">
<div id="flashAlternativeContent">
<?php
switch( $ua->getDevice() ) {
	case "android_m":
	case "android_t":
	case "pc":
?>
<div style="border:#fff 5px solid;padding:30px;">
<h2 align="center">このコンテンツを視聴するには Flash が必要です</h2>
<p align="center">このコンテンツを視聴するには、JavaScript が有効になっていることと、最新バージョンの Adobe Flash Player を利用していることが必要です。</p>
<p align="center"><a href="http://www.adobe.com/go/getflashplayer">今すぐ無償 Flash Player をダウンロード！<br>
<img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" width="112" height="33" /></a></p>
</div>
<?php
	break;
	default:
?>
<h2 class="blue">ライブアンケート</h2>
<p style="margin:10px;min-height:100px">iPhoneやiPadなどのiOS端末ではライブアンケートがご利用できません。ライブアンケート機能をご利用いただくには、このページをパソコンまたはAndroid端末でご覧下さい。</p>
<h2 class="blue">チャット</h2>
<p style="margin:10px;min-height:100px">iPhoneやiPadなどのiOS端末ではチャットがご利用できません。チャット機能をご利用いただくには、このページをパソコンまたはAndroid端末でご覧下さい。</p>
<?php
	break;
}
?>

</div><!-- /#flashAlternativeContent -->

</div><!-- /#rightcolum -->
</div><!-- /#main -->
</div><!-- /#body -->
</body>
<?php
}else{
?>
</head>
<body>
</body>

<?php
}
?>

</html>
