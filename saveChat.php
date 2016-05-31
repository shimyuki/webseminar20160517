<?php
require_once "conf.php";
if (! file_exists(ROOT_LOG)) {
   if( mkdir( ROOT_LOG, 0755, true)) {
	   //echo ROOT_LOG. " 生成成功<br />";
   } else {
	   error_log("can't mkdir ". ROOT_LOG);
	   echo ROOT_LOG. " 生成失敗<br />";
   }
}


switch(  $_POST['mode']) {
	
case 'chat' :
	   $path = ROOT_LOG. "/chat.html";
	   unlink($path);
	   file_put_contents($path,$_POST['text'], LOCK_EX);
	break;
	/*
case 'chat_deleted' :
	   $path = ROOT_LOG. "/chat_more.html";
	   $content=$_POST['text'].file_get_contents($path);
	   file_put_contents($path,$content, LOCK_EX);
	break;
*/
case 'chat_append' :
	   $path = ROOT_LOG. "/chat_all.html";
	   file_put_contents($path,$_POST['text'], FILE_APPEND | LOCK_EX);
	break;
}



?>
