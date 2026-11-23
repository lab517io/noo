// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appMenuFile => 'ファイル';

  @override
  String get appMenuEdit => '編集';

  @override
  String get appMenuView => '表示';

  @override
  String get appMenuTools => 'ツール';

  @override
  String get appMenuDebug => 'デバッグ';

  @override
  String get appMenuHelp => 'ヘルプ';

  @override
  String get appMenuWindow => 'ウインドウ';

  @override
  String get appMenuOpen => '開く...';

  @override
  String get appMenuOpenDatabase => 'データベースを開く...';

  @override
  String get appMenuNewDatabase => '新規データベース...';

  @override
  String get appMenuExportObsidian => 'Obsidian に書き出す...';

  @override
  String get appMenuImportObsidian => 'Obsidian から読み込む...';

  @override
  String get appMenuExit => '終了';

  @override
  String get appMenuFind => '検索...';

  @override
  String get appMenuTheme => 'テーマ';

  @override
  String get appMenuThemeEllipsis => 'テーマ...';

  @override
  String get appThemeSystem => 'システム';

  @override
  String get appThemeLight => 'ライト';

  @override
  String get appThemeDark => 'ダーク';

  @override
  String get appMenuTimeline => 'タイムライン...';

  @override
  String get appMenuTimeReport => '時間レポート...';

  @override
  String get appMenuCompactDatabase => 'データベースを最適化...';

  @override
  String get appMenuSyncNow => '今すぐ同期';

  @override
  String get appMenuSyncP2p => 'P2P 同期...';

  @override
  String get appMenuPreferences => '環境設定...';

  @override
  String get appMenuViewChangeHistory => '変更履歴を表示...';

  @override
  String get appMenuGenerateTestData => 'テストデータを生成';

  @override
  String get appMenuGenerateLargeDataset => '大規模データセットを生成';

  @override
  String get appMenuClearAllData => 'すべてのデータを消去';

  @override
  String get appMenuCheckForUpdate => 'アップデートを確認...';

  @override
  String get appMenuLogs => 'ログ';

  @override
  String get appMenuSyncLog => '同期ログ...';

  @override
  String get appMenuAppLog => 'アプリログ...';

  @override
  String appMenuAbout(String appName) {
    return '$appName について';
  }

  @override
  String get appMacMenuCheckForUpdate => 'アップデートを確認…';

  @override
  String get appMacMenuSettings => '設定…';

  @override
  String appMacMenuQuit(String appName) {
    return '$appName を終了';
  }

  @override
  String get appMacMenuOpen => '開く…';

  @override
  String get appMacMenuNewDatabase => '新規データベース…';

  @override
  String get appMacMenuExportObsidian => 'Obsidian に書き出す…';

  @override
  String get appMacMenuImportObsidian => 'Obsidian から読み込む…';

  @override
  String get appMacMenuUndo => '取り消す';

  @override
  String get appMacMenuRedo => 'やり直す';

  @override
  String get appMacMenuCut => 'カット';

  @override
  String get appMacMenuPaste => 'ペースト';

  @override
  String get appMacMenuSelectAll => 'すべてを選択';

  @override
  String get appMacMenuFind => '検索…';

  @override
  String get appMacMenuTimeline => 'タイムライン…';

  @override
  String get appMacMenuTimeReport => '時間レポート…';

  @override
  String get appMacMenuCompactDatabase => 'データベースを最適化…';

  @override
  String get appMacMenuSyncP2p => 'P2P 同期…';

  @override
  String get appMacMenuViewChangeHistory => '変更履歴を表示…';

  @override
  String get appMacMenuSyncLog => '同期ログ…';

  @override
  String get appMacMenuAppLog => 'アプリログ…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'データベースを開く';

  @override
  String get appCreateDatabaseDialogTitle => '新しいデータベースを作成';

  @override
  String get appIncorrectPasswordRetry => 'パスワードが正しくありません。もう一度入力してください。';

  @override
  String appDatabaseOpened(String fileName) {
    return '開きました: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'データベースを開けませんでした: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return '作成しました: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'データベースを作成できませんでした: $error';
  }

  @override
  String get appOpenDatabaseFirst => '先にデータベースを開いてください';

  @override
  String get appNoDatabaseOpen => 'データベースが開かれていません';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'データベースファイルを読み込めません: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt => 'パスワードが正しくないか、データベースが破損しています';

  @override
  String get appExportObsidianDialogTitle => 'Obsidian ディレクトリに書き出す';

  @override
  String get appImportObsidianDialogTitle => 'Obsidian ディレクトリから読み込む';

  @override
  String get appImportObsidianZipDialogTitle => 'Obsidian の .zip を読み込む';

  @override
  String get appExportingObsidian => 'Obsidian 形式で書き出しています...';

  @override
  String get appImportingObsidian => 'Obsidian 形式から読み込んでいます...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のタスク',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のタイムラインファイル',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個の画像',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の時間記録',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return '書き出しました: $tasks、$timelineFiles、$images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return '読み込みました: $tasks、$timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return '書き出しに失敗しました: $error';
  }

  @override
  String appImportFailed(String error) {
    return '読み込みに失敗しました: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obsidian 書き出し（$count 件のタスク）',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'ディレクトリが存在しません: $path';
  }

  @override
  String get appSyncNotConfigured => '同期が設定されていません。先に同期設定を開いてください。';

  @override
  String get appNoSyncServer =>
      '同期サーバーが設定されていません。P2P 同期... (Shift+F5) を使うか、環境設定でサーバーを追加してください。';

  @override
  String get appUnsyncedChangesTitle => '未同期の変更';

  @override
  String get appUnsyncedChangesBody => '同期されていない変更があります。同期しますか？';

  @override
  String get appDontSync => '同期しない';

  @override
  String get appSync => '同期';

  @override
  String get appSelectTaskFirst => '先にタスクを選択してください';

  @override
  String get appGenerateTestDataBody => '階層と時間記録を持つサンプルタスクを作成します。\n\n続行しますか？';

  @override
  String get appGenerate => '生成';

  @override
  String get appTestDataGenerated => 'テストデータを生成しました';

  @override
  String get appGenerateLargeDatasetBody =>
      '次の内容で大規模なデータセットを作成します:\n- 最上位タスク 20 件\n- 最大 5 階層\n- 各タスクに最大 6 件の子タスク\n- 多数のタスクに時間記録\n\nしばらく時間がかかる場合があります。続行しますか？';

  @override
  String get appGeneratingData => 'データを生成しています...';

  @override
  String get appLargeDatasetGenerated => '大規模データセットを生成しました';

  @override
  String get appClearAllDataBody =>
      'すべてのタスク、時間記録、添付ファイルを完全に削除します。\n\nこの操作は取り消せません。よろしいですか？';

  @override
  String get appDeleteAll => 'すべて削除';

  @override
  String get appAllDataCleared => 'すべてのデータを消去しました';

  @override
  String get appCompactDatabaseTitle => 'データベースを最適化';

  @override
  String get appCompactDatabaseBody =>
      'データベースファイルを書き直し、削除したタスク、添付ファイル、古い変更履歴が占めていた領域をディスクに返します。\n\n削除した添付ファイルの内容も解放されます。それらを復元した場合は、サーバーから再度ダウンロードされます。\n\n現在表示されている内容は何も削除されません。大きなデータベースでは時間がかかり、完了するまでアプリは使用できません。';

  @override
  String get appCompact => '最適化';

  @override
  String get appCompactingDatabase => 'データベースを最適化しています...';

  @override
  String appCompactingFailed(String error) {
    return '最適化に失敗しました: $error';
  }

  @override
  String get appDatabaseCompacted => 'データベースを最適化しました';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'データベースを最適化しました — $freed を解放（現在 $size）';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'データベースを最適化しました — すでに最適化済みです（$size）';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result。$note';
  }

  @override
  String get appFindTooltip => '検索';

  @override
  String get appSyncNowTooltip => '今すぐ同期';

  @override
  String get appBiometricFailed => '生体認証に失敗しました。パスワードを入力してください。';

  @override
  String get appSavedPasswordIncorrect => '保存されたパスワードが正しくありません。パスワードを入力してください。';

  @override
  String get appLoading => '読み込んでいます...';

  @override
  String get appFailedToOpenDatabaseTitle => 'データベースを開けませんでした';

  @override
  String get appOpenAnotherDatabase => '別のデータベースを開く…';

  @override
  String get appBiometricReason => 'Noo データベースのロックを解除';

  @override
  String appWelcomeTitle(String appName) {
    return '$appName へようこそ';
  }

  @override
  String get appWelcomeIntro =>
      '暗号化されたデータベースの保存場所を選択してください。後から「ファイル」メニューで変更できます。';

  @override
  String get appUseDefaultLocation => 'デフォルトの場所を使用';

  @override
  String get appResolving => '確認しています…';

  @override
  String get appCreateNewDatabaseOption => '新しいデータベースを作成…';

  @override
  String get appCreateNewDatabaseSubtitle => '新しい暗号化データベースの場所を指定します。';

  @override
  String get appOpenExistingDatabaseOption => '既存のデータベースを開く…';

  @override
  String get appOpenExistingDatabaseSubtitle => '別の場所にある既存の .noo ファイルを使用します。';

  @override
  String get appQuit => '終了';

  @override
  String get appWelcomeSyncHint =>
      '別のデバイスにデータベースがありますか？ ここで同じパスワードの新しいデータベースを作成し、環境設定 → 同期 で同じユーザー名を使って同期を設定してください。最初の同期でノートが届きます。';

  @override
  String get appTaskFallbackTitle => 'タスク';

  @override
  String get appTabNotes => 'ノート';

  @override
  String get appTabTime => '時間';

  @override
  String get appTabFiles => 'ファイル';

  @override
  String appTabFilesCount(int count) {
    return 'ファイル（$count）';
  }

  @override
  String get appStartTracking => '記録を開始';

  @override
  String get appStopTracking => '記録を停止';

  @override
  String get appNoTaskSelected => 'タスクが選択されていません。';

  @override
  String get appAttachmentsHeading => '添付ファイル';

  @override
  String get appModified => '変更あり';

  @override
  String get appWordWrapOnTooltip => '折り返しはオンです — クリックでオフ';

  @override
  String get appWordWrapOffTooltip => '折り返しはオフです — クリックでオン';

  @override
  String get appTimeTodayTap => '今日の記録時間 — タップで開く';

  @override
  String get appHideTimeTracking => '時間記録を隠す';

  @override
  String get appTimeTodayClick => '今日の記録時間 — クリックで詳細';

  @override
  String get appViewTimeline => 'タイムラインを表示';

  @override
  String get appAttachmentsTap => '添付ファイル — タップで開く';

  @override
  String get appHideAttachments => '添付ファイルを隠す';

  @override
  String get appAttachmentsClick => '添付ファイル — クリックで表示';

  @override
  String get appAddAttachment => '添付ファイルを追加';

  @override
  String get appUntitledInPath => '（無題）';

  @override
  String get appSyncStatusDisabled => '同期は無効です — クリックで同期';

  @override
  String get appSyncStatusUnknown => 'まだ同期されていません — クリックで同期';

  @override
  String get appSyncStatusIdle => '同期済み — クリックで同期';

  @override
  String get appSyncStatusSyncing => '同期しています...';

  @override
  String get appSyncStatusError => '同期エラー — クリックで再試行';

  @override
  String get appSyncStatusPending => '未同期の変更があります — クリックで同期';

  @override
  String get appSyncStatusIncoming => '他のデバイスから変更が届いています — クリックで同期';

  @override
  String appTrackingChipTooltip(String title) {
    return '「$title」の時間を記録中 — クリックで移動';
  }

  @override
  String appStopTrackingTask(String title) {
    return '「$title」の記録を停止';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String appPendingMore(int count) {
    return 'ほか $count 件';
  }

  @override
  String appPendingItemDetail(String fields, String ago) {
    return '$fields · $ago';
  }

  @override
  String appCountItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 項目',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return '同期待ち: $items、$changes';
  }

  @override
  String get appPendingFieldTitle => 'タイトル';

  @override
  String get appPendingFieldContent => '内容';

  @override
  String get appPendingFieldMoved => '移動';

  @override
  String get appPendingFieldReordered => '並べ替え';

  @override
  String get appPendingFieldFlags => 'フラグ';

  @override
  String get appPendingFieldDeleted => '削除';

  @override
  String get appPendingFieldName => '名前';

  @override
  String get appPendingFieldStartTime => '開始時刻';

  @override
  String get appPendingFieldEndTime => '終了時刻';

  @override
  String get appJustNow => 'たった今';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分前',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 時間前',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日前',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'パスワードを入力';

  @override
  String get appSetDatabasePasswordTitle => 'データベースのパスワードを設定';

  @override
  String get appPasswordLabel => 'パスワード';

  @override
  String get appConfirmPasswordLabel => 'パスワードの確認';

  @override
  String get appPleaseEnterPassword => 'パスワードを入力してください';

  @override
  String get appPasswordTooShort => 'パスワードは 4 文字以上にしてください';

  @override
  String get appPasswordsDoNotMatch => 'パスワードが一致しません';

  @override
  String get appPasswordWarning => 'このパスワードはデータベースの暗号化に使われます。忘れるとデータを復元できません。';

  @override
  String get appCreate => '作成';

  @override
  String get appStrengthVeryWeak => '非常に弱い';

  @override
  String get appStrengthWeak => '弱い';

  @override
  String get appStrengthFair => '普通';

  @override
  String get appStrengthGood => '良い';

  @override
  String get appStrengthStrong => '強い';

  @override
  String get appTagline => '時間記録付きの小さなアウトライナー';

  @override
  String get appAboutDescription =>
      '考え、タスク、プロジェクトを整理するためのクロスプラットフォームのデスクトップ用アウトライナーです。時間記録機能を内蔵しています。';

  @override
  String get appBuiltWithFlutter => 'Flutter で開発';

  @override
  String get appCheckForUpdateTitle => 'アップデートを確認';

  @override
  String appCouldNotOpen(String url) {
    return '$url を開けませんでした';
  }

  @override
  String get appOpenReleasePage => 'リリースページを開く';

  @override
  String get appDownloadApk => 'APK をダウンロード';

  @override
  String get appDownloadDiskImage => 'ディスクイメージをダウンロード';

  @override
  String get appCheckingForUpdate => '新しいバージョンを確認しています...';

  @override
  String get appUpdateCheckFailed => 'アップデートの確認に失敗しました';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version は最新バージョンです。';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version が利用可能です（現在のバージョンは $installed）。';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return '$appName $version をダウンロードしています...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version をダウンロードし、検証しました。インストールすると $appName を終了してプログラムファイルを置き換え、再起動します。データベースには影響しません。';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version をインストールしました。使用するには再起動してください。';
  }

  @override
  String get appLater => '後で';

  @override
  String get appInstall => 'インストール';

  @override
  String get appInstallAndRestart => 'インストールして再起動';

  @override
  String get appRestartNow => '今すぐ再起動';

  @override
  String get appUpdGithubTimeout => 'GitHub から時間内に応答がありませんでした';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'GitHub に接続できません: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return '最新リリースの取得で GitHub が $status を返しました';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return '予期しないリリースデータです: $error';
  }

  @override
  String get appUpdUnexpectedData => '予期しないリリースデータです';

  @override
  String get appUpdNoInPlace => 'このプラットフォームではその場での更新はできません';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'リリース $version には Windows インストーラーがありません';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'リリース $version には Windows 用 ZIP がありません';
  }

  @override
  String appUpdCannotWrite(String path) {
    return '$path に書き込めません。新しいバージョンを手動でダウンロードしてください';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName に $path が含まれていません';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'ダウンロードしたファイルは有効な ZIP ではありません: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'ZIP に安全でないパスが含まれています: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'ダウンロードしたファイルを展開できません: $error';
  }

  @override
  String get appUpdNotAppImage => 'AppImage から実行されていません';

  @override
  String appUpdNoAppImage(String version) {
    return 'リリース $version には Linux 用 AppImage がありません';
  }

  @override
  String appUpdCannotChmod(String error) {
    return '新しい AppImage を実行可能にできません: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return '$path を置き換えられません: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'ダウンロードに失敗しました: サーバーが $status を返しました';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'ダウンロードしたファイルを保存できません: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'ダウンロードが中断されました: $error';
  }

  @override
  String get appUpdChecksumMismatch => 'ダウンロードしたファイルが公開されているチェックサムと一致しません';

  @override
  String appUpdNoChecksums(String version) {
    return 'リリース $version にはチェックサムが公開されていません。手動でダウンロードしてください';
  }

  @override
  String get appUpdChecksumTimeout => 'チェックサムのダウンロードがタイムアウトしました';

  @override
  String appUpdChecksumFailed(String error) {
    return 'チェックサムのダウンロードに失敗しました: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'チェックサムのダウンロードに失敗しました: サーバーが $status を返しました';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName は $checksumsFile に記載されていません';
  }

  @override
  String get appLogCopied => 'アプリログをクリップボードにコピーしました';

  @override
  String get appLogTitle => 'アプリログ';

  @override
  String get appLogSaveDialogTitle => 'アプリログを保存';

  @override
  String appSavedTo(String path) {
    return '$path に保存しました';
  }

  @override
  String appSaveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get appShare => '共有';

  @override
  String get appClearLogTooltip => 'ログを消去';

  @override
  String get appClearLogButton => 'ログを消去';

  @override
  String get appSaveEllipsis => '保存...';

  @override
  String get appSearchHint => '検索';

  @override
  String get appLogLevelAll => 'すべて';

  @override
  String get appLogLevelWarnings => '警告とエラー';

  @override
  String get appLogLevelErrors => 'エラー';

  @override
  String get appLogEmpty => 'まだ何も記録されていません。';

  @override
  String get appLogNoMatch => '一致する行はありません。';

  @override
  String get appHistoryTitle => '変更履歴';

  @override
  String get appHistoryFilter => 'フィルター: ';

  @override
  String appHistoryAll(int count) {
    return 'すべて（$count）';
  }

  @override
  String appHistoryTasks(int count) {
    return 'タスク（$count）';
  }

  @override
  String appHistoryFiles(int count) {
    return 'ファイル（$count）';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'タイムライン（$count）';
  }

  @override
  String appHistoryError(String error) {
    return 'エラー: $error';
  }

  @override
  String get appHistoryEmpty => '履歴エントリが見つかりません';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のフィールドを変更',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return 'グループ化されたエントリ $total 件中 $shown 件を表示（フィールド変更は合計 $changes 件）';
  }

  @override
  String get appHistoryOld => '旧:';

  @override
  String get appHistoryNew => '新:';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveAs => '名前を付けて保存...';

  @override
  String get commonDelete => '削除';

  @override
  String get commonRename => '名前を変更';

  @override
  String get commonRemove => '削除';

  @override
  String get commonAdd => '追加';

  @override
  String get commonOpen => '開く';

  @override
  String get commonCopy => 'コピー';

  @override
  String get commonApply => '適用';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonYes => 'はい';

  @override
  String get commonNo => 'いいえ';

  @override
  String get commonBrowse => '参照...';

  @override
  String get commonError => 'エラー';

  @override
  String get commonShow => '表示';

  @override
  String get commonHide => '隠す';

  @override
  String get commonClear => '消去';

  @override
  String get commonRefresh => '更新';

  @override
  String get commonTest => 'テスト';

  @override
  String get commonDownload => 'ダウンロード';

  @override
  String get commonNone => 'なし';

  @override
  String get commonSystemDefault => 'システムのデフォルト';

  @override
  String get commonUntitled => '無題';

  @override
  String get languageSystem => 'システムのデフォルト';

  @override
  String get editorImageNotAvailable => '画像を表示できません';

  @override
  String get editorImageResize => 'サイズを変更...';

  @override
  String get editorImageReplace => '画像を置き換える...';

  @override
  String get editorImageSaveAs => '画像を別名で保存...';

  @override
  String get editorImageRemoveFromText => 'テキストから削除';

  @override
  String get editorImageRemoveFromTextHint => 'ファイルは添付ファイルに残ります';

  @override
  String get editorImageDelete => '画像を削除';

  @override
  String get editorImageDeleteHint => '添付ファイルも削除します';

  @override
  String get editorImageKeptInOtherTask =>
      '画像をテキストから削除しました。ファイルは別のタスクのものなので、そちらに残してあります。';

  @override
  String get editorResizeImageTitle => '画像のサイズを変更';

  @override
  String get editorResizeWidth => '幅';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$natural px の $percent%';
  }

  @override
  String get editorResizeOriginalSize => '元のサイズ';

  @override
  String get editorInsertImage => '画像を挿入';

  @override
  String get editorReplaceImageDialogTitle => '画像を置き換える';

  @override
  String get editorSaveImageDialogTitle => '画像を保存';

  @override
  String editorSavedFile(String name) {
    return '保存しました: $name';
  }

  @override
  String get editorAttachFileTooltipCompact => 'ファイルを添付\n（長押しで添付ファイルを表示）';

  @override
  String get editorAttachFileTooltip => 'ファイルを添付\n（長押しで添付ファイルの表示/非表示）';

  @override
  String get editorStopRecording => '録音を停止';

  @override
  String get editorRecordVoiceMemo => 'ボイスメモを録音';

  @override
  String get editorRecordVoiceMemoTooltip => 'ボイスメモを録音\n（長押しで文字起こしせずに録音）';

  @override
  String editorAttachedOne(String name) {
    return '$name を添付しました';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のファイルを添付しました',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'フォント';

  @override
  String get editorFontSize => 'フォントサイズ';

  @override
  String get editorSizeLabel => 'サイズ';

  @override
  String get editorSizeSmall => '小';

  @override
  String get editorSizeLarge => '大';

  @override
  String get editorSizeHuge => '特大';

  @override
  String get editorStartTyping => '入力を開始...';

  @override
  String get editorLinkedTaskGone => 'リンク先のタスクはもう存在しません。';

  @override
  String get editorRemoveFormatting => '書式を解除';

  @override
  String editorFormatAsTable(String separator) {
    return '表として整形（$separator）';
  }

  @override
  String get editorWordWrapOff => '折り返しをオフにする';

  @override
  String get editorWordWrapOn => '折り返しをオンにする';

  @override
  String editorErrorMessage(String error) {
    return 'エラー: $error';
  }

  @override
  String get editorTaskNotFound => 'タスクが見つかりません';

  @override
  String get editorSelectTask => '編集するタスクを選択してください';

  @override
  String editorSaveFailed(String error) {
    return 'タスクを保存できませんでした: $error';
  }

  @override
  String get editorChangesMerged => '編集中にこのノートが別の場所で変更されました。両方の変更を統合しました。';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return '編集中にこのノートが別の場所で変更されました。あなたのテキストは保存され、もう一方の版は「$copyTitle」として残してあります。';
  }

  @override
  String get treeNewTask => '新規タスク (Ctrl+N)';

  @override
  String get treeNewChildTask => '新規子タスク (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'タスクを削除';

  @override
  String get treeExpandAll => 'すべて展開';

  @override
  String get treeCollapseAll => 'すべて折りたたむ';

  @override
  String get treeNoTasks => 'タスクはまだありません';

  @override
  String get treeCreateFirstTask => '最初のタスクを作成';

  @override
  String get treeTrackedHere => 'このタスクの時間を記録中です';

  @override
  String get treeTrackedInside => 'この中のタスクの時間を記録中です';

  @override
  String get treeHiddenFromAgents => 'AI エージェントから非表示（配下のすべてを含む）';

  @override
  String get treeMoveUp => '上へ移動';

  @override
  String get treeMoveDown => '下へ移動';

  @override
  String get treeMoveToParentLevel => '親の階層へ移動';

  @override
  String get treeMoveUnderPrevious => '前のタスクの下へ移動';

  @override
  String get treeAddChildTask => '子タスクを追加';

  @override
  String get treeStartTracking => '記録を開始';

  @override
  String get treeStopTracking => '記録を停止';

  @override
  String get treeTimeline => 'タイムライン...';

  @override
  String get searchHint => 'タスクを検索...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の結果',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => '一致なし';

  @override
  String get searchUntitled => '（無題）';

  @override
  String get attachImageNotAvailable => '画像を表示できません';

  @override
  String get attachTryAgain => '再試行';

  @override
  String get attachPlay => '再生';

  @override
  String get attachPause => '一時停止';

  @override
  String attachLoadFailed(String error) {
    return '添付ファイルを読み込めませんでした: $error';
  }

  @override
  String get attachNone => '添付ファイルはありません';

  @override
  String get attachAddFile => 'ファイルを追加';

  @override
  String get attachNotDownloaded => 'この添付ファイルはまだダウンロードされていません — 同期して取得してください';

  @override
  String get attachContentLoadFailed => '添付ファイルの内容を読み込めませんでした';

  @override
  String get attachDownloading => '添付ファイルをダウンロードしています…';

  @override
  String get attachExportDialogTitle => '添付ファイルを書き出す';

  @override
  String attachExported(String name) {
    return '書き出しました: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return '$name を開けるアプリがありません';
  }

  @override
  String get attachImageInNoteTitle => '画像はノートに表示されています';

  @override
  String attachImageInNoteBody(String name) {
    return '「$name」はこのタスクのノートに表示されているため、ここからは削除できません。\n\nノート内の画像をクリックし、「画像を削除」を選ぶと画像とファイルの両方が削除されます。「テキストから削除」を選ぶとファイルが残るので、その後ここで削除できます。';
  }

  @override
  String get attachDeleteTitle => '添付ファイルを削除しますか？';

  @override
  String attachDeleteConfirm(String name) {
    return '「$name」を削除してもよろしいですか？';
  }

  @override
  String get attachRenameTitle => '添付ファイルの名前を変更';

  @override
  String get attachFileName => 'ファイル名';

  @override
  String get attachShowPreview => 'プレビューを表示';

  @override
  String get attachHidePreview => 'プレビューを隠す';

  @override
  String get attachShare => '共有';

  @override
  String get attachExport => '書き出す';

  @override
  String get attachTranscribe => '文字起こし';

  @override
  String get attachCannotPlay => 'このファイルは再生できません';

  @override
  String get attachPlaybackUnavailable => '再生を利用できません';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分',
    );
    return '$_temp0の上限に達したため録音を停止しました。メモは保存されています。';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分',
    );
    return '$_temp0の上限に達しました';
  }

  @override
  String get voiceDismiss => '閉じる';

  @override
  String get voiceOpeningMic => 'マイクを準備しています…';

  @override
  String get voiceSaving => '保存しています…';

  @override
  String get voiceSavedTranscribing => '保存しました。文字起こし中…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return '保存しました。文字起こし中… $percent%';
  }

  @override
  String get voiceDiscard => '破棄';

  @override
  String get voiceStop => '停止';

  @override
  String get voiceChooseModelFirst => '先に環境設定で文字起こしモデルを選択してください';

  @override
  String voiceModelNotDownloaded(String model) {
    return '$model モデルはまだダウンロードされていません — 環境設定を確認してください';
  }

  @override
  String get voiceTranscribing => '文字起こし中…';

  @override
  String voiceTranscribingPercent(int percent) {
    return '文字起こし中… $percent%';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return '文字起こしできませんでした: $error';
  }

  @override
  String get voiceNoSpeech => 'このメモには音声が見つかりませんでした';

  @override
  String get voiceTranscribedNoteNotOpen => '文字起こしは完了しましたが、対象のノートが開かれていません';

  @override
  String get voiceDiscardedDatabaseSwitched => '別のデータベースが開かれたため、録音を破棄しました。';

  @override
  String get voiceMicPermissionRefused => 'マイクへのアクセスが拒否されました';

  @override
  String voiceStartFailed(String error) {
    return '録音を開始できませんでした: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return '録音に失敗しました: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return '録音を完了できませんでした: $error';
  }

  @override
  String get voiceNoDatabase => 'データベースが開かれていないため、メモを保存できませんでした';

  @override
  String voiceSaveFailed(String error) {
    return 'メモを保存できませんでした: $error';
  }

  @override
  String get timeTimelineTitle => 'タイムライン';

  @override
  String get timeStatsToday => '今日:';

  @override
  String get timeStatsThisMonth => '今月:';

  @override
  String timeRecordingSince(String time) {
    return '$time から記録中';
  }

  @override
  String get timeEndBeforeStart => '終了時刻は開始時刻より後にしてください';

  @override
  String get timeOverlaps => '既存の区間と重なっています';

  @override
  String get timeAddIntervalTitle => '時間区間を追加';

  @override
  String get timeEditIntervalTitle => '時間区間を編集';

  @override
  String get timeStartTime => '開始時刻:';

  @override
  String get timeFinishTime => '終了時刻:';

  @override
  String get timeDurationLabel => '長さ:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 時間',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 時間',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String timeShortHours(int hours) {
    return '$hours時間';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get timeAddEllipsis => '追加...';

  @override
  String get timeNoRecords => '時間記録はありません';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day（$weekday）';
  }

  @override
  String get timeNow => '現在';

  @override
  String get timeRemoveIntervalTitle => '区間を削除しますか？';

  @override
  String get timeRemoveIntervalConfirm => 'この時間区間を削除してもよろしいですか？';

  @override
  String get timeNotTracking => '記録していません';

  @override
  String get timeStopTracking => '記録を停止';

  @override
  String get timeStartTracking => '記録を開始';

  @override
  String get timeBackToFullWindow => '通常のウインドウに戻る';

  @override
  String get timeReportTitle => '時間レポート';

  @override
  String get timeReportSaveTitle => '時間レポートを保存';

  @override
  String timeReportGenerateFailed(String error) {
    return 'レポートを生成できませんでした: $error';
  }

  @override
  String get timeReportCopied => 'レポートをクリップボードにコピーしました';

  @override
  String timeReportSavedTo(String path) {
    return '$path に保存しました';
  }

  @override
  String timeReportSaveFailed(String error) {
    return '保存に失敗しました: $error';
  }

  @override
  String get timeReportTasks => 'タスク';

  @override
  String get timeReportNoTasks => 'タスクがありません。';

  @override
  String get timeReportClearSelection => '選択を解除';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件選択',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => '子孫タスクを含める';

  @override
  String get timeReportIncludeDescendantsHint => '選択した各ノードの子タスクの時間もレポートに含めます。';

  @override
  String get timeReportDateRange => '期間';

  @override
  String timeReportFrom(String date) {
    return '開始: $date';
  }

  @override
  String timeReportTo(String date) {
    return '終了: $date';
  }

  @override
  String get timeReportFormat => '形式';

  @override
  String get timeReportFormatTree => 'ツリー（合計のみ）';

  @override
  String get timeReportFormatTreeWithDays => 'ツリー（日別の内訳付き）';

  @override
  String get timeReportFormatFlat => '区間の一覧';

  @override
  String get timeReportShowEmpty => '記録のないタスクも表示';

  @override
  String get timeReportUntitled => '（無題）';

  @override
  String get timeReportSelectTasks => 'レポートを生成するには、タスクを 1 つ以上選択してください。';

  @override
  String get timeReportNoRecordsInPeriod => '選択した期間に時間記録はありません。';

  @override
  String get timeReportTextPeriod => '期間:';

  @override
  String get timeReportTextTotal => '合計:';

  @override
  String get timeReportTextGenerated => '作成日時:';

  @override
  String get timeReportTextClipped => '期間の境界をまたぐ記録は期間内に切り詰められています。';

  @override
  String timeReportTextSelf(String duration) {
    return '自身: $duration';
  }

  @override
  String get timeReportTextOngoing => '記録中';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の記録',
    );
    return '合計: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => '再生成';

  @override
  String get timeReportShare => '共有…';

  @override
  String get timeReportSave => '保存…';

  @override
  String get timeReportPresetToday => '今日';

  @override
  String get timeReportPresetThisWeek => '今週';

  @override
  String get timeReportPresetThisMonth => '今月';

  @override
  String get timeReportPresetLastMonth => '先月';

  @override
  String get timeReportPresetThisYear => '今年';

  @override
  String get prefsTitle => '環境設定';

  @override
  String get prefsTabAppearance => '外観';

  @override
  String get prefsTabBehavior => '動作';

  @override
  String get prefsTabVoiceMemos => 'ボイスメモ';

  @override
  String get prefsTabSync => '同期';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => '言語';

  @override
  String get prefsInterfaceLanguage => '表示言語';

  @override
  String get prefsLanguageHint => '英語以外の翻訳は機械翻訳です。修正のご提案を歓迎します。';

  @override
  String get prefsGroupTheme => 'テーマ';

  @override
  String get prefsThemeMode => 'モード';

  @override
  String get prefsThemeSystem => 'システム';

  @override
  String get prefsThemeLight => 'ライト';

  @override
  String get prefsThemeDark => 'ダーク';

  @override
  String get prefsGroupStyle => 'スタイル';

  @override
  String get prefsGroupColour => 'カラー';

  @override
  String get prefsLook => '外観';

  @override
  String get prefsLookHint =>
      'クラシック: 角の丸みなし、枠付きのフラットなボタン、波紋効果なし、スクロールバーを常に表示、アクセントカラーのタイトルバーとその下のメニュー。';

  @override
  String get prefsUiStyleModern => 'モダン';

  @override
  String get prefsUiStyleClassic => 'クラシック';

  @override
  String get prefsAccentColour => 'アクセントカラー';

  @override
  String get prefsAccentTeal => 'ティール';

  @override
  String get prefsAccentBlue => 'ブルー';

  @override
  String get prefsAccentIndigo => 'インディゴ';

  @override
  String get prefsAccentPurple => 'パープル';

  @override
  String get prefsAccentPink => 'ピンク';

  @override
  String get prefsAccentRed => 'レッド';

  @override
  String get prefsAccentOrange => 'オレンジ';

  @override
  String get prefsAccentAmber => 'アンバー';

  @override
  String get prefsAccentGreen => 'グリーン';

  @override
  String get prefsAccentGraphite => 'グラファイト';

  @override
  String get prefsGroupWindow => 'ウインドウ';

  @override
  String get prefsSystemTitleBar => 'システムのタイトルバーを使用';

  @override
  String get prefsSystemTitleBarHint =>
      'ウインドウの枠、タイトル、ボタンをデスクトップの標準の表示にし、その下にメニューバーを置きます。';

  @override
  String get prefsGroupEditorFont => 'エディターのフォント（ノートの本文）';

  @override
  String get prefsGroupTreeFont => 'ツリーのフォント（アウトライン）';

  @override
  String get prefsGroupInterfaceFont => 'インターフェイスのフォント（メニューとダイアログ）';

  @override
  String get prefsFontFamily => 'フォント';

  @override
  String get prefsFontCustom => 'カスタム…';

  @override
  String get prefsCustomName => 'カスタム名';

  @override
  String prefsCustomFamilyExample(String font) {
    return '例: $font';
  }

  @override
  String get prefsFontSize => 'サイズ';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'スタイル';

  @override
  String get prefsBold => '太字';

  @override
  String get prefsItalic => '斜体';

  @override
  String get prefsPreview => 'プレビュー';

  @override
  String get prefsPreviewText =>
      'いろはにほへと ちりぬるを わかよたれそ つねならむ。The quick brown fox jumps over the lazy dog.';

  @override
  String get prefsScale => '倍率';

  @override
  String get prefsFontSansSerif => 'ゴシック体（Sans Serif）';

  @override
  String get prefsFontSerif => '明朝体（Serif）';

  @override
  String get prefsFontMonospace => '等幅';

  @override
  String get prefsGroupTimeTracking => '時間記録';

  @override
  String get prefsEnableTimeTracking => '時間記録を有効にする';

  @override
  String get prefsEnableTimeTrackingHint =>
      '記録の開始/停止、タイムライン、時間レポート。オフにすると非表示になりますが、記録した時間は保持されます';

  @override
  String get prefsShowSeconds => '秒を表示';

  @override
  String get prefsShowSecondsHint => '時間の長さに秒を表示します';

  @override
  String get prefsMiniTracker => '記録中はミニウインドウを表示';

  @override
  String get prefsMiniTrackerHint =>
      '時計が動いている間にウインドウを最小化すると、代わりに常に最前面に表示される小さな時計になります';

  @override
  String get prefsGroupSaving => '保存';

  @override
  String get prefsAutoSaveEvery => '自動保存の間隔';

  @override
  String get prefsUnitSec => '秒';

  @override
  String get prefsGroupEditor => 'エディター';

  @override
  String get prefsTabWidth => 'タブ幅';

  @override
  String get prefsUnitSpaces => 'スペース';

  @override
  String get prefsTabAsSpaces => 'タブをスペースとして挿入';

  @override
  String get prefsTabAsSpacesHint => 'Tab キーを押すとタブの代わりにスペースを挿入します';

  @override
  String get prefsWordWrap => '折り返し';

  @override
  String get prefsWordWrapHint =>
      'オフ: 長い行は折り返されず、ノートを横にスクロールします（Shift + ホイール）。エディターのコンテキストメニューとステータスバーからも切り替えられます';

  @override
  String get prefsMonospaceOnly => '等幅フォントのみ';

  @override
  String get prefsMonospaceOnlyHint =>
      'ツールバーのフォントメニューに等幅フォントだけを表示し、桁をそろえたテキストが崩れないようにします';

  @override
  String get prefsFloatingButtons => 'フローティングボタン';

  @override
  String get prefsFloatingButtonsHint =>
      'ノートの上に「ファイルを添付」と「ボイスメモを録音」を表示します。ツールバーのボタンはどちらの場合も残ります';

  @override
  String get prefsPaste => 'ペースト';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V は常にプレーンテキストとしてペーストします';

  @override
  String get prefsPasteKeep => '書式を保持';

  @override
  String get prefsPasteStrip => '色とフォントを除去';

  @override
  String get prefsPastePlain => 'プレーンテキストのみ';

  @override
  String get prefsTableColumns => '表の列';

  @override
  String get prefsTableColumnsHint =>
      '「表として整形」（エディターのコンテキストメニュー）で列を区切る文字。URL や引用符で囲まれたテキストの中では区切りません';

  @override
  String get prefsSeparatorColon => 'コロン  ( : )';

  @override
  String get prefsSeparatorEquals => '等号  ( = )';

  @override
  String get prefsSeparatorPipe => '縦棒  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'セミコロン  ( ; )';

  @override
  String get prefsSeparatorComma => 'カンマ  ( , )';

  @override
  String get prefsSeparatorTab => 'タブ';

  @override
  String get prefsGroupToolbarButtons => 'ツールバーのボタン';

  @override
  String get prefsToolbarButtonsHint => 'チェックを外したボタンはエディターのツールバーから取り除かれます。';

  @override
  String get prefsToolbarUndoRedo => '取り消す / やり直す';

  @override
  String get prefsToolbarFont => 'フォント';

  @override
  String get prefsToolbarSize => 'サイズ';

  @override
  String get prefsToolbarBold => '太字';

  @override
  String get prefsToolbarItalic => '斜体';

  @override
  String get prefsToolbarUnderline => '下線';

  @override
  String get prefsToolbarStrikeThrough => '取り消し線';

  @override
  String get prefsToolbarInlineCode => 'コード';

  @override
  String get prefsToolbarTextColor => '文字色';

  @override
  String get prefsToolbarHighlightColor => 'ハイライト色';

  @override
  String get prefsToolbarClearFormat => '書式を解除';

  @override
  String get prefsToolbarHeadings => '見出し';

  @override
  String get prefsToolbarNumberedList => '番号付きリスト';

  @override
  String get prefsToolbarBulletedList => '箇条書き';

  @override
  String get prefsToolbarChecklist => 'チェックリスト';

  @override
  String get prefsToolbarCodeBlock => 'コードブロック';

  @override
  String get prefsToolbarQuote => '引用';

  @override
  String get prefsToolbarIndent => 'インデント';

  @override
  String get prefsToolbarLink => 'リンク';

  @override
  String get prefsToolbarInsertImage => '画像を挿入';

  @override
  String get prefsToolbarVoiceMemo => 'ボイスメモ';

  @override
  String get prefsGroupSecurity => 'セキュリティ';

  @override
  String get prefsRememberPassword => 'パスワードを記憶';

  @override
  String get prefsRememberPasswordHint => 'データベースのパスワードをシステムのキーチェーンに保存します';

  @override
  String get prefsBiometricUnlock => '生体認証でロック解除';

  @override
  String get prefsBiometricUnavailableHint =>
      '利用できません — 先に Android の設定で指紋認証または画面ロックを設定してください';

  @override
  String get prefsBiometricHint => '記憶したパスワードを使う前に、指紋、顔、または画面ロックで確認します';

  @override
  String get prefsBlockScreenshots => 'スクリーンショットを禁止';

  @override
  String get prefsBlockScreenshotsHint =>
      'スクリーンショット、画面録画、最近使ったアプリの一覧でアプリの内容を隠します';

  @override
  String get prefsGroupStartup => '起動';

  @override
  String get prefsSingleInstance => '単一インスタンス';

  @override
  String get prefsSingleInstanceHint =>
      'ウインドウを 1 つだけにし、新たに起動すると既存のウインドウを前面に出します。次回の起動から有効になります。';

  @override
  String get prefsVoiceGroupDevices => 'デバイス';

  @override
  String get prefsVoiceMicrophone => 'マイク';

  @override
  String get prefsVoiceMicrophoneHint => 'ボイスメモと下のチェックに使用します。';

  @override
  String get prefsVoiceSpeaker => 'スピーカー';

  @override
  String get prefsVoiceSpeakerHint =>
      'ボイスメモに適用されます。その他の音声添付ファイルはシステムのデフォルトで再生されます。';

  @override
  String get prefsVoiceDevicesLooking => '検索しています…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'オーディオデバイスを取得できませんでした: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => '利用できません';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name（デフォルト）';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name（未接続）';
  }

  @override
  String get prefsVoiceGroupTranscription => '文字起こし';

  @override
  String get prefsVoiceModel => 'モデル';

  @override
  String get prefsVoiceModelHintNone => 'メモは音声としてのみ録音・保存されます。';

  @override
  String get prefsVoiceModelHintLocal => 'このデバイス上で動作します。どこにも送信されません。';

  @override
  String get prefsVoiceModelOff => 'オフ';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · 推奨';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => '録音後に文字起こし';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'メモはまず保存され、保存された音声から文字起こしされます。オフにすると文字起こしせずに保存します。後から添付ファイルメニューの「文字起こし」で実行することもできます。';

  @override
  String get prefsVoiceLanguage => '言語';

  @override
  String get prefsVoiceLanguageAuto => '自動検出';

  @override
  String get prefsVoiceFooter =>
      '録音はモデルがなくても使えます。メモは常に音声として保存され、他の添付ファイルと同じように再生できます。モデルはテキストを追加するだけです。';

  @override
  String get prefsVoiceGroupCheck => 'チェック';

  @override
  String get prefsVoiceCheckIntro =>
      '上のデバイスとモデルを使って数秒間録音し、再生して文字起こしします。何も保存されません。';

  @override
  String get prefsVoiceStop => '停止';

  @override
  String get prefsVoiceTestAgain => 'もう一度テスト';

  @override
  String get prefsVoiceCheckRecording => '録音中 — 何か一文を話してから「停止」を押してください。';

  @override
  String get prefsVoiceCheckPlaying => '再生しています…';

  @override
  String get prefsVoiceCheckTranscribing => '文字起こし中…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return '文字起こし中… $percent%';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return '$duration 録音しました。';
  }

  @override
  String get prefsVoiceCheckFailed => 'チェックが完了しませんでした。';

  @override
  String get prefsVoiceDownloading => 'ダウンロードしています…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$size の $percent%';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model はダウンロード済みで、使用できます。';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return '未ダウンロード — HuggingFace から $size。';
  }

  @override
  String get prefsCheckBusy => 'ボイスメモを録音中です。先に完了させてください。';

  @override
  String get prefsCheckPermissionRefused => 'マイクへのアクセスが拒否されました。';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'マイクを開けませんでした: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return '録音に失敗しました: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return '録音を完了できませんでした: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      '何も録音されませんでした。もう少し長く録音するか、別のマイクを選択してください。';

  @override
  String get prefsCheckMalformed => '録音データが不正で、再生できませんでした。';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return '再生に失敗しました: $error';
  }

  @override
  String get prefsCheckNoModel => '録音と再生は正常です。モデルが選択されていないため、文字起こしは行いません。';

  @override
  String prefsCheckModelMissing(String model) {
    return '録音と再生は正常です。$model がまだダウンロードされていないため、文字起こしは行いませんでした。';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return '文字起こしに失敗しました: $error';
  }

  @override
  String get prefsCheckSilence =>
      'マイクから無音しか届きませんでした。レベルメーターが一度も動いていません。正しいデバイスが選択されていること、アプリにその使用が許可されていることを確認してください。';

  @override
  String get prefsCheckNoSpeech =>
      '録音と再生は正常ですが、whisper は音声を検出できませんでした。マイクに近づいて話すか、別の言語を試してください。';

  @override
  String get prefsCheckQuiet => 'レベルメーターが一度も動かなかったため、入力が非常に小さいようです。';

  @override
  String get prefsDownloadCancelled => 'ダウンロードをキャンセルしました。';

  @override
  String prefsDownloadFailed(String error) {
    return 'ダウンロードに失敗しました: $error';
  }

  @override
  String get prefsUntitled => '（無題）';

  @override
  String get prefsMcpTokenSessionOnly =>
      'システムのキーチェーンに保存できなかったため、このセッションでのみ保存されています。キーリングがロックされている場合は、ロックを解除して「再生成」を押してください。';

  @override
  String get prefsMcpRegenerateTitle => 'トークンを再生成しますか？';

  @override
  String get prefsMcpRegenerateBody =>
      '現在のトークンで設定されたエージェントは、新しいトークンを設定に貼り付けるまで動作しなくなります。';

  @override
  String get prefsMcpRegenerate => '再生成';

  @override
  String get prefsMcpGroupAccess => 'エージェントのアクセス';

  @override
  String get prefsMcpEnable => 'MCP サーバーを有効にする';

  @override
  String get prefsMcpEnableHint =>
      'ローカルの AI コーディングエージェントが 127.0.0.1 経由でこのアウトラインを読めるようにします。デフォルトはオフです。';

  @override
  String get prefsMcpReadOnly => '読み取り専用';

  @override
  String get prefsMcpReadOnlyHint => 'エージェントはタスクを検索・閲覧できますが、作成、変更、移動、削除はできません。';

  @override
  String get prefsMcpGroupEndpoint => 'エンドポイント';

  @override
  String get prefsMcpPort => 'ポート';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'URL をコピー';

  @override
  String get prefsMcpToken => 'トークン';

  @override
  String get prefsMcpTokenHint =>
      'あなたの権限でプログラムを実行できる人は誰でもこのトークンを使えます。パスワードと同様に扱ってください。';

  @override
  String get prefsMcpNoTokenYet => 'トークンはまだありません — サーバーを有効にすると作成されます';

  @override
  String get prefsMcpShowToken => 'トークンを表示';

  @override
  String get prefsMcpHideToken => 'トークンを隠す';

  @override
  String get prefsMcpCopyToken => 'トークンをコピー';

  @override
  String get prefsMcpCopied => 'コピーしました。';

  @override
  String get prefsMcpGroupExcluded => '除外するブランチ';

  @override
  String get prefsMcpExcludedIntro => 'MCP サーバーから隠すタスク（配下のすべてを含む）。';

  @override
  String get prefsMcpLoading => '読み込んでいます…';

  @override
  String get prefsMcpOutlineReadError => 'アウトラインを読み込めませんでした。';

  @override
  String get prefsMcpChoose => '選択…';

  @override
  String get prefsMcpNothingExcluded => '何も除外されていません — エージェントはアウトライン全体を参照できます。';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ほか $count 件',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return '$url で待ち受け中';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'ポート $port は使用できません。別のポートを選択してください。';
  }

  @override
  String get prefsMcpNoAccessToken => 'アクセストークンがありません。「再生成」を押して作成してください。';

  @override
  String get prefsMcpWaitingDatabase => 'データベースが開かれるのを待っています。';

  @override
  String get prefsMcpNotRunning => '停止中。';

  @override
  String prefsMcpLastRequest(String time) {
    return '最後のリクエスト $time';
  }

  @override
  String get prefsMcpNoRequests => 'リクエストはまだありません';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件を拒否（トークンが誤っているか未指定）',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<先にサーバーを有効にしてください>';

  @override
  String get prefsMcpGroupSetup => 'エージェントの設定';

  @override
  String get prefsMcpClient => 'クライアント';

  @override
  String get prefsMcpStdioBridge => 'stdio にしか対応していないエージェントは、次のコマンドで接続できます:';

  @override
  String get prefsMcpTargetTerminal => 'ターミナルで次を実行してください:';

  @override
  String prefsMcpTargetFile(String file) {
    return '$file に追加してください:';
  }

  @override
  String get prefsMcpNoteClaudeCode => 'ユーザー単位の設定なので、すべてのプロジェクトでアウトラインを利用できます。';

  @override
  String get prefsMcpNoteCodex =>
      'トークンをファイルに書かないようにするには、http_headers を bearer_token_env_var = \"NOO_MCP_TOKEN\" に置き換え、シェルでその変数を設定してください。';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false は必須です。これがないと OpenCode はこのサーバーの 401 を OAuth 登録の開始と解釈し、完了できなくなります。';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'チェックしたタスクは、配下のすべてとともに MCP サーバーから隠されます。エージェントはそれを読むことも変更することもできず、それを含むものを削除することもできません。';

  @override
  String get prefsMcpNoDatabase => 'データベースが開かれていません。';

  @override
  String get prefsMcpNoTasks => 'このアウトラインにはまだタスクがありません。';

  @override
  String get prefsMcpCollapse => '折りたたむ';

  @override
  String get prefsMcpExpand => '展開';

  @override
  String get prefsMcpHiddenWithParent => '親とともに非表示';

  @override
  String get syncGroupSynchronization => '同期';

  @override
  String get syncEnable => '同期を有効にする';

  @override
  String get syncEnableHint => 'このデータベースをサーバーと同期します';

  @override
  String get syncGroupIdentity => 'ID';

  @override
  String get syncNeedsUserName =>
      '同期を始めるにはユーザー名を入力してください。ユーザー名がないと、サーバーの有無にかかわらず何も同期されません。';

  @override
  String get syncUserName => 'ユーザー名';

  @override
  String get syncUserNameHint =>
      'すべてのデバイスで同じにします。データベースのパスワードと組み合わせて暗号鍵を導出するため、両方が一致するデバイス同士でのみ同期されます。';

  @override
  String get syncDeviceName => 'デバイス名';

  @override
  String get syncDeviceNameHint => '近くのデバイスに表示されるこのデバイスの名前';

  @override
  String get syncGroupServer => '同期サーバー（オプション）';

  @override
  String get syncServerIntro =>
      '空欄にすると、同じネットワーク上の近くのデバイスとだけ同期します。サーバーを使うと、離れた場所にあるデバイス同士でも同期できます。サーバーには読み取れない暗号化データのみが保存されます。';

  @override
  String get syncServerUrl => 'サーバー URL';

  @override
  String get syncServerPassword => 'パスワード';

  @override
  String get syncServerPasswordHint =>
      'サーバー上のアカウントのパスワードです。データベースのパスワードとは別のもので、暗号鍵には使われません。';

  @override
  String get syncTestConnection => '接続をテスト';

  @override
  String get syncRegister => '登録';

  @override
  String get syncGroupSchedule => 'スケジュール';

  @override
  String get syncScheduleNeedsServer =>
      '起動時と終了時の同期にはサーバーが必要です。同じネットワーク上のデバイスは、ツール → P2P 同期... から指示したときに同期します。';

  @override
  String get syncAutosyncOnStart => '起動時に自動同期';

  @override
  String get syncAutosyncOnStartHint => 'アプリがデータベースを開いたときに同期します';

  @override
  String get syncCheckOnStart => '起動時に受信する変更を確認';

  @override
  String get syncCheckOnStartHint =>
      '同期はせずに、他のデバイスから変更が届いているかをサーバーに問い合わせ、同期アイコンに表示します。「起動時に自動同期」がオンの場合は不要です';

  @override
  String get syncAskOnExit => '終了時に同期を確認';

  @override
  String get syncAskOnExitHint => 'アプリを閉じる前に、未同期の変更を同期するか確認します';

  @override
  String get syncGroupServerStorage => 'サーバーのストレージ';

  @override
  String get syncGroupPeerToPeer => 'ピアツーピア';

  @override
  String get syncPeerToPeerIntro =>
      '同じネットワーク上にあり、ユーザー名とデータベースのパスワードが同じデバイス同士は、サーバーなしで直接同期できます。それぞれのデバイスでツール → P2P 同期... を開いてください。そのウインドウが開いている間、互いを見つけて同期します。それ以外のときは検出されません。';

  @override
  String get syncStorageNoServer =>
      'この構成ではサーバーに何も保存されません。ピアツーピア同期では、すべてのパケットがデバイス自身に保存されます。';

  @override
  String get syncStorageIntro =>
      'サーバーにはこれまでのすべての暗号化された変更が保存されるため、そのサイズはアウトラインの大きさではなく編集量に応じて増えます。';

  @override
  String get syncStorageReading => '読み込んでいます…';

  @override
  String get syncStoragePressRefresh => '「更新」を押すと現在の使用量を読み込みます。';

  @override
  String get syncStorageEmpty => 'サーバーにはまだ何も保存されていません。';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size（$count パケット）',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'カウンター $first～$last';
  }

  @override
  String syncStorageDeviceCountersSnapshots(
    int snapshots,
    int first,
    int last,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      snapshots,
      locale: localeName,
      other: 'カウンター $first～$last、スナップショット $snapshots 個',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'さらに添付ファイル $count 個（$size）。それぞれ 1 回だけ保存され、参照するすべてのパケットで共有されます。',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このデバイスはそのうち $count 個をローカルに保持しています（$size）。',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'サーバー上のデータを最適化';

  @override
  String get syncResetIdentity => 'デバイス ID をリセット';

  @override
  String get syncNotConfiguredOnDevice => 'このデバイスでは同期が設定されていません。';

  @override
  String syncStorageReadFailed(String error) {
    return 'サーバーのストレージを読み込めませんでした: $error';
  }

  @override
  String get syncResetConfirm =>
      'このデバイスは新しい ID で同期を始め、次回の同期で現在のデータベースの完全なコピーを公開します。他のデバイスはそれを通常どおり統合するので、何も失われません。\n\nこのデバイスの履歴が分岐したと同期で報告された場合に実行してください。通常は、同期済みのデータベースをバックアップから復元したことが原因です。\n\n古い ID は、最適化するまでサーバーのストレージ一覧に表示され続けます。';

  @override
  String get syncReset => 'リセット';

  @override
  String syncResetFailed(String error) {
    return 'デバイス ID をリセットできませんでした: $error';
  }

  @override
  String get syncCompactConfirm =>
      'このデバイスは同期した後、データベース全体のスナップショットを 1 つアップロードします。その後サーバーは、スナップショットに含まれる保存済みの変更をすべて削除し、各デバイスもスナップショットを受け取った時点で同じように削除します。\n\nノート、時間、添付ファイルには影響しません。破棄されるのは、スナップショット以前の個々の編集の記録です。\n\n先に他のデバイスの Noo をアップデートしてください。古いバージョンは、先頭が削除されたストリームを読み込めません。';

  @override
  String get syncCompact => '最適化';

  @override
  String get syncCompactFailed => '最適化に失敗しました。';

  @override
  String get syncCompactNothing => '最適化するものはまだありません。';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'サーバー上で $size を解放しました（$count パケット）',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'スナップショットはアップロードしましたが、このサーバーはまだ最適化に対応していないため、コピーを保持したままです';

  @override
  String get syncCompactRelayNothing =>
      'スナップショットはアップロードしましたが、サーバーには削除できるものが残っていませんでした';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'このデバイスで $size を解放しました（$count パケット）',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay。$local。スナップショット自体のサイズは $size です。';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay。スナップショット自体のサイズは $size です。';
  }

  @override
  String get syncTestSuccess => '成功: サーバーに接続できます';

  @override
  String get syncTestUnreachable => 'エラー: サーバーに接続できません';

  @override
  String syncErrorWith(String error) {
    return 'エラー: $error';
  }

  @override
  String get syncRegisterNeedsCredentials => 'エラー: ユーザー名とパスワードが必要です';

  @override
  String syncRegisterSuccess(String user) {
    return '成功: アカウント「$user」を作成しました。設定を保存しました。';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return '成功: サーバーストレージ無制限のアカウント「$user」を作成しました。設定を保存しました。';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return '成功: サーバーストレージ $size のアカウント「$user」を作成しました。設定を保存しました。';
  }

  @override
  String get syncStagePreparing => '準備';

  @override
  String get syncStageAuthenticating => '認証情報を確認';

  @override
  String get syncStagePushing => '変更を送信';

  @override
  String get syncStageApplying => '変更を適用';

  @override
  String get syncStatePending => '待機中';

  @override
  String get syncStateActive => '処理中…';

  @override
  String get syncStateDone => '完了';

  @override
  String get syncStateSkipped => 'スキップ';

  @override
  String get syncStateFailed => '失敗';

  @override
  String get syncCancelling => 'キャンセルしています…';

  @override
  String get syncSynchronizing => '同期しています…';

  @override
  String get syncCancelled => '同期をキャンセルしました';

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String get syncTitle => '同期';

  @override
  String get syncComplete => '同期が完了しました';

  @override
  String get syncNow => '今すぐ同期';

  @override
  String get syncShowFullLogTooltip => 'ログ全体を表示';

  @override
  String get syncShowFullLog => 'ログ全体を表示';

  @override
  String get syncMoreSeeFullLog => '「ログ全体を表示」を参照';

  @override
  String get syncGroupProgress => '進行状況';

  @override
  String get syncNoRunYet => 'まだ同期は実行されていません。「今すぐ同期」で同期すると、最後の同期の詳細がここに表示されます。';

  @override
  String get syncCancelledNote =>
      '要求に応じて停止しました。それまでに同期した内容はすべて保持され、次回の同期はそこから続行します。';

  @override
  String get syncGroupSummary => '概要';

  @override
  String get syncChangesPushed => '送信した変更';

  @override
  String get syncChangesApplied => '適用した変更';

  @override
  String get syncGroupApplied => '適用 — 他のデバイスから';

  @override
  String get syncGroupPushed => '送信 — このデバイスから';

  @override
  String get syncGroupLwwSkipped => '未適用 — このデバイスに新しい値がありました';

  @override
  String get syncGroupUnreadable => '読み取れませんでした';

  @override
  String get syncLwwTieNote =>
      'タイムスタンプが完全に一致する場合は、両方のデバイスでそのまま保持されるため、2 つは異なったままになります。残したい版のデバイスで、もう一度その項目を編集してください。';

  @override
  String get syncLwwOlderNote =>
      '受信した値はこのデバイスの値より古かったため、書き込まれませんでした。受信した値が優先されるべきだった場合は、両方のデバイスの時計が合っているか確認してください。';

  @override
  String get syncSkewSame => '同じタイムスタンプ';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'ローカルが $seconds 秒進んでいます',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'ローカルが $minutes 分 $seconds 秒進んでいます';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'ローカルが $hours 時間 $minutes 分進んでいます';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'ローカルが $days 日進んでいます',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return '受信 $incoming · ローカル $local（$skew）';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage に失敗  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'これらのパケットは復号できませんでした。このデータベースのパスワードが、パケットを書き込んだデバイスのパスワードと異なることを意味します。同期はこれらを再試行しません。パスワードを一致させてから、もう一方のデバイスで該当する項目を保存し直して再送信してください。';

  @override
  String get syncSkippedUnreadableNote =>
      'これらのパケットは読み取れず、同期はそれらを飛ばして先に進みました。その変更が自動的に届くことはありません。もう一方のデバイスで該当する項目を保存し直して再送信してください。';

  @override
  String get syncP2pNotConfigured =>
      '同期が設定されていません。先に環境設定 → 同期 でユーザー名を設定してください。';

  @override
  String syncP2pStartFailed(String error) {
    return 'ピアツーピア同期を開始できませんでした: $error';
  }

  @override
  String get syncP2pStarting => '開始しています...';

  @override
  String get syncP2pLooking => 'このネットワーク上のデバイスを探しています...';

  @override
  String get syncP2pIntro =>
      'もう一方のデバイスでも P2P 同期... を開いてください。互いを見つけるとすぐに同期します。このウインドウを閉じると検出されなくなります。';

  @override
  String get syncP2pTitle => 'P2P 同期';

  @override
  String get syncP2pSyncAgain => '再同期';

  @override
  String get syncP2pFound => '検出 — 同期待ち';

  @override
  String get syncP2pSyncing => '同期しています...';

  @override
  String get syncP2pUpToDate => '同期済み — すでに最新です';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '同期済み — $count 件の変更を受信',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return '失敗 — $error';
  }

  @override
  String get syncP2pUnknownError => '不明なエラー';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return '$device から受信（$count）';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return '$device へ送信（$count）';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$quota 中 $used を使用（$percent%）';
  }

  @override
  String get syncQuotaSemantics => 'サーバーストレージの使用量';

  @override
  String get syncQuotaFull => '容量不足: 最適化するか添付ファイルを削除するまで、サーバーは新しい変更を受け付けません。';

  @override
  String get syncQuotaNearlyFull => '残り容量がわずかです。通常は最適化でほとんどの領域を解放できます。';

  @override
  String get syncNotConfiguredOpenSettings => '同期が設定されていません。先に同期設定を開いてください。';

  @override
  String get syncNoServerConfigured =>
      '同期サーバーが設定されていません。ローカルでの同期には「P2P 同期...」を使うか、環境設定 → 同期 でサーバーを追加してください。';

  @override
  String get syncAlreadyInProgress => 'すでに同期中です';

  @override
  String get syncAlreadyInProgressSentence => 'すでに同期が進行中です。';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$totalText 件中 $done 件の変更',
    );
    return '$_temp0';
  }

  @override
  String syncApplyPacketOf(
    int count,
    String countText,
    int current,
    int packets,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText 件の変更 · パケット $packets 個中 $current 個目',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText 件の変更',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · 残り約 $seconds 秒';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · 残り約 $minutes 分';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'デバイスのストリームの分岐を検出しました: リモートノードはこのデバイスのパケットカウンター $remote を保持していますが、このデバイスは $local で、それ以前の内容が一致しているか確認できません（データベースをバックアップから復元しましたか？）。同期を再開するには、環境設定 → 同期 の「デバイス ID をリセット」を使用してください。';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'デバイスのストリームがパケットカウンター $counter で分岐しました: このデバイスと $source は、同じ ID の下に異なる内容を保持しています（こちらは $localHash、相手は $remoteHash）。このデータベースはバックアップから復元され、公開済みのパケット番号を再利用した可能性が高いです。同期を再開するには、環境設定 → 同期 の「デバイス ID をリセット」を使用してください。新しい ID でこのデータベースを再公開するので、何も失われません。';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'サーバーにこのデバイスの履歴の一部がありません: サーバーは次にパケット #$expected を期待していますが、このデバイスが保持する最も古いパケットは #$local で、その間のパケットはもうありません（このデバイスが最適化した後に、サーバーが古いバックアップから復元された可能性が高いです）。同期を再開するには、環境設定 → 同期 の「デバイス ID をリセット」を使用してください。新しい ID でこのデータベースを再公開するので、何も失われません。';
  }

  @override
  String get syncIdentityReset =>
      'このデバイスは新しい ID で同期するようになりました。次回の同期で現在のデータベースの完全なコピーを公開し、他のすべてのデバイスはそれを通常どおり統合します。';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'このデバイスは新しい ID で同期するようになりました。次回の同期で現在のデータベースの完全なコピーを公開し、他のすべてのデバイスはそれを通常どおり統合します。使用できないパケット $count 個を破棄しました。',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => '暗号鍵を導出しています';

  @override
  String get syncDetailSignedIn => 'サインイン済み';

  @override
  String get syncDetailPackaging => 'ローカルの変更をまとめています';

  @override
  String get syncDetailRecovering => 'このデバイス自身の履歴を復旧しています';

  @override
  String get syncDetailUploading => 'サーバーにアップロードしています';

  @override
  String get syncDetailNoLocalChanges => 'ローカルの変更はありません';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更を送信しました',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => 'リモートの変更をダウンロードしています';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個の添付ファイルをダウンロードしました',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '未ダウンロードの添付ファイルが $count 個あります',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'すでに最新です';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更を適用しました',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'キャンセルしました';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return '添付ファイル「$name」はまだこのデバイスにダウンロードされておらず、このデバイスでの変更がそれを参照しているため、届くまでこのデバイスの変更はサーバーに送信できません。届いたらもう一度同期するか、そのファイルを持つ近くのデバイスと同期してください。';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'サーバーは添付ファイル「$name」（$size）を大きすぎるとして拒否しました。それ以外はすべて同期されます。この添付ファイル自体は P2P 同期でのみ他のデバイスに届きます。';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'サーバーは添付ファイル「$name」（$size）を大きすぎるとして拒否しました（上限は $limit）。それ以外はすべて同期されます。この添付ファイル自体は P2P 同期でのみ他のデバイスに届きます。';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return '添付ファイル「$name」（$size）がサーバーストレージに収まりません。それ以外はすべて同期されます。サーバー上のデータを最適化するか大きな添付ファイルを削除して空きを作ってください。それまでは、この添付ファイルは P2P 同期でのみ他のデバイスに届きます。';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return '添付ファイル「$name」（$size）がサーバーストレージに収まりません（$quota 中 $used を使用）。それ以外はすべて同期されます。サーバー上のデータを最適化するか大きな添付ファイルを削除して空きを作ってください。それまでは、この添付ファイルは P2P 同期でのみ他のデバイスに届きます。';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count バイト',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      '同期サーバーが設定されていません。最適化ではリレーにスナップショットを公開します。近くのデバイスとの同期だけでは、解放するリレーのストレージはありません。';

  @override
  String get syncCompactStageSyncing => '最適化の前に同期しています';

  @override
  String get syncCompactStageChecking => 'このデバイスが最新か確認しています';

  @override
  String get syncCompactStagePackaging => 'データベース全体のスナップショットを作成しています';

  @override
  String get syncCompactStageAttachments => 'スナップショットが参照する添付ファイルをアップロードしています';

  @override
  String get syncCompactStageUploading => 'スナップショットをアップロードしています';

  @override
  String get syncCompactStageReclaiming => 'このデバイスの領域を解放しています';

  @override
  String get syncCompactStageReadingUsage => 'リレーのストレージを読み込んでいます';

  @override
  String syncCompactNeedsSync(String error) {
    return '最適化するには、先に同期を完了する必要があります: $error';
  }

  @override
  String get syncCompactDidNotFinish => '最適化が完了しませんでした。';

  @override
  String get syncCompactRaced => '別の同期が先に変更をまとめました。もう一度最適化してください。';

  @override
  String get syncCompactSnapshotMissing => 'スナップショットは作成されましたが、ローカルのストアにありません。';

  @override
  String get syncCompactMissingAttachments =>
      'このデバイスにはまだ不足している添付ファイルがあります。すべての添付ファイルがダウンロードされるまで同期してから最適化してください。';

  @override
  String syncCompactRelayRefused(String error) {
    return 'リレーがスナップショットを拒否しました: $error';
  }

  @override
  String syncCompactError(String error) {
    return '最適化に失敗しました: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'このデバイスは $count 個のパケット（$packets）を読み取れなかったため、その状態はログ内のすべてを統合したものではありません。最適化すると、このデバイスが適用していないパケットが破棄されてしまいます。',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'このデバイスにはまだ未同期の編集があります。先に同期してから最適化してください。';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'このデバイスにはまだ不足している添付ファイルがあるため（未ダウンロード $count 個）、スナップショットにそれらを含めることができず、サーバーから削除されてしまいます。すべての添付ファイルがダウンロードされるまで同期してから最適化してください。',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'このデバイスは、$count 台のデバイスについて保持している内容をまだすべて適用していません。もう一度同期してから最適化してください。',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      '近くのデバイスとの同期だけでは、削除した添付ファイルを他のデバイスがまだ保持していることを保証できないため、何も解放しませんでした。';

  @override
  String get syncCollectUnsynced =>
      'このデバイスには、サーバーにまだ保存されていない変更があります。先に同期してから最適化してください。';

  @override
  String syncSummarySnapshotOf(String device) {
    return '$device のスナップショット';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count フィールド — データベース全体',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'ノード「$name」';
  }

  @override
  String syncSummaryFile(String name) {
    return 'ファイル「$name」';
  }

  @override
  String get syncSummaryFileFallback => 'ファイル';

  @override
  String get syncSummaryTimeChunk => '時間記録';

  @override
  String syncSummaryRenamedTo(String title) {
    return '「$title」に名前を変更';
  }

  @override
  String get syncSummaryContentEdited => '内容を編集';

  @override
  String get syncSummaryMoved => '移動';

  @override
  String get syncSummaryReordered => '並べ替え';

  @override
  String get syncSummaryFlagsChanged => 'フラグを変更';

  @override
  String get syncSummaryRenamed => '名前を変更';

  @override
  String get syncSummaryContentUpdated => '内容を更新';

  @override
  String syncSummaryFrom(String time) {
    return '$time から';
  }

  @override
  String syncSummaryUntil(String time) {
    return '$time まで';
  }

  @override
  String get syncValueTopLevel => '最上位';

  @override
  String get syncStorageFull =>
      'サーバーストレージがいっぱいです。サーバー上のデータを最適化する（環境設定 → 同期 → サーバーのストレージ）か、大きな添付ファイルを削除してください。アップロードされていないものはこのデバイスに残ります。';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'サーバーストレージがいっぱいです（$quota 中 $used を使用）。サーバー上のデータを最適化する（環境設定 → 同期 → サーバーのストレージ）か、大きな添付ファイルを削除してください。アップロードされていないものはこのデバイスに残ります。';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'サーバーはこのアカウントでこれ以上デバイスのストリームを受け付けません: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'サーバーのディスク容量が不足しています。何も失われていません。後でもう一度同期してください。';

  @override
  String syncStorageRefused(String detail) {
    return 'サーバーはこれ以上の保存を拒否しました: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'このサーバーはアカウント数の上限に達しているため、新しいアカウントを受け付けていません。';

  @override
  String get syncRegClosed => 'このサーバーは新規登録を受け付けていません。運営者にアカウントを依頼してください。';

  @override
  String get syncRegTaken => 'そのユーザー名はすでに使われています。';

  @override
  String get syncRegInvalid => 'ユーザー名は 3～50 文字、サーバーのパスワードは 8～128 文字にしてください。';

  @override
  String get syncRegTooManyFromNetwork => '今日このネットワークから登録されたアカウントが多すぎます。';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return '今日このネットワークから登録されたアカウントが多すぎます。$wait後にもう一度お試しください。';
  }

  @override
  String get syncRegTooManyAttempts => '試行回数が多すぎます。';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return '試行回数が多すぎます。$wait後にもう一度お試しください。';
  }

  @override
  String get syncRegBusy => 'サーバーが混み合っています。しばらくしてからもう一度お試しください。';

  @override
  String syncRegFailed(int status) {
    return '登録に失敗しました（HTTP $status）';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return '登録に失敗しました（HTTP $status）: $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 秒',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 時間',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return '$host から $seconds 秒以内に応答がありません';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return '$host からの応答が $seconds 秒間止まっています';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…ほか $count 件 — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => '同期ログを参照';

  @override
  String get traceAtTopLevel => '最上位';

  @override
  String traceInPath(String path) {
    return '場所: $path';
  }

  @override
  String get traceRowNew => '（新規）';

  @override
  String get traceRowRemoved => '（削除）';

  @override
  String get traceShowHowTooltip => 'この変更の経緯を表示';

  @override
  String traceBytes(int count) {
    return '$count B';
  }

  @override
  String traceKilobytes(String size) {
    return '$size KB';
  }

  @override
  String traceMegabytes(String size) {
    return '$size MB';
  }

  @override
  String get traceDecisionApplied => '適用';

  @override
  String get traceDecisionCreated => 'このデバイスで作成';

  @override
  String get traceDecisionConflictCopy => '適用 — 置き換えられた値は競合コピーとして保持';

  @override
  String get traceDecisionMerged => 'このデバイスでの編集と統合 — 両方の変更を保持';

  @override
  String get traceDecisionCycleToRoot => '最上位に移動 — 親がループを作るため';

  @override
  String get traceDecisionParentMissing => '親が届くまで最上位に配置';

  @override
  String get traceDecisionBlobPending => '適用 — 添付ファイルのデータは別途届きます';

  @override
  String get traceDecisionSent => '送信';

  @override
  String get traceDecisionForwarded => '転送';

  @override
  String get traceRouteRelay => 'リレーからダウンロードしました。';

  @override
  String traceRouteRelayStored(String time) {
    return 'リレーからダウンロードしました（リレーへの保存: $time）。';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'ローカルネットワーク経由で $peer が転送しました — 作成元は $author です。';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'ローカルネットワーク経由で $peer から直接受信しました。';
  }

  @override
  String get traceRouteStoredEarlier => '以前のやり取りですでにこのデバイスにあり、今回適用しました。';

  @override
  String traceRouteStoredAt(String time) {
    return 'すでにこのデバイスにありました — $time に受信し、今回適用しました。';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'すでにこのデバイスにありました — $time に $source から受信し、今回適用しました。';
  }

  @override
  String get traceRoutePackagedUploaded => 'このデバイスでまとめ、リレーにアップロードしました。';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'このデバイスでまとめました。リレーは別の経路ですでに受け取っていました。';

  @override
  String get traceRoutePackagedBlocked =>
      'このデバイスでまとめましたが、まだアップロードしていません — 必要な添付ファイルを送信できませんでした。';

  @override
  String get traceRoutePackagedWaiting =>
      'このデバイスでまとめました。リレーまたはピアが取得するのを待っています。';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'ローカルネットワーク経由で $peer が取得しました — $author に代わって転送しました。';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'ローカルネットワーク経由で $peer が取得しました。';
  }

  @override
  String get traceBlobDownloaded => '今回ダウンロード';

  @override
  String traceBlobDownloadedSized(String size) {
    return '今回ダウンロード（$size）';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return '今回 $source からダウンロード';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return '今回 $source からダウンロード（$size）';
  }

  @override
  String get traceBlobWaiting => '未ダウンロード — 後の同期で、または開いたときに取得されます';

  @override
  String get traceBlobHeld => 'すでにこのデバイスにあります';

  @override
  String get traceBlobUploaded => 'リレーにアップロード';

  @override
  String traceBlobUploadedSized(String size) {
    return 'リレーにアップロード（$size）';
  }

  @override
  String get traceBlobOnRelay => 'リレーにすでにありました';

  @override
  String get traceBlobOffered => '他のデバイスが取得できるようこのデバイスで提供';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return '最適化のスナップショット: $device のデータベース全体を 1 つのパケットにしたものです。';
  }

  @override
  String traceSnapshotPart(String device) {
    return '$device の完全なスナップショットの一部です。スナップショットには作成元のデータベース全体が含まれます。この項目は、このデバイスの内容と異なっていたため表示されています。';
  }

  @override
  String get traceFieldsHeading => 'フィールド';

  @override
  String traceTimeEdited(String time) {
    return '編集 $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return '相手 $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'このデバイス $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'パケット $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'パケット $device #$counter（スナップショット）';
  }

  @override
  String tracePacketWritten(String time) {
    return '作成 $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の変更',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return '作成元デバイス $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'デバイス $id から';
  }

  @override
  String get traceCopyHashTooltip => 'パケットのハッシュをコピー';

  @override
  String get traceAttachmentBytesHeading => '添付ファイルのデータ';

  @override
  String get traceShowInSyncLog => '同期ログで表示';

  @override
  String get traceTriggerRelay => 'サーバー同期';

  @override
  String get traceTriggerCheck => '受信する変更の確認';

  @override
  String get traceTriggerLan => '近くのデバイス';

  @override
  String get traceTriggerLanReturn => '近くのデバイス（要求による）';

  @override
  String get traceTriggerLanServe => '近くのデバイスへ提供';

  @override
  String get traceTriggerPackage => 'ローカルの変更をまとめた';

  @override
  String get traceTriggerCompaction => '最適化';

  @override
  String get traceTriggerIdentityReset => 'デバイス ID のリセット';

  @override
  String get traceTriggerAttachment => '添付ファイルのダウンロード';

  @override
  String get traceTriggerBlobCollect => '添付ファイルの整理';

  @override
  String get traceOutcomeRunning => '実行中';

  @override
  String get traceOutcomeFailed => '失敗';

  @override
  String get traceOutcomeDeclined => '辞退';

  @override
  String get traceOutcomeBusy => '使用中';

  @override
  String get traceOutcomeInterrupted => '中断';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件のイベントを JSON としてコピーしました',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => '同期ログを消去しますか？';

  @override
  String get traceClearBody =>
      'このデバイスに記録されたすべての実行とイベントが削除されます。同期されたデータには影響しません。';

  @override
  String get traceTitle => '同期ログ';

  @override
  String get traceCopyAsJson => 'JSON としてコピー';

  @override
  String get traceClearLogTooltip => 'ログを消去';

  @override
  String get traceClearLogButton => 'ログを消去';

  @override
  String traceSummaryApplied(int count) {
    return '$count 件適用';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '警告 $count 件',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'エラー $count 件',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'やり取りなし';

  @override
  String get traceNoRuns =>
      'まだ同期は記録されていません。このデバイスがサーバーや近くのデバイスと同期すると、実行記録がここに表示されます。';

  @override
  String get traceAllRuns => 'すべての実行';

  @override
  String traceRunsRecorded(int count) {
    return '$count 件記録';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'すべての実行（$count）';
  }

  @override
  String get traceRunLabel => '実行';

  @override
  String get traceSearchHint => '検索: ノード名、ID、ハッシュ、デバイス、種類…';

  @override
  String get traceLevelAll => 'すべて';

  @override
  String get traceLevelWarnings => '警告';

  @override
  String get traceLevelErrors => 'エラー';

  @override
  String get traceDirectionAll => '受信と送信';

  @override
  String get traceDirectionIncoming => '受信';

  @override
  String get traceDirectionOutgoing => '送信';

  @override
  String get traceDirectionLocal => 'ローカル';

  @override
  String get traceNoEvents => '一致するイベントはありません。';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最初の $count 件のイベントを表示しています。残りを見るには、検索を絞り込むか実行を選択してください。',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return '実行 #$id';
  }

  @override
  String get traceEmptyValue => '（空）';

  @override
  String traceSubHash(String hash) {
    return 'ハッシュ $hash';
  }

  @override
  String traceSubValue(String hash) {
    return '値 $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'リモート $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'ローカル $time';
  }

  @override
  String get traceDetailAt => '日時';

  @override
  String get traceDetailDirection => '方向';

  @override
  String get traceDetailOriginDevice => '作成元デバイス';

  @override
  String get traceDetailCounter => 'カウンター';

  @override
  String get traceDetailHash => 'パケット / Blob のハッシュ';

  @override
  String get traceDetailEntity => 'エンティティ';

  @override
  String get traceDetailWorldId => 'World ID';

  @override
  String get traceDetailName => '名前';

  @override
  String get traceDetailField => 'フィールド';

  @override
  String get traceDetailRemoteTs => 'リモートのタイムスタンプ';

  @override
  String get traceDetailLocalTs => 'ローカルのタイムスタンプ';

  @override
  String get traceDetailValueHash => '値のハッシュ';

  @override
  String get traceDetailValuePreview => '値のプレビュー';

  @override
  String get traceDetailMessage => 'メッセージ';

  @override
  String get traceDetailDetail => '詳細';
}
