<?PHP
// Webセミナー用の定数
define( 'LIVECLASS_CLASS_ID', 'live_class_0905f'); // 何でも良いですが、変更するとチャットの履歴などがクリアされますので、本番期間の開始以降は変更しないでください。
define( 'LIVECLASS_HOST', '202.210.133.92'); //  Wowzaサーバ
define( 'LIVECLASS_BASE_URL', str_replace(basename($_SERVER["PHP_SELF"]),"", (empty($_SERVER["HTTPS"]) ? "http://" : "https://") . $_SERVER["HTTP_HOST"] . $_SERVER["PHP_SELF"])); // WebサーバURL
define( 'LIVECLASS_APP_NAME', '0916live'); // 変更しないでください。
define( 'ROOT_LOG', dirname(__FILE__) . "/log/".LIVECLASS_CLASS_ID); // ログファイルの出力先URL。適宜変更してください。
define( 'UID_CSV', "uid_4_filename.csv"); // 変更の必要は無いです。

?>