<?php
require_once "conf.php";
////////////////////////////////////
// Flashに渡す変数をXML形式で生成
////////////////////////////////////

//--------------------------------------------------
// 1. 定数（CONFファイルより）をXMLにする
//--------------------------------------------------
$host = LIVECLASS_HOST;
$app_name = LIVECLASS_APP_NAME;
$saveChat_url = LIVECLASS_BASE_URL.'saveChat.php';
$setQuestionnaire_url = LIVECLASS_BASE_URL.'setQuestionnaire.php';
$gettime_url = LIVECLASS_BASE_URL.'getTime.php';

$senddata = <<<EOF
<param name="HOST" value="{$host}" />
<param name="APP_NAME" value="{$app_name}" />
<param name="SAVECHAT_URL" value="{$saveChat_url}" />
<param name="SETQUESTIONNAIRE_URL" value="{$setQuestionnaire_url}" />
<param name="PROTOCOL" value="rtmp" />
<param name="PORT" value="" />
<param name="GETTIME_URL" value="{$gettime_url}" />
EOF;

$senddata .= '<param name="COMMON_UNIX_TIME" value="'. time() .'" />';


//--------------------------------------------------
// 2. POST値取得
// class_id: ライブ授業のID
// uid: 講師または生徒のID
//--------------------------------------------------
$class_id = isset( $_POST['class_id'])?$_POST['class_id']:"";
$uid = isset( $_POST['uid'])?$_POST['uid']:"";

//--------------------------------------------------
// 3. セミナーが終了済みか
//--------------------------------------------------
if( 1 /* 終了済みかの判定はいる */) {
	$senddata .= '<param name="AVAILABLE" value="1" />'; // 有効
} else {
	$senddata .= '<param name="AVAILABLE" value="0" />'; // 授業が終了済み
}


//--------------------------------------------------
// 4. class_idに紐づけられている各種基本情報を
//    DBから取り出し、XMLにする
//--------------------------------------------------


// 授業名
$senddata .= '<param name="CLASS_TITLE" value="セミナー名はいる" />';
$senddata .= '<param name="START_TIME" value="2012-07-23 00:59:00" />';
$senddata .= '<param name="END_TIME" value="2015-12-25 14:00:00" />';

//--------------------------------------------------
// 5. class_idとuidに紐づけられている各種情報を
//    DBから取り出し、XMLにする
//--------------------------------------------------
$senddata .= "\n<member uid='lecturer' name='講師' img='img/face.jpg' islecturer='1'>";

// 講師の動画配信設定XML
//$senddata .= file_get_contents( "db/stream/stream_lecturer.xml"); 
$senddata .= "</member>";

//-------------------------------------------------------------------
// 8. プロトコル／ポートの自動きりかえ指定XMLファイルの読み込み
//-------------------------------------------------------------------
$senddata .= file_get_contents( "protocollist.xml");


//---------------------------------
// Flashに送信
//---------------------------------
print <<<EOF
<data>
{$senddata}
</data>
EOF;


function return_bytes($val) {
    $val = trim($val);
    $last = strtolower($val[strlen($val)-1]);
    switch($last) {
        // 'G' は PHP 5.1.0 以降で使用可能です
        case 'g':
            $val *= 1024;
        case 'm':
            $val *= 1024;
        case 'k':
            $val *= 1024;
    }

    return $val;
}

?>
