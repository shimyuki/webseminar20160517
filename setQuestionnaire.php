<?php
/////////////////////////////////////////
// アンケート編集/保存時にFlashから呼ばれる
/////////////////////////////////////////

// class_idと生成日時のセットでアンケートはユニークとなる
echo "class_id（テキスト）：" . $_POST['class_id'] . "<br />";
echo "生成日時（テキスト）：" . $_POST['date'] . "<br />"; 

echo "編集モード（新規:new／修正:mod／削除:del）：". $_POST['mode'] . "<br />";

echo "アンケートタイトル：" . $_POST['title'] . "<br />";
echo "公開設定（公開:1／非公開:0）：" . $_POST['showall'] . "<br />";
echo "本文（テキスト）：" . $_POST['description'] . "<br />";
echo "選択肢（テキストの配列）：" . get_arr( 'selection_arr');
echo "回答結果（テキストとテキストの連想配列）：" . get_hash( 'result_arr');


function get_arr ( $post_key) {
	$ret = "";
	if( isset( $_POST[$post_key])) {
		$arr = $_POST[$post_key];
		for( $i = 0; $i < count($arr); $i++) {
			$ret .=  $post_key . "[$i] =>" . $arr[$i] . "<br />";
		}
	}
	return $ret;
}

function get_hash ( $post_key) {
	$ret = "";
	if( isset( $_POST[ $post_key])) {
		$hash = $_POST[ $post_key];
		foreach ( $hash as $key => $val) {
			$ret .=  $key . " => " . $val . "<br />";
		}
	}
	return $ret;
}

?>
