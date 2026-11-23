// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appMenuFile => '文件';

  @override
  String get appMenuEdit => '编辑';

  @override
  String get appMenuView => '视图';

  @override
  String get appMenuTools => '工具';

  @override
  String get appMenuDebug => '调试';

  @override
  String get appMenuHelp => '帮助';

  @override
  String get appMenuWindow => '窗口';

  @override
  String get appMenuOpen => '打开...';

  @override
  String get appMenuOpenDatabase => '打开数据库...';

  @override
  String get appMenuNewDatabase => '新建数据库...';

  @override
  String get appMenuExportObsidian => '导出到 Obsidian...';

  @override
  String get appMenuImportObsidian => '从 Obsidian 导入...';

  @override
  String get appMenuExit => '退出';

  @override
  String get appMenuFind => '查找...';

  @override
  String get appMenuTheme => '主题';

  @override
  String get appMenuThemeEllipsis => '主题...';

  @override
  String get appThemeSystem => '跟随系统';

  @override
  String get appThemeLight => '浅色';

  @override
  String get appThemeDark => '深色';

  @override
  String get appMenuTimeline => '时间线...';

  @override
  String get appMenuTimeReport => '时间报告...';

  @override
  String get appMenuCompactDatabase => '压缩数据库...';

  @override
  String get appMenuSyncNow => '立即同步';

  @override
  String get appMenuSyncP2p => 'P2P 同步...';

  @override
  String get appMenuPreferences => '首选项...';

  @override
  String get appMenuViewChangeHistory => '查看更改历史...';

  @override
  String get appMenuGenerateTestData => '生成测试数据';

  @override
  String get appMenuGenerateLargeDataset => '生成大型数据集';

  @override
  String get appMenuClearAllData => '清除所有数据';

  @override
  String get appMenuCheckForUpdate => '检查更新...';

  @override
  String get appMenuLogs => '日志';

  @override
  String get appMenuSyncLog => '同步日志...';

  @override
  String get appMenuAppLog => '应用日志...';

  @override
  String appMenuAbout(String appName) {
    return '关于 $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => '检查更新…';

  @override
  String get appMacMenuSettings => '设置…';

  @override
  String appMacMenuQuit(String appName) {
    return '退出 $appName';
  }

  @override
  String get appMacMenuOpen => '打开…';

  @override
  String get appMacMenuNewDatabase => '新建数据库…';

  @override
  String get appMacMenuExportObsidian => '导出到 Obsidian…';

  @override
  String get appMacMenuImportObsidian => '从 Obsidian 导入…';

  @override
  String get appMacMenuUndo => '撤销';

  @override
  String get appMacMenuRedo => '重做';

  @override
  String get appMacMenuCut => '剪切';

  @override
  String get appMacMenuPaste => '粘贴';

  @override
  String get appMacMenuSelectAll => '全选';

  @override
  String get appMacMenuFind => '查找…';

  @override
  String get appMacMenuTimeline => '时间线…';

  @override
  String get appMacMenuTimeReport => '时间报告…';

  @override
  String get appMacMenuCompactDatabase => '压缩数据库…';

  @override
  String get appMacMenuSyncP2p => 'P2P 同步…';

  @override
  String get appMacMenuViewChangeHistory => '查看更改历史…';

  @override
  String get appMacMenuSyncLog => '同步日志…';

  @override
  String get appMacMenuAppLog => '应用日志…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => '打开数据库';

  @override
  String get appCreateDatabaseDialogTitle => '新建数据库';

  @override
  String get appIncorrectPasswordRetry => '密码不正确，请重试。';

  @override
  String appDatabaseOpened(String fileName) {
    return '已打开：$fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return '无法打开数据库：$error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return '已创建：$fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return '无法创建数据库：$error';
  }

  @override
  String get appOpenDatabaseFirst => '请先打开一个数据库';

  @override
  String get appNoDatabaseOpen => '未打开数据库';

  @override
  String appCannotReadDatabaseFile(String error) {
    return '无法读取数据库文件：$error';
  }

  @override
  String get appWrongPasswordOrCorrupt => '密码不正确或数据库已损坏';

  @override
  String get appExportObsidianDialogTitle => '导出到 Obsidian 目录';

  @override
  String get appImportObsidianDialogTitle => '从 Obsidian 目录导入';

  @override
  String get appImportObsidianZipDialogTitle => '导入 Obsidian .zip';

  @override
  String get appExportingObsidian => '正在导出为 Obsidian 格式...';

  @override
  String get appImportingObsidian => '正在从 Obsidian 格式导入...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个任务',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个时间线文件',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张图片',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条时间记录',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return '已导出 $tasks、$timelineFiles、$images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return '已导入 $tasks、$timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String appImportFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obsidian 导出（$count 个任务）',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return '目录不存在：$path';
  }

  @override
  String get appSyncNotConfigured => '尚未配置同步。请先打开同步设置。';

  @override
  String get appNoSyncServer =>
      '未配置同步服务器。请使用“P2P 同步...”（Shift+F5），或在首选项中添加服务器。';

  @override
  String get appUnsyncedChangesTitle => '未同步的更改';

  @override
  String get appUnsyncedChangesBody => '有尚未同步的更改，是否要同步？';

  @override
  String get appDontSync => '不同步';

  @override
  String get appSync => '同步';

  @override
  String get appSelectTaskFirst => '请先选择一个任务';

  @override
  String get appGenerateTestDataBody => '这将创建带有层级结构和时间记录的示例任务。\n\n是否继续？';

  @override
  String get appGenerate => '生成';

  @override
  String get appTestDataGenerated => '测试数据已生成';

  @override
  String get appGenerateLargeDatasetBody =>
      '这将创建一个大型数据集，包括：\n- 20 个顶级任务\n- 最多 5 层深\n- 每个任务最多 6 个子任务\n- 许多任务的时间记录\n\n这可能需要一些时间。是否继续？';

  @override
  String get appGeneratingData => '正在生成数据...';

  @override
  String get appLargeDatasetGenerated => '大型数据集已生成';

  @override
  String get appClearAllDataBody => '这将永久删除所有任务、时间记录和附件。\n\n此操作无法撤销。确定要继续吗？';

  @override
  String get appDeleteAll => '全部删除';

  @override
  String get appAllDataCleared => '所有数据已清除';

  @override
  String get appCompactDatabaseTitle => '压缩数据库';

  @override
  String get appCompactDatabaseBody =>
      '重写数据库文件，将已删除的任务、附件和旧更改历史所占用的空间归还给磁盘。\n\n已删除附件的内容也会被释放；如果以后恢复其中某个附件，会从服务器重新下载。\n\n仍然可见的内容不会被删除。数据库较大时这需要一段时间，完成之前无法使用本应用。';

  @override
  String get appCompact => '压缩';

  @override
  String get appCompactingDatabase => '正在压缩数据库...';

  @override
  String appCompactingFailed(String error) {
    return '压缩失败：$error';
  }

  @override
  String get appDatabaseCompacted => '数据库已压缩';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return '数据库已压缩 — 释放了 $freed（现为 $size）';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return '数据库已压缩 — 已是紧凑状态（$size）';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result。$note';
  }

  @override
  String get appFindTooltip => '查找';

  @override
  String get appSyncNowTooltip => '立即同步';

  @override
  String get appBiometricFailed => '生物识别验证失败。请输入密码。';

  @override
  String get appSavedPasswordIncorrect => '保存的密码不正确。请输入密码。';

  @override
  String get appLoading => '正在加载...';

  @override
  String get appFailedToOpenDatabaseTitle => '无法打开数据库';

  @override
  String get appOpenAnotherDatabase => '打开其他数据库…';

  @override
  String get appBiometricReason => '解锁你的 Noo 数据库';

  @override
  String appWelcomeTitle(String appName) {
    return '欢迎使用 $appName';
  }

  @override
  String get appWelcomeIntro => '选择加密数据库的存储位置。以后可以在“文件”菜单中更改。';

  @override
  String get appUseDefaultLocation => '使用默认位置';

  @override
  String get appResolving => '正在确定…';

  @override
  String get appCreateNewDatabaseOption => '新建数据库…';

  @override
  String get appCreateNewDatabaseSubtitle => '为新的加密数据库选择自定义位置。';

  @override
  String get appOpenExistingDatabaseOption => '打开现有数据库…';

  @override
  String get appOpenExistingDatabaseSubtitle => '使用其他位置的现有 .noo 文件。';

  @override
  String get appQuit => '退出';

  @override
  String get appWelcomeSyncHint =>
      '在其他设备上已有数据库？请在此用相同的密码新建一个数据库，然后在“首选项 → 同步”中使用相同的用户名设置同步——首次同步时你的笔记就会到达。';

  @override
  String get appTaskFallbackTitle => '任务';

  @override
  String get appTabNotes => '笔记';

  @override
  String get appTabTime => '时间';

  @override
  String get appTabFiles => '文件';

  @override
  String appTabFilesCount(int count) {
    return '文件（$count）';
  }

  @override
  String get appStartTracking => '开始计时';

  @override
  String get appStopTracking => '停止计时';

  @override
  String get appNoTaskSelected => '未选择任务。';

  @override
  String get appAttachmentsHeading => '附件';

  @override
  String get appModified => '已修改';

  @override
  String get appWordWrapOnTooltip => '自动换行已开启 — 点击关闭';

  @override
  String get appWordWrapOffTooltip => '自动换行已关闭 — 点击开启';

  @override
  String get appTimeTodayTap => '今日跟踪时间 — 轻点打开';

  @override
  String get appHideTimeTracking => '隐藏时间跟踪';

  @override
  String get appTimeTodayClick => '今日跟踪时间 — 点击查看详情';

  @override
  String get appViewTimeline => '查看时间线';

  @override
  String get appAttachmentsTap => '附件 — 轻点打开';

  @override
  String get appHideAttachments => '隐藏附件';

  @override
  String get appAttachmentsClick => '附件 — 点击显示';

  @override
  String get appAddAttachment => '添加附件';

  @override
  String get appUntitledInPath => '（无标题）';

  @override
  String get appSyncStatusDisabled => '同步已禁用 — 点击同步';

  @override
  String get appSyncStatusUnknown => '尚未同步 — 点击同步';

  @override
  String get appSyncStatusIdle => '已同步 — 点击同步';

  @override
  String get appSyncStatusSyncing => '正在同步...';

  @override
  String get appSyncStatusError => '同步出错 — 点击重试';

  @override
  String get appSyncStatusPending => '有待同步的更改 — 点击同步';

  @override
  String get appSyncStatusIncoming => '其他设备发来了更改 — 点击同步';

  @override
  String appTrackingChipTooltip(String title) {
    return '正在为“$title”计时 — 点击转到该任务';
  }

  @override
  String appStopTrackingTask(String title) {
    return '停止为“$title”计时';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String appPendingMore(int count) {
    return '还有 $count 项';
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
      other: '$count 项',
      one: '1 项',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 处更改',
      one: '1 处更改',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return '等待同步：$items，$changes';
  }

  @override
  String get appPendingFieldTitle => '标题';

  @override
  String get appPendingFieldContent => '内容';

  @override
  String get appPendingFieldMoved => '已移动';

  @override
  String get appPendingFieldReordered => '已重新排序';

  @override
  String get appPendingFieldFlags => '标志';

  @override
  String get appPendingFieldDeleted => '已删除';

  @override
  String get appPendingFieldName => '名称';

  @override
  String get appPendingFieldStartTime => '开始时间';

  @override
  String get appPendingFieldEndTime => '结束时间';

  @override
  String get appJustNow => '刚刚';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 分钟前',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时前',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天前',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => '输入密码';

  @override
  String get appSetDatabasePasswordTitle => '设置数据库密码';

  @override
  String get appPasswordLabel => '密码';

  @override
  String get appConfirmPasswordLabel => '确认密码';

  @override
  String get appPleaseEnterPassword => '请输入密码';

  @override
  String get appPasswordTooShort => '密码至少需要 4 个字符';

  @override
  String get appPasswordsDoNotMatch => '两次输入的密码不一致';

  @override
  String get appPasswordWarning => '此密码将用于加密你的数据库。如果忘记密码，数据将无法恢复。';

  @override
  String get appCreate => '创建';

  @override
  String get appStrengthVeryWeak => '非常弱';

  @override
  String get appStrengthWeak => '弱';

  @override
  String get appStrengthFair => '一般';

  @override
  String get appStrengthGood => '良好';

  @override
  String get appStrengthStrong => '强';

  @override
  String get appTagline => '带时间跟踪的小巧大纲工具';

  @override
  String get appAboutDescription => '一款跨平台的桌面大纲应用，用于整理想法、任务和项目，并内置时间跟踪。';

  @override
  String get appBuiltWithFlutter => '使用 Flutter 构建';

  @override
  String get appCheckForUpdateTitle => '检查更新';

  @override
  String appCouldNotOpen(String url) {
    return '无法打开 $url';
  }

  @override
  String get appOpenReleasePage => '打开发布页面';

  @override
  String get appDownloadApk => '下载 APK';

  @override
  String get appDownloadDiskImage => '下载磁盘映像';

  @override
  String get appCheckingForUpdate => '正在检查新版本...';

  @override
  String get appUpdateCheckFailed => '检查更新失败';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version 已是最新版本。';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version 已发布（你的版本为 $installed）。';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return '正在下载 $appName $version...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version 已下载并通过验证。安装时将关闭 $appName，替换程序文件并重新启动。你的数据库不会受到影响。';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version 已安装。重新启动后即可使用。';
  }

  @override
  String get appLater => '稍后';

  @override
  String get appInstall => '安装';

  @override
  String get appInstallAndRestart => '安装并重新启动';

  @override
  String get appRestartNow => '立即重新启动';

  @override
  String get appUpdGithubTimeout => 'GitHub 未及时响应';

  @override
  String appUpdCannotReachGithub(String error) {
    return '无法连接 GitHub：$error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub 对最新版本的请求返回了 $status';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return '意外的版本数据：$error';
  }

  @override
  String get appUpdUnexpectedData => '意外的版本数据';

  @override
  String get appUpdNoInPlace => '此平台不支持就地更新';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return '版本 $version 没有 Windows 安装程序';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return '版本 $version 没有 Windows ZIP';
  }

  @override
  String appUpdCannotWrite(String path) {
    return '无法写入 $path；请手动下载新版本';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName 中不包含 $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return '下载的文件不是有效的 ZIP：$error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'ZIP 包含不安全的路径：$path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return '无法解压下载的文件：$error';
  }

  @override
  String get appUpdNotAppImage => '未从 AppImage 运行';

  @override
  String appUpdNoAppImage(String version) {
    return '版本 $version 没有 Linux AppImage';
  }

  @override
  String appUpdCannotChmod(String error) {
    return '无法将新的 AppImage 设为可执行：$error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return '无法替换 $path：$error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return '下载失败：服务器返回 $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return '无法保存下载的文件：$error';
  }

  @override
  String appUpdInterrupted(String error) {
    return '下载中断：$error';
  }

  @override
  String get appUpdChecksumMismatch => '下载的文件与发布的校验和不匹配';

  @override
  String appUpdNoChecksums(String version) {
    return '版本 $version 未发布校验和；请手动下载';
  }

  @override
  String get appUpdChecksumTimeout => '下载校验和超时';

  @override
  String appUpdChecksumFailed(String error) {
    return '下载校验和失败：$error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return '下载校验和失败：服务器返回 $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$checksumsFile 中未列出 $fileName';
  }

  @override
  String get appLogCopied => '应用日志已复制到剪贴板';

  @override
  String get appLogTitle => '应用日志';

  @override
  String get appLogSaveDialogTitle => '保存应用日志';

  @override
  String appSavedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String appSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get appShare => '分享';

  @override
  String get appClearLogTooltip => '清除日志';

  @override
  String get appClearLogButton => '清除日志';

  @override
  String get appSaveEllipsis => '保存...';

  @override
  String get appSearchHint => '搜索';

  @override
  String get appLogLevelAll => '全部';

  @override
  String get appLogLevelWarnings => '警告和错误';

  @override
  String get appLogLevelErrors => '错误';

  @override
  String get appLogEmpty => '尚无日志记录。';

  @override
  String get appLogNoMatch => '没有匹配的行。';

  @override
  String get appHistoryTitle => '更改历史';

  @override
  String get appHistoryFilter => '筛选： ';

  @override
  String appHistoryAll(int count) {
    return '全部（$count）';
  }

  @override
  String appHistoryTasks(int count) {
    return '任务（$count）';
  }

  @override
  String appHistoryFiles(int count) {
    return '文件（$count）';
  }

  @override
  String appHistoryTimeline(int count) {
    return '时间线（$count）';
  }

  @override
  String appHistoryError(String error) {
    return '错误：$error';
  }

  @override
  String get appHistoryEmpty => '未找到历史记录';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更改了 $count 个字段',
      one: '更改了 1 个字段',
      zero: '未更改字段',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return '显示 $shown / $total 个分组条目（共 $changes 处字段更改）';
  }

  @override
  String get appHistoryOld => '旧值：';

  @override
  String get appHistoryNew => '新值：';

  @override
  String get commonOk => '确定';

  @override
  String get commonCancel => '取消';

  @override
  String get commonClose => '关闭';

  @override
  String get commonSave => '保存';

  @override
  String get commonSaveAs => '另存为...';

  @override
  String get commonDelete => '删除';

  @override
  String get commonRename => '重命名';

  @override
  String get commonRemove => '移除';

  @override
  String get commonAdd => '添加';

  @override
  String get commonOpen => '打开';

  @override
  String get commonCopy => '复制';

  @override
  String get commonApply => '应用';

  @override
  String get commonRetry => '重试';

  @override
  String get commonYes => '是';

  @override
  String get commonNo => '否';

  @override
  String get commonBrowse => '浏览...';

  @override
  String get commonError => '错误';

  @override
  String get commonShow => '显示';

  @override
  String get commonHide => '隐藏';

  @override
  String get commonClear => '清除';

  @override
  String get commonRefresh => '刷新';

  @override
  String get commonTest => '测试';

  @override
  String get commonDownload => '下载';

  @override
  String get commonNone => '无';

  @override
  String get commonSystemDefault => '系统默认';

  @override
  String get commonUntitled => '无标题';

  @override
  String get languageSystem => '系统默认';

  @override
  String get editorImageNotAvailable => '图片不可用';

  @override
  String get editorImageResize => '调整大小...';

  @override
  String get editorImageReplace => '替换图片...';

  @override
  String get editorImageSaveAs => '图片另存为...';

  @override
  String get editorImageRemoveFromText => '从文本中移除';

  @override
  String get editorImageRemoveFromTextHint => '文件保留在附件中';

  @override
  String get editorImageDelete => '删除图片';

  @override
  String get editorImageDeleteHint => '同时删除附件';

  @override
  String get editorImageKeptInOtherTask => '图片已从文本中移除。该文件属于另一个任务，已在那里保留。';

  @override
  String get editorResizeImageTitle => '调整图片大小';

  @override
  String get editorResizeWidth => '宽度';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$natural px 的 $percent%';
  }

  @override
  String get editorResizeOriginalSize => '原始大小';

  @override
  String get editorInsertImage => '插入图片';

  @override
  String get editorReplaceImageDialogTitle => '替换图片';

  @override
  String get editorSaveImageDialogTitle => '保存图片';

  @override
  String editorSavedFile(String name) {
    return '已保存：$name';
  }

  @override
  String get editorAttachFileTooltipCompact => '附加文件\n（长按显示附件）';

  @override
  String get editorAttachFileTooltip => '附加文件\n（长按显示或隐藏附件）';

  @override
  String get editorStopRecording => '停止录音';

  @override
  String get editorRecordVoiceMemo => '录制语音备忘录';

  @override
  String get editorRecordVoiceMemoTooltip => '录制语音备忘录\n（长按录制但不转写）';

  @override
  String editorAttachedOne(String name) {
    return '已附加 $name';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已附加 $count 个文件',
      one: '已附加 1 个文件',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => '字体';

  @override
  String get editorFontSize => '字号';

  @override
  String get editorSizeLabel => '字号';

  @override
  String get editorSizeSmall => '小';

  @override
  String get editorSizeLarge => '大';

  @override
  String get editorSizeHuge => '特大';

  @override
  String get editorStartTyping => '开始输入...';

  @override
  String get editorLinkedTaskGone => '链接的任务已不存在。';

  @override
  String get editorRemoveFormatting => '清除格式';

  @override
  String editorFormatAsTable(String separator) {
    return '格式化为表格（$separator）';
  }

  @override
  String get editorWordWrapOff => '关闭自动换行';

  @override
  String get editorWordWrapOn => '开启自动换行';

  @override
  String editorErrorMessage(String error) {
    return '错误：$error';
  }

  @override
  String get editorTaskNotFound => '未找到任务';

  @override
  String get editorSelectTask => '选择要编辑的任务';

  @override
  String editorSaveFailed(String error) {
    return '无法保存任务：$error';
  }

  @override
  String get editorChangesMerged => '你编辑这篇笔记时，它在别处被更改了。两处更改已合并。';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return '你编辑这篇笔记时，它在别处被更改了。你的文本已保存；另一个版本保留为“$copyTitle”。';
  }

  @override
  String get treeNewTask => '新建任务 (Ctrl+N)';

  @override
  String get treeNewChildTask => '新建子任务 (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => '删除任务';

  @override
  String get treeExpandAll => '全部展开';

  @override
  String get treeCollapseAll => '全部折叠';

  @override
  String get treeNoTasks => '还没有任务';

  @override
  String get treeCreateFirstTask => '创建第一个任务';

  @override
  String get treeTrackedHere => '正在为此任务计时';

  @override
  String get treeTrackedInside => '正在为其中的某个任务计时';

  @override
  String get treeHiddenFromAgents => '对 AI 代理隐藏，包括其下的所有内容';

  @override
  String get treeMoveUp => '上移';

  @override
  String get treeMoveDown => '下移';

  @override
  String get treeMoveToParentLevel => '移到上一级';

  @override
  String get treeMoveUnderPrevious => '移到上一项之下';

  @override
  String get treeAddChildTask => '添加子任务';

  @override
  String get treeStartTracking => '开始计时';

  @override
  String get treeStopTracking => '停止计时';

  @override
  String get treeTimeline => '时间线...';

  @override
  String get searchHint => '搜索任务...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个结果',
      one: '1 个结果',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => '无匹配项';

  @override
  String get searchUntitled => '（无标题）';

  @override
  String get attachImageNotAvailable => '图片不可用';

  @override
  String get attachTryAgain => '重试';

  @override
  String get attachPlay => '播放';

  @override
  String get attachPause => '暂停';

  @override
  String attachLoadFailed(String error) {
    return '无法加载附件：$error';
  }

  @override
  String get attachNone => '没有附件';

  @override
  String get attachAddFile => '添加文件';

  @override
  String get attachNotDownloaded => '此附件尚未下载 — 请同步以获取';

  @override
  String get attachContentLoadFailed => '无法加载附件内容';

  @override
  String get attachDownloading => '正在下载附件…';

  @override
  String get attachExportDialogTitle => '导出附件';

  @override
  String attachExported(String name) {
    return '已导出：$name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return '没有可以打开 $name 的应用';
  }

  @override
  String get attachImageInNoteTitle => '图片在笔记中';

  @override
  String attachImageInNoteBody(String name) {
    return '“$name”显示在此任务的笔记中，因此无法在这里删除。\n\n请点击笔记中的图片，选择“删除图片”以同时删除图片和文件；或选择“从文本中移除”以保留文件，之后再在这里删除。';
  }

  @override
  String get attachDeleteTitle => '删除附件？';

  @override
  String attachDeleteConfirm(String name) {
    return '确定要删除“$name”吗？';
  }

  @override
  String get attachRenameTitle => '重命名附件';

  @override
  String get attachFileName => '文件名';

  @override
  String get attachShowPreview => '显示预览';

  @override
  String get attachHidePreview => '隐藏预览';

  @override
  String get attachShare => '分享';

  @override
  String get attachExport => '导出';

  @override
  String get attachTranscribe => '转写';

  @override
  String get attachCannotPlay => '无法播放此文件';

  @override
  String get attachPlaybackUnavailable => '无法播放';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '录音已在达到 $_temp0上限时停止。备忘录已保存。';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '已达到 $_temp0上限';
  }

  @override
  String get voiceDismiss => '关闭';

  @override
  String get voiceOpeningMic => '正在打开麦克风…';

  @override
  String get voiceSaving => '正在保存…';

  @override
  String get voiceSavedTranscribing => '已保存。正在转写…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return '已保存。正在转写… $percent%';
  }

  @override
  String get voiceDiscard => '丢弃';

  @override
  String get voiceStop => '停止';

  @override
  String get voiceChooseModelFirst => '请先在首选项中选择转写模型';

  @override
  String voiceModelNotDownloaded(String model) {
    return '$model 模型尚未下载 — 请查看首选项';
  }

  @override
  String get voiceTranscribing => '正在转写…';

  @override
  String voiceTranscribingPercent(int percent) {
    return '正在转写… $percent%';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return '无法转写：$error';
  }

  @override
  String get voiceNoSpeech => '此备忘录中未检测到语音';

  @override
  String get voiceTranscribedNoteNotOpen => '已转写，但所属的笔记未打开';

  @override
  String get voiceDiscardedDatabaseSwitched => '由于打开了另一个数据库，录音已被丢弃。';

  @override
  String get voiceMicPermissionRefused => '麦克风权限被拒绝';

  @override
  String voiceStartFailed(String error) {
    return '无法开始录音：$error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return '录音失败：$error';
  }

  @override
  String voiceFinishFailed(String error) {
    return '无法完成录音：$error';
  }

  @override
  String get voiceNoDatabase => '未打开数据库，因此无法保存备忘录';

  @override
  String voiceSaveFailed(String error) {
    return '无法保存备忘录：$error';
  }

  @override
  String get timeTimelineTitle => '时间线';

  @override
  String get timeStatsToday => '今天：';

  @override
  String get timeStatsThisMonth => '本月：';

  @override
  String timeRecordingSince(String time) {
    return '自 $time 起计时';
  }

  @override
  String get timeEndBeforeStart => '结束时间必须晚于开始时间';

  @override
  String get timeOverlaps => '与现有时间段重叠';

  @override
  String get timeAddIntervalTitle => '添加时间段';

  @override
  String get timeEditIntervalTitle => '编辑时间段';

  @override
  String get timeStartTime => '开始时间：';

  @override
  String get timeFinishTime => '结束时间：';

  @override
  String get timeDurationLabel => '时长：';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 小时',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours 小时',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes 分钟',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '$hours小时$minutes分钟';
  }

  @override
  String timeShortHours(int hours) {
    return '$hours小时';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '$minutes分钟';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '$seconds秒';
  }

  @override
  String get timeAddEllipsis => '添加...';

  @override
  String get timeNoRecords => '没有时间记录';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day（$weekday）';
  }

  @override
  String get timeNow => '现在';

  @override
  String get timeRemoveIntervalTitle => '移除时间段？';

  @override
  String get timeRemoveIntervalConfirm => '确定要移除此时间段吗？';

  @override
  String get timeNotTracking => '未在计时';

  @override
  String get timeStopTracking => '停止计时';

  @override
  String get timeStartTracking => '开始计时';

  @override
  String get timeBackToFullWindow => '返回完整窗口';

  @override
  String get timeReportTitle => '时间报告';

  @override
  String get timeReportSaveTitle => '保存时间报告';

  @override
  String timeReportGenerateFailed(String error) {
    return '无法生成报告：$error';
  }

  @override
  String get timeReportCopied => '报告已复制到剪贴板';

  @override
  String timeReportSavedTo(String path) {
    return '已保存到 $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return '保存失败：$error';
  }

  @override
  String get timeReportTasks => '任务';

  @override
  String get timeReportNoTasks => '没有可用的任务。';

  @override
  String get timeReportClearSelection => '清除选择';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已选择 $count 个',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => '包括子孙任务';

  @override
  String get timeReportIncludeDescendantsHint => '同时统计每个所选节点下子任务的时间。';

  @override
  String get timeReportDateRange => '日期范围';

  @override
  String timeReportFrom(String date) {
    return '从：$date';
  }

  @override
  String timeReportTo(String date) {
    return '到：$date';
  }

  @override
  String get timeReportFormat => '格式';

  @override
  String get timeReportFormatTree => '树形（仅合计）';

  @override
  String get timeReportFormatTreeWithDays => '树形，按天细分';

  @override
  String get timeReportFormatFlat => '平铺时间段列表';

  @override
  String get timeReportShowEmpty => '显示无记录的任务';

  @override
  String get timeReportUntitled => '（无标题）';

  @override
  String get timeReportSelectTasks => '选择一个或多个任务以生成报告。';

  @override
  String get timeReportNoRecordsInPeriod => '所选时间段内没有时间记录。';

  @override
  String get timeReportTextPeriod => '期间：';

  @override
  String get timeReportTextTotal => '合计：';

  @override
  String get timeReportTextGenerated => '生成时间：';

  @override
  String get timeReportTextClipped => '跨越期间边界的记录已按期间截取。';

  @override
  String timeReportTextSelf(String duration) {
    return '自身：$duration';
  }

  @override
  String get timeReportTextOngoing => '进行中';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条记录',
      one: '1 条记录',
    );
    return '合计：$duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => '重新生成';

  @override
  String get timeReportShare => '分享…';

  @override
  String get timeReportSave => '保存…';

  @override
  String get timeReportPresetToday => '今天';

  @override
  String get timeReportPresetThisWeek => '本周';

  @override
  String get timeReportPresetThisMonth => '本月';

  @override
  String get timeReportPresetLastMonth => '上月';

  @override
  String get timeReportPresetThisYear => '今年';

  @override
  String get prefsTitle => '首选项';

  @override
  String get prefsTabAppearance => '外观';

  @override
  String get prefsTabBehavior => '行为';

  @override
  String get prefsTabVoiceMemos => '语音备忘录';

  @override
  String get prefsTabSync => '同步';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label：';
  }

  @override
  String get prefsGroupLanguage => '语言';

  @override
  String get prefsInterfaceLanguage => '界面';

  @override
  String get prefsLanguageHint => '英语以外的翻译均为机器翻译，欢迎指正。';

  @override
  String get prefsGroupTheme => '主题';

  @override
  String get prefsThemeMode => '模式';

  @override
  String get prefsThemeSystem => '跟随系统';

  @override
  String get prefsThemeLight => '浅色';

  @override
  String get prefsThemeDark => '深色';

  @override
  String get prefsGroupStyle => '样式';

  @override
  String get prefsGroupColour => '颜色';

  @override
  String get prefsLook => '外观';

  @override
  String get prefsLookHint => '经典：直角、带边框的扁平按钮、无涟漪效果、始终显示滚动条，以及强调色的标题栏和其下方的菜单。';

  @override
  String get prefsUiStyleModern => '现代';

  @override
  String get prefsUiStyleClassic => '经典';

  @override
  String get prefsAccentColour => '强调色';

  @override
  String get prefsAccentTeal => '青色';

  @override
  String get prefsAccentBlue => '蓝色';

  @override
  String get prefsAccentIndigo => '靛蓝';

  @override
  String get prefsAccentPurple => '紫色';

  @override
  String get prefsAccentPink => '粉色';

  @override
  String get prefsAccentRed => '红色';

  @override
  String get prefsAccentOrange => '橙色';

  @override
  String get prefsAccentAmber => '琥珀色';

  @override
  String get prefsAccentGreen => '绿色';

  @override
  String get prefsAccentGraphite => '石墨色';

  @override
  String get prefsGroupWindow => '窗口';

  @override
  String get prefsSystemTitleBar => '使用系统标题栏';

  @override
  String get prefsSystemTitleBarHint => '由桌面环境绘制窗口边框、标题和按钮，菜单栏位于其下方。';

  @override
  String get prefsGroupEditorFont => '编辑器字体（笔记文本）';

  @override
  String get prefsGroupTreeFont => '树字体（大纲）';

  @override
  String get prefsGroupInterfaceFont => '界面字体（菜单和对话框）';

  @override
  String get prefsFontFamily => '字体';

  @override
  String get prefsFontCustom => '自定义…';

  @override
  String get prefsCustomName => '自定义名称';

  @override
  String prefsCustomFamilyExample(String font) {
    return '例如 $font';
  }

  @override
  String get prefsFontSize => '字号';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => '样式';

  @override
  String get prefsBold => '粗体';

  @override
  String get prefsItalic => '斜体';

  @override
  String get prefsPreview => '预览';

  @override
  String get prefsPreviewText => '敏捷的棕色狐狸跳过了那只懒狗。';

  @override
  String get prefsScale => '缩放';

  @override
  String get prefsFontSansSerif => '无衬线';

  @override
  String get prefsFontSerif => '衬线';

  @override
  String get prefsFontMonospace => '等宽';

  @override
  String get prefsGroupTimeTracking => '时间跟踪';

  @override
  String get prefsEnableTimeTracking => '启用时间跟踪';

  @override
  String get prefsEnableTimeTrackingHint =>
      '开始/停止计时、时间线和时间报告。关闭后将隐藏这些功能；已记录的时间会保留';

  @override
  String get prefsShowSeconds => '显示秒';

  @override
  String get prefsShowSecondsHint => '在时长中显示秒';

  @override
  String get prefsMiniTracker => '计时时显示迷你窗口';

  @override
  String get prefsMiniTrackerHint => '计时进行中时，最小化窗口会将其缩小为一个始终置顶的小时钟';

  @override
  String get prefsGroupSaving => '保存';

  @override
  String get prefsAutoSaveEvery => '自动保存间隔';

  @override
  String get prefsUnitSec => '秒';

  @override
  String get prefsGroupEditor => '编辑器';

  @override
  String get prefsTabWidth => '制表符宽度';

  @override
  String get prefsUnitSpaces => '个空格';

  @override
  String get prefsTabAsSpaces => '以空格插入制表符';

  @override
  String get prefsTabAsSpacesHint => '按 Tab 键插入空格而不是制表符';

  @override
  String get prefsWordWrap => '自动换行';

  @override
  String get prefsWordWrapHint =>
      '关闭时：长行不换行，笔记可横向滚动（Shift + 滚轮）。也可在编辑器的上下文菜单和状态栏中切换';

  @override
  String get prefsMonospaceOnly => '仅限等宽字体';

  @override
  String get prefsMonospaceOnlyHint => '工具栏的字体菜单只提供等宽字体，让需要对齐的文本保持对齐';

  @override
  String get prefsFloatingButtons => '浮动按钮';

  @override
  String get prefsFloatingButtonsHint => '在笔记上方显示“附加文件”和“录制语音备忘录”；工具栏中的按钮始终保留';

  @override
  String get prefsPaste => '粘贴';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V 始终粘贴纯文本';

  @override
  String get prefsPasteKeep => '保留格式';

  @override
  String get prefsPasteStrip => '去除颜色和字体';

  @override
  String get prefsPastePlain => '仅纯文本';

  @override
  String get prefsTableColumns => '表格列';

  @override
  String get prefsTableColumnsHint => '“格式化为表格”（编辑器上下文菜单）用于分列的字符。URL 和引号内的文本除外';

  @override
  String get prefsSeparatorColon => '冒号  ( : )';

  @override
  String get prefsSeparatorEquals => '等号  ( = )';

  @override
  String get prefsSeparatorPipe => '竖线  ( | )';

  @override
  String get prefsSeparatorSemicolon => '分号  ( ; )';

  @override
  String get prefsSeparatorComma => '逗号  ( , )';

  @override
  String get prefsSeparatorTab => '制表符';

  @override
  String get prefsGroupToolbarButtons => '工具栏按钮';

  @override
  String get prefsToolbarButtonsHint => '取消勾选按钮即可将其从编辑器工具栏中移除。';

  @override
  String get prefsToolbarUndoRedo => '撤销 / 重做';

  @override
  String get prefsToolbarFont => '字体';

  @override
  String get prefsToolbarSize => '字号';

  @override
  String get prefsToolbarBold => '粗体';

  @override
  String get prefsToolbarItalic => '斜体';

  @override
  String get prefsToolbarUnderline => '下划线';

  @override
  String get prefsToolbarStrikeThrough => '删除线';

  @override
  String get prefsToolbarInlineCode => '代码';

  @override
  String get prefsToolbarTextColor => '文本颜色';

  @override
  String get prefsToolbarHighlightColor => '突出显示颜色';

  @override
  String get prefsToolbarClearFormat => '清除格式';

  @override
  String get prefsToolbarHeadings => '标题';

  @override
  String get prefsToolbarNumberedList => '编号列表';

  @override
  String get prefsToolbarBulletedList => '项目符号列表';

  @override
  String get prefsToolbarChecklist => '核对清单';

  @override
  String get prefsToolbarCodeBlock => '代码块';

  @override
  String get prefsToolbarQuote => '引用';

  @override
  String get prefsToolbarIndent => '缩进';

  @override
  String get prefsToolbarLink => '链接';

  @override
  String get prefsToolbarInsertImage => '插入图片';

  @override
  String get prefsToolbarVoiceMemo => '语音备忘录';

  @override
  String get prefsGroupSecurity => '安全';

  @override
  String get prefsRememberPassword => '记住密码';

  @override
  String get prefsRememberPasswordHint => '将数据库密码存储在系统钥匙串中';

  @override
  String get prefsBiometricUnlock => '生物识别解锁';

  @override
  String get prefsBiometricUnavailableHint => '不可用 — 请先在 Android 设置中设置指纹或屏幕锁定';

  @override
  String get prefsBiometricHint => '使用记住的密码前，需先验证指纹、面容或屏幕锁定';

  @override
  String get prefsBlockScreenshots => '阻止截屏';

  @override
  String get prefsBlockScreenshotsHint => '在截屏、屏幕录制和最近使用的应用切换器中隐藏应用内容';

  @override
  String get prefsGroupStartup => '启动';

  @override
  String get prefsSingleInstance => '单实例';

  @override
  String get prefsSingleInstanceHint => '只允许一个运行中的窗口；再次启动时将切换到现有窗口。下次启动时生效。';

  @override
  String get prefsVoiceGroupDevices => '设备';

  @override
  String get prefsVoiceMicrophone => '麦克风';

  @override
  String get prefsVoiceMicrophoneHint => '用于语音备忘录和下方的检测。';

  @override
  String get prefsVoiceSpeaker => '扬声器';

  @override
  String get prefsVoiceSpeakerHint => '适用于语音备忘录。其他音频附件通过系统默认设备播放。';

  @override
  String get prefsVoiceDevicesLooking => '正在查找…';

  @override
  String prefsVoiceDevicesError(String error) {
    return '无法列出音频设备：$error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => '不可用';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name（默认）';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name（未连接）';
  }

  @override
  String get prefsVoiceGroupTranscription => '转写';

  @override
  String get prefsVoiceModel => '模型';

  @override
  String get prefsVoiceModelHintNone => '备忘录仅以音频形式录制和存储。';

  @override
  String get prefsVoiceModelHintLocal => '在本设备上运行，不会向任何地方发送数据。';

  @override
  String get prefsVoiceModelOff => '关闭';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · 推荐';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => '录制后转写';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      '备忘录会先存储，再根据存储的音频进行转写。关闭后将存储为未转写；之后仍可使用附件菜单中的“转写”。';

  @override
  String get prefsVoiceLanguage => '语言';

  @override
  String get prefsVoiceLanguageAuto => '自动检测';

  @override
  String get prefsVoiceFooter => '录音无需模型——备忘录始终以音频形式存储，并像其他附件一样回放。模型只是额外生成文字。';

  @override
  String get prefsVoiceGroupCheck => '检测';

  @override
  String get prefsVoiceCheckIntro => '使用上面的设备和模型录制几秒钟，回放并转写。不会保存任何内容。';

  @override
  String get prefsVoiceStop => '停止';

  @override
  String get prefsVoiceTestAgain => '再次测试';

  @override
  String get prefsVoiceCheckRecording => '正在录音——说一句话，然后按“停止”。';

  @override
  String get prefsVoiceCheckPlaying => '正在回放…';

  @override
  String get prefsVoiceCheckTranscribing => '正在转写…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return '正在转写… $percent%';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return '已录制 $duration。';
  }

  @override
  String get prefsVoiceCheckFailed => '检测未完成。';

  @override
  String get prefsVoiceDownloading => '正在下载…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$size 的 $percent%';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return '$model 已下载，可以使用。';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return '未下载 — 从 HuggingFace 下载 $size。';
  }

  @override
  String get prefsCheckBusy => '正在录制语音备忘录。请先完成录制。';

  @override
  String get prefsCheckPermissionRefused => '麦克风权限被拒绝。';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return '无法打开麦克风：$error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return '录音失败：$error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return '无法完成录音：$error';
  }

  @override
  String get prefsCheckNothingRecorded => '未录到任何内容。请让测试持续得稍长一些，或选择其他麦克风。';

  @override
  String get prefsCheckMalformed => '录音数据格式错误，无法播放。';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return '播放失败：$error';
  }

  @override
  String get prefsCheckNoModel => '录音和回放正常。未选择模型，因此没有可转写的内容。';

  @override
  String prefsCheckModelMissing(String model) {
    return '录音和回放正常。$model 尚未下载，因此未进行转写。';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return '转写失败：$error';
  }

  @override
  String get prefsCheckSilence =>
      '麦克风没有声音——电平表始终没有变化。请检查是否选择了正确的设备，以及应用是否有权使用它。';

  @override
  String get prefsCheckNoSpeech => '录音和回放正常，但 whisper 未检测到语音。请靠近麦克风说话，或尝试其他语言。';

  @override
  String get prefsCheckQuiet => '电平表始终没有变化，输入音量非常低。';

  @override
  String get prefsDownloadCancelled => '下载已取消。';

  @override
  String prefsDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get prefsUntitled => '（无标题）';

  @override
  String get prefsMcpTokenSessionOnly =>
      '仅为本次会话保存：系统钥匙串拒绝了它。如果你的密钥环已锁定，请解锁后按“重新生成”。';

  @override
  String get prefsMcpRegenerateTitle => '重新生成令牌？';

  @override
  String get prefsMcpRegenerateBody => '使用当前令牌配置的代理将停止工作，直到你将新令牌粘贴到它们的设置中。';

  @override
  String get prefsMcpRegenerate => '重新生成';

  @override
  String get prefsMcpGroupAccess => '代理访问';

  @override
  String get prefsMcpEnable => '启用 MCP 服务器';

  @override
  String get prefsMcpEnableHint => '允许本地 AI 编程代理通过 127.0.0.1 读取此大纲。默认关闭。';

  @override
  String get prefsMcpReadOnly => '只读';

  @override
  String get prefsMcpReadOnlyHint => '代理可以搜索和读取任务，但不能创建、更改、移动或删除任务。';

  @override
  String get prefsMcpGroupEndpoint => '端点';

  @override
  String get prefsMcpPort => '端口';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => '复制 URL';

  @override
  String get prefsMcpToken => '令牌';

  @override
  String get prefsMcpTokenHint => '任何能以你的身份运行程序的人都可以使用此令牌。请像对待密码一样对待它。';

  @override
  String get prefsMcpNoTokenYet => '尚无令牌 — 启用服务器以创建令牌';

  @override
  String get prefsMcpShowToken => '显示令牌';

  @override
  String get prefsMcpHideToken => '隐藏令牌';

  @override
  String get prefsMcpCopyToken => '复制令牌';

  @override
  String get prefsMcpCopied => '已复制。';

  @override
  String get prefsMcpGroupExcluded => '排除的分支';

  @override
  String get prefsMcpExcludedIntro => '对 MCP 服务器隐藏的任务，以及其下的所有内容。';

  @override
  String get prefsMcpLoading => '正在加载…';

  @override
  String get prefsMcpOutlineReadError => '无法读取大纲。';

  @override
  String get prefsMcpChoose => '选择…';

  @override
  String get prefsMcpNothingExcluded => '未排除任何内容 — 代理可以看到整个大纲。';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '等另外 $count 个',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return '正在监听 $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return '端口 $port 不可用。请选择其他端口。';
  }

  @override
  String get prefsMcpNoAccessToken => '没有访问令牌。按“重新生成”以创建一个。';

  @override
  String get prefsMcpWaitingDatabase => '正在等待打开数据库。';

  @override
  String get prefsMcpNotRunning => '未运行。';

  @override
  String prefsMcpLastRequest(String time) {
    return '上次请求 $time';
  }

  @override
  String get prefsMcpNoRequests => '尚无请求';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已拒绝 $count 个（令牌错误或缺失）',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<请先启用服务器>';

  @override
  String get prefsMcpGroupSetup => '设置你的代理';

  @override
  String get prefsMcpClient => '客户端';

  @override
  String get prefsMcpStdioBridge => '仅支持 stdio 的代理可以通过以下命令桥接：';

  @override
  String get prefsMcpTargetTerminal => '在终端中运行：';

  @override
  String prefsMcpTargetFile(String file) {
    return '添加到 $file：';
  }

  @override
  String get prefsMcpNoteClaudeCode => '作用范围为你的用户，因此每个项目中都可使用此大纲。';

  @override
  String get prefsMcpNoteCodex =>
      '若不想把令牌写在文件中，可将 http_headers 替换为 bearer_token_env_var = \"NOO_MCP_TOKEN\"，并在 shell 中设置该变量。';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false 很重要——没有它，OpenCode 会把此服务器的 401 当作开始 OAuth 注册的邀请，而该注册无法完成。';

  @override
  String get prefsMcpExcludedDialogIntro =>
      '勾选的任务及其下的所有内容将对 MCP 服务器隐藏——代理无法读取或更改它，也无法删除任何包含它的内容。';

  @override
  String get prefsMcpNoDatabase => '未打开数据库。';

  @override
  String get prefsMcpNoTasks => '此大纲还没有任务。';

  @override
  String get prefsMcpCollapse => '折叠';

  @override
  String get prefsMcpExpand => '展开';

  @override
  String get prefsMcpHiddenWithParent => '随上级隐藏';

  @override
  String get syncGroupSynchronization => '同步';

  @override
  String get syncEnable => '启用同步';

  @override
  String get syncEnableHint => '让此数据库与服务器保持同步';

  @override
  String get syncGroupIdentity => '身份';

  @override
  String get syncNeedsUserName => '输入用户名以开始同步。没有用户名就无法同步——无论是否使用服务器。';

  @override
  String get syncUserName => '用户名';

  @override
  String get syncUserNameHint =>
      '在你的每台设备上都相同。它与数据库密码一起派生加密密钥，因此只有两者都一致时设备才会同步。';

  @override
  String get syncDeviceName => '设备名称';

  @override
  String get syncDeviceNameHint => '此设备向附近设备展示的名称';

  @override
  String get syncGroupServer => '同步服务器（可选）';

  @override
  String get syncServerIntro =>
      '留空则仅与同一网络中的附近设备同步。服务器还能让不在一起的设备同步；它存储的是它无法读取的加密数据。';

  @override
  String get syncServerUrl => '服务器 URL';

  @override
  String get syncServerPassword => '密码';

  @override
  String get syncServerPasswordHint => '你在服务器上的账户密码。不是数据库密码，也绝不会用作加密密钥。';

  @override
  String get syncTestConnection => '测试连接';

  @override
  String get syncRegister => '注册';

  @override
  String get syncGroupSchedule => '计划';

  @override
  String get syncScheduleNeedsServer =>
      '启动和退出时同步需要服务器。同一网络中的设备会在你要求时同步，方法是选择“工具 → P2P 同步...”。';

  @override
  String get syncAutosyncOnStart => '启动时自动同步';

  @override
  String get syncAutosyncOnStartHint => '应用打开数据库时进行同步';

  @override
  String get syncCheckOnStart => '启动时检查传入的更改';

  @override
  String get syncCheckOnStartHint =>
      '询问服务器其他设备是否发来了更改（不进行同步），并在同步图标上显示。开启“启动时自动同步”时无需此项';

  @override
  String get syncAskOnExit => '退出时询问是否同步';

  @override
  String get syncAskOnExitHint => '应用关闭前提示同步待同步的更改';

  @override
  String get syncGroupServerStorage => '服务器存储';

  @override
  String get syncGroupPeerToPeer => '点对点';

  @override
  String get syncPeerToPeerIntro =>
      '同一网络中使用相同用户名和数据库密码的设备可以直接同步——无需服务器。在每台设备上打开“工具 → P2P 同步...”：窗口打开期间它们会互相发现并同步，否则不可被发现。';

  @override
  String get syncStorageNoServer => '在此设置下，服务器上不存储任何内容。点对点同步将所有数据包保存在设备本身。';

  @override
  String get syncStorageIntro => '服务器会保留所做过的每一处加密更改，因此其大小随编辑次数增长，而不是随大纲的大小增长。';

  @override
  String get syncStorageReading => '正在读取…';

  @override
  String get syncStoragePressRefresh => '按“刷新”以读取当前用量。';

  @override
  String get syncStorageEmpty => '服务器上尚未存储任何内容。';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size，共 $count 个数据包',
      one: '$size，共 1 个数据包',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return '计数器 $first–$last';
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
      other: '计数器 $first–$last，$snapshots 个快照',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '另有 $count 个附件（$size），各仅存储一次，由所有引用它们的数据包共享。',
      one: '另有 1 个附件（$size），仅存储一次，由所有引用它的数据包共享。',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备在本地保存了其中 $count 个（$size）。',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => '压缩服务器上的数据';

  @override
  String get syncResetIdentity => '重置设备身份';

  @override
  String get syncNotConfiguredOnDevice => '此设备上尚未配置同步。';

  @override
  String syncStorageReadFailed(String error) {
    return '无法读取服务器存储：$error';
  }

  @override
  String get syncResetConfirm =>
      '此设备将以新身份开始同步，下次同步时会发布当前数据库的完整副本。你的其他设备会正常合并它——不会丢失任何内容。\n\n当同步报告此设备的历史已出现分歧时执行此操作，这通常意味着此数据库在同步之后又从备份中恢复过。\n\n在执行压缩之前，旧身份会一直出现在服务器的存储列表中。';

  @override
  String get syncReset => '重置';

  @override
  String syncResetFailed(String error) {
    return '无法重置设备身份：$error';
  }

  @override
  String get syncCompactConfirm =>
      '此设备将先同步，然后上传整个数据库的一个快照。之后服务器会删除该快照已包含的所有已存储更改，其他设备在获取快照时也会这样做。\n\n你的笔记、时间和附件不受影响——被丢弃的是快照之前每一次编辑的记录。\n\n请先在其他设备上更新 Noo：旧版本无法读取开头已被删除的数据流。';

  @override
  String get syncCompact => '压缩';

  @override
  String get syncCompactFailed => '压缩失败。';

  @override
  String get syncCompactNothing => '暂时没有可压缩的内容。';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '在服务器上释放了 $size（$count 个数据包）',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported => '快照已上传，但此服务器尚不支持压缩，因此保留了它的副本';

  @override
  String get syncCompactRelayNothing => '快照已上传；服务器上已没有可删除的内容';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备释放了 $size（$count 个数据包）',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay。$local。快照本身为 $size。';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay。快照本身为 $size。';
  }

  @override
  String get syncTestSuccess => '成功：服务器可以访问';

  @override
  String get syncTestUnreachable => '错误：无法访问服务器';

  @override
  String syncErrorWith(String error) {
    return '错误：$error';
  }

  @override
  String get syncRegisterNeedsCredentials => '错误：需要用户名和密码';

  @override
  String syncRegisterSuccess(String user) {
    return '成功：已创建账户“$user”。设置已保存。';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return '成功：已创建账户“$user”，服务器存储空间不限。设置已保存。';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return '成功：已创建账户“$user”，服务器存储空间为 $size。设置已保存。';
  }

  @override
  String get syncStagePreparing => '准备';

  @override
  String get syncStageAuthenticating => '验证凭据';

  @override
  String get syncStagePushing => '推送更改';

  @override
  String get syncStageApplying => '应用更改';

  @override
  String get syncStatePending => '等待中';

  @override
  String get syncStateActive => '进行中…';

  @override
  String get syncStateDone => '完成';

  @override
  String get syncStateSkipped => '已跳过';

  @override
  String get syncStateFailed => '失败';

  @override
  String get syncCancelling => '正在取消…';

  @override
  String get syncSynchronizing => '正在同步…';

  @override
  String get syncCancelled => '同步已取消';

  @override
  String get syncFailed => '同步失败';

  @override
  String get syncTitle => '同步';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncShowFullLogTooltip => '显示完整日志';

  @override
  String get syncShowFullLog => '显示完整日志';

  @override
  String get syncMoreSeeFullLog => '请查看“显示完整日志”';

  @override
  String get syncGroupProgress => '进度';

  @override
  String get syncNoRunYet => '尚未进行过同步。使用“立即同步”进行同步；上次同步的详细信息将显示在这里。';

  @override
  String get syncCancelledNote => '已按你的要求停止。在此之前已同步的内容都会保留；下次同步将从那里继续。';

  @override
  String get syncGroupSummary => '摘要';

  @override
  String get syncChangesPushed => '已推送的更改';

  @override
  String get syncChangesApplied => '已应用的更改';

  @override
  String get syncGroupApplied => '已应用 — 来自其他设备';

  @override
  String get syncGroupPushed => '已推送 — 来自此设备';

  @override
  String get syncGroupLwwSkipped => '未应用 — 此设备已有更新的值';

  @override
  String get syncGroupUnreadable => '无法读取';

  @override
  String get syncLwwTieNote =>
      '时间戳完全相同时，两台设备各自保留原值，因此两者仍然不同。请在你想保留其版本的设备上再次编辑该项。';

  @override
  String get syncLwwOlderNote => '传入的值比此设备上的旧，因此未写入。如果它本应胜出，请检查两台设备的时钟是否一致。';

  @override
  String get syncSkewSame => '时间戳相同';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '本地快 $seconds 秒',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return '本地快 $minutes 分 $seconds 秒';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return '本地快 $hours 小时 $minutes 分';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '本地快 $days 天',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return '传入 $incoming · 本地 $local（$skew）';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage 失败  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      '这些数据包无法解密，这意味着此数据库的密码与写入它们的设备上的密码不同。同步不会重试它们：请让密码一致，然后在另一台设备上重新保存受影响的项，以便再次发送。';

  @override
  String get syncSkippedUnreadableNote =>
      '这些数据包无法读取，同步已跳过它们——其中的更改不会自行到达。请在另一台设备上重新保存受影响的项以再次发送。';

  @override
  String get syncP2pNotConfigured => '尚未配置同步。请先在“首选项 → 同步”中设置用户名。';

  @override
  String syncP2pStartFailed(String error) {
    return '无法启动点对点同步：$error';
  }

  @override
  String get syncP2pStarting => '正在启动...';

  @override
  String get syncP2pLooking => '正在查找此网络中的设备...';

  @override
  String get syncP2pIntro =>
      '也请在另一台设备上打开“P2P 同步...”。设备一旦互相发现就会同步；关闭此窗口后它们将不再可见。';

  @override
  String get syncP2pTitle => 'P2P 同步';

  @override
  String get syncP2pSyncAgain => '再次同步';

  @override
  String get syncP2pFound => '已发现 — 等待同步';

  @override
  String get syncP2pSyncing => '正在同步...';

  @override
  String get syncP2pUpToDate => '已同步 — 已是最新';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已同步 — 收到 $count 处更改',
      one: '已同步 — 收到 1 处更改',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return '失败 — $error';
  }

  @override
  String get syncP2pUnknownError => '未知错误';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return '从 $device 接收（$count）';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return '发送到 $device（$count）';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '已用 $used / $quota（$percent%）';
  }

  @override
  String get syncQuotaSemantics => '已用服务器存储空间';

  @override
  String get syncQuotaFull => '已满：在你压缩数据或移除附件之前，服务器将拒绝新的更改。';

  @override
  String get syncQuotaNearlyFull => '即将用满。压缩通常可以释放大部分空间。';

  @override
  String get syncNotConfiguredOpenSettings => '尚未配置同步。请先打开同步设置。';

  @override
  String get syncNoServerConfigured =>
      '未配置同步服务器。请使用“P2P 同步...”进行本地同步，或在“首选项 → 同步”中添加服务器。';

  @override
  String get syncAlreadyInProgress => '同步已在进行中';

  @override
  String get syncAlreadyInProgressSentence => '同步已在进行中。';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done / $totalText 处更改',
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
      other: '$countText 处更改 · 数据包 $current / $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText 处更改',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · 约剩 $seconds 秒';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · 约剩 $minutes 分钟';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return '检测到设备数据流分叉：某个远程节点保存了此设备的数据包计数器 $remote，但此设备处于 $local，且无法确认两者此前的内容一致（数据库是否从备份中恢复过？）。请在“首选项 → 同步”中使用“重置设备身份”以恢复同步。';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return '设备数据流在数据包计数器 $counter 处出现分歧：此设备与 $source 在同一身份下保存了不同的内容（此处为 $localHash，对方为 $remoteHash）。此数据库很可能是从备份中恢复的，并重复使用了已发布过的数据包编号。请在“首选项 → 同步”中使用“重置设备身份”以恢复同步；它会以新身份重新发布此数据库，不会丢失任何内容。';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return '服务器缺少此设备的部分历史：它期望下一个数据包为 #$expected，但此设备仍保存的最早数据包为 #$local，中间的数据包已不存在（服务器很可能在此设备压缩后从较旧的备份中恢复过）。请在“首选项 → 同步”中使用“重置设备身份”以恢复同步；它会以新身份重新发布此数据库，不会丢失任何内容。';
  }

  @override
  String get syncIdentityReset =>
      '此设备现在以新身份同步。下次同步时将发布当前数据库的完整副本，其他所有设备会正常合并它。';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备现在以新身份同步。下次同步时将发布当前数据库的完整副本，其他所有设备会正常合并它。已丢弃 $count 个不可用的数据包。',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => '正在派生加密密钥';

  @override
  String get syncDetailSignedIn => '已登录';

  @override
  String get syncDetailPackaging => '正在打包本地更改';

  @override
  String get syncDetailRecovering => '正在恢复此设备自身的历史';

  @override
  String get syncDetailUploading => '正在上传到服务器';

  @override
  String get syncDetailNoLocalChanges => '没有本地更改';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已推送 $count 处更改',
      one: '已推送 1 处更改',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => '正在下载远程更改';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已下载 $count 个附件',
      one: '已下载 1 个附件',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '还有 $count 个附件待下载',
      one: '还有 1 个附件待下载',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => '已是最新';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已应用 $count 处更改',
      one: '已应用 1 处更改',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => '已取消';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return '附件“$name”尚未下载到此设备，而此设备所做的某处更改引用了它，因此在它到达之前，此设备的更改无法到达服务器——等它到达后请再次同步，或与保存了它的附近设备同步。';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return '服务器以过大为由拒绝了附件“$name”（$size）。其他内容均会同步；该附件本身只能通过 P2P 同步到达其他设备。';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return '服务器以过大为由拒绝了附件“$name”（$size）（上限为 $limit）。其他内容均会同步；该附件本身只能通过 P2P 同步到达其他设备。';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return '附件“$name”（$size）超出了你的服务器存储空间。其他内容均会同步；请压缩服务器上的数据或移除大型附件以腾出空间，在此之前该附件只能通过 P2P 同步到达其他设备。';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return '附件“$name”（$size）超出了你的服务器存储空间（已用 $used / $quota）。其他内容均会同步；请压缩服务器上的数据或移除大型附件以腾出空间，在此之前该附件只能通过 P2P 同步到达其他设备。';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 字节',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      '未配置同步服务器。压缩会将快照发布到中继服务器；仅使用附近设备同步时，没有可回收的中继存储空间。';

  @override
  String get syncCompactStageSyncing => '压缩前同步';

  @override
  String get syncCompactStageChecking => '检查此设备是否为最新';

  @override
  String get syncCompactStagePackaging => '打包整个数据库的快照';

  @override
  String get syncCompactStageAttachments => '上传快照引用的附件';

  @override
  String get syncCompactStageUploading => '上传快照';

  @override
  String get syncCompactStageReclaiming => '回收此设备上的空间';

  @override
  String get syncCompactStageReadingUsage => '读取中继服务器存储';

  @override
  String syncCompactNeedsSync(String error) {
    return '压缩前需要先完成一次同步：$error';
  }

  @override
  String get syncCompactDidNotFinish => '压缩未完成。';

  @override
  String get syncCompactRaced => '另一次同步先完成了打包。请再次尝试压缩。';

  @override
  String get syncCompactSnapshotMissing => '快照已打包，但不在本地存储中。';

  @override
  String get syncCompactMissingAttachments => '此设备仍缺少部分附件。请同步直到所有附件都已下载，然后再压缩。';

  @override
  String syncCompactRelayRefused(String error) {
    return '中继服务器拒绝了快照：$error';
  }

  @override
  String syncCompactError(String error) {
    return '压缩失败：$error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '此设备无法读取 $count 个数据包（$packets），因此其状态并非日志中所有内容的合并结果。压缩将丢弃此设备从未应用过的数据包。',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced => '此设备仍有未同步的编辑。请先同步，然后再压缩。';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '此设备仍缺少部分附件（$count 个待下载），因此其快照无法提供它们，服务器会将其删除。请同步直到所有附件都已下载，然后再压缩。',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '此设备尚未应用它为 $count 台设备保存的全部内容。请再次同步，然后再压缩。',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay => '仅使用附近设备同步时，无法保证其他设备仍保存着已删除的附件，因此未释放任何附件。';

  @override
  String get syncCollectUnsynced => '此设备有服务器尚未存储的更改。请先同步，然后再压缩。';

  @override
  String syncSummarySnapshotOf(String device) {
    return '$device 的快照';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个字段 — 整个数据库',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return '节点“$name”';
  }

  @override
  String syncSummaryFile(String name) {
    return '文件“$name”';
  }

  @override
  String get syncSummaryFileFallback => '文件';

  @override
  String get syncSummaryTimeChunk => '时间段';

  @override
  String syncSummaryRenamedTo(String title) {
    return '重命名为“$title”';
  }

  @override
  String get syncSummaryContentEdited => '内容已编辑';

  @override
  String get syncSummaryMoved => '已移动';

  @override
  String get syncSummaryReordered => '已重新排序';

  @override
  String get syncSummaryFlagsChanged => '标志已更改';

  @override
  String get syncSummaryRenamed => '已重命名';

  @override
  String get syncSummaryContentUpdated => '内容已更新';

  @override
  String syncSummaryFrom(String time) {
    return '从 $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return '至 $time';
  }

  @override
  String get syncValueTopLevel => '顶级';

  @override
  String get syncStorageFull =>
      '服务器存储空间已满。请压缩服务器上的数据（首选项 → 同步 → 服务器存储）或移除大型附件；尚未上传的内容会保留在此设备上。';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return '服务器存储空间已满（已用 $used / $quota）。请压缩服务器上的数据（首选项 → 同步 → 服务器存储）或移除大型附件；尚未上传的内容会保留在此设备上。';
  }

  @override
  String syncStorageStreams(String detail) {
    return '服务器拒绝为此账户再添加一个设备数据流：$detail';
  }

  @override
  String get syncStorageServerDisk => '服务器磁盘空间不足。没有丢失任何内容；请稍后再同步。';

  @override
  String syncStorageRefused(String detail) {
    return '服务器拒绝存储更多内容：$detail';
  }

  @override
  String get syncRegAccountLimit => '此服务器不再接受新账户：已达到账户数量上限。';

  @override
  String get syncRegClosed => '此服务器不接受注册。请向其运营者申请账户。';

  @override
  String get syncRegTaken => '该用户名已被占用。';

  @override
  String get syncRegInvalid => '用户名必须为 3–50 个字符，服务器密码必须为 8–128 个字符。';

  @override
  String get syncRegTooManyFromNetwork => '今天从此网络注册的账户过多。';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return '今天从此网络注册的账户过多。请在 $wait后重试。';
  }

  @override
  String get syncRegTooManyAttempts => '尝试次数过多。';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return '尝试次数过多。请在 $wait后重试。';
  }

  @override
  String get syncRegBusy => '服务器繁忙。请稍后重试。';

  @override
  String syncRegFailed(int status) {
    return '注册失败（HTTP $status）';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return '注册失败（HTTP $status）：$detail';
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
      other: '$count 分钟',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 小时',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return '$host 在 $seconds 秒内无响应';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return '来自 $host 的响应停滞了 $seconds 秒';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…另有 $count 项 — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => '请查看同步日志';

  @override
  String get traceAtTopLevel => '位于顶级';

  @override
  String traceInPath(String path) {
    return '位于 $path';
  }

  @override
  String get traceRowNew => '（新）';

  @override
  String get traceRowRemoved => '（已移除）';

  @override
  String get traceShowHowTooltip => '显示此更改是如何发生的';

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
  String get traceDecisionApplied => '已应用';

  @override
  String get traceDecisionCreated => '在此创建';

  @override
  String get traceDecisionConflictCopy => '已应用 — 被替换的值保留为冲突副本';

  @override
  String get traceDecisionMerged => '已与此处的编辑合并 — 两处更改均保留';

  @override
  String get traceDecisionCycleToRoot => '已移到顶级 — 其父项会造成循环';

  @override
  String get traceDecisionParentMissing => '在其父项到达之前暂放在顶级';

  @override
  String get traceDecisionBlobPending => '已应用 — 附件数据随后单独传输';

  @override
  String get traceDecisionSent => '已发送';

  @override
  String get traceDecisionForwarded => '已转发';

  @override
  String get traceRouteRelay => '从中继服务器下载。';

  @override
  String traceRouteRelayStored(String time) {
    return '从中继服务器下载，服务器于 $time 存储了它。';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return '由 $peer 通过本地网络转发 — 由 $author 写入。';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return '通过本地网络直接来自 $peer。';
  }

  @override
  String get traceRouteStoredEarlier => '在之前的交换中已存在于此设备上；在本次交换中应用。';

  @override
  String traceRouteStoredAt(String time) {
    return '已存在于此设备上 — 于 $time 接收；在本次交换中应用。';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return '已存在于此设备上 — 于 $time 从 $source 接收；在本次交换中应用。';
  }

  @override
  String get traceRoutePackagedUploaded => '在此打包并上传到中继服务器。';

  @override
  String get traceRoutePackagedAlreadyHeld => '在此打包；中继服务器已从其他途径获得。';

  @override
  String get traceRoutePackagedBlocked => '在此打包；尚未上传 — 它所需的某个附件无法上传。';

  @override
  String get traceRoutePackagedWaiting => '在此打包；等待中继服务器或对等设备获取。';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return '由 $peer 通过本地网络拉取 — 代表 $author 转发。';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return '由 $peer 通过本地网络拉取。';
  }

  @override
  String get traceBlobDownloaded => '刚刚下载';

  @override
  String traceBlobDownloadedSized(String size) {
    return '刚刚下载（$size）';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return '刚刚从 $source 下载';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return '刚刚从 $source 下载（$size）';
  }

  @override
  String get traceBlobWaiting => '尚未下载 — 将在之后的同步或打开时获取';

  @override
  String get traceBlobHeld => '已在此设备上';

  @override
  String get traceBlobUploaded => '已上传到中继服务器';

  @override
  String traceBlobUploadedSized(String size) {
    return '已上传到中继服务器（$size）';
  }

  @override
  String get traceBlobOnRelay => '中继服务器上已有';

  @override
  String get traceBlobOffered => '在此设备上，供其他设备获取';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return '压缩快照：$device 的整个数据库，位于一个数据包中。';
  }

  @override
  String traceSnapshotPart(String device) {
    return '来自 $device 的完整状态快照的一部分。快照包含作者的整个数据库；列出此项是因为它与此处不同。';
  }

  @override
  String get traceFieldsHeading => '字段';

  @override
  String traceTimeEdited(String time) {
    return '编辑于 $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return '对方 $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return '此设备 $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return '数据包 $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return '数据包 $device #$counter（快照）';
  }

  @override
  String tracePacketWritten(String time) {
    return '写入于 $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 处更改',
      one: '1 处更改',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return '作者设备 $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return '来自设备 $id';
  }

  @override
  String get traceCopyHashTooltip => '复制数据包哈希';

  @override
  String get traceAttachmentBytesHeading => '附件数据';

  @override
  String get traceShowInSyncLog => '在同步日志中显示';

  @override
  String get traceTriggerRelay => '服务器同步';

  @override
  String get traceTriggerCheck => '检查传入的更改';

  @override
  String get traceTriggerLan => '附近设备';

  @override
  String get traceTriggerLanReturn => '附近设备（请求）';

  @override
  String get traceTriggerLanServe => '提供给附近设备';

  @override
  String get traceTriggerPackage => '打包本地更改';

  @override
  String get traceTriggerCompaction => '压缩';

  @override
  String get traceTriggerIdentityReset => '设备身份重置';

  @override
  String get traceTriggerAttachment => '附件下载';

  @override
  String get traceTriggerBlobCollect => '附件清理';

  @override
  String get traceOutcomeRunning => '运行中';

  @override
  String get traceOutcomeFailed => '失败';

  @override
  String get traceOutcomeDeclined => '已拒绝';

  @override
  String get traceOutcomeBusy => '忙碌';

  @override
  String get traceOutcomeInterrupted => '已中断';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已将 $count 个事件复制为 JSON',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => '清除同步日志？';

  @override
  String get traceClearBody => '此设备上记录的所有运行和事件都将被删除。已同步的数据不受影响。';

  @override
  String get traceTitle => '同步日志';

  @override
  String get traceCopyAsJson => '复制为 JSON';

  @override
  String get traceClearLogTooltip => '清除日志';

  @override
  String get traceClearLogButton => '清除日志';

  @override
  String traceSummaryApplied(int count) {
    return '已应用 $count 处';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个警告',
      one: '1 个警告',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个错误',
      one: '1 个错误',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => '未交换任何内容';

  @override
  String get traceNoRuns => '尚未记录任何同步。此设备与服务器或附近设备同步时，运行记录会显示在这里。';

  @override
  String get traceAllRuns => '所有运行';

  @override
  String traceRunsRecorded(int count) {
    return '已记录 $count 次';
  }

  @override
  String traceAllRunsCount(int count) {
    return '所有运行（$count）';
  }

  @override
  String get traceRunLabel => '运行';

  @override
  String get traceSearchHint => '搜索：节点名称、ID、哈希、设备、类型…';

  @override
  String get traceLevelAll => '全部';

  @override
  String get traceLevelWarnings => '警告';

  @override
  String get traceLevelErrors => '错误';

  @override
  String get traceDirectionAll => '传入和传出';

  @override
  String get traceDirectionIncoming => '传入';

  @override
  String get traceDirectionOutgoing => '传出';

  @override
  String get traceDirectionLocal => '本地';

  @override
  String get traceNoEvents => '没有匹配的事件。';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '显示前 $count 个事件。缩小搜索范围或选择一次运行以查看其余事件。',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return '运行 #$id';
  }

  @override
  String get traceEmptyValue => '（空）';

  @override
  String traceSubHash(String hash) {
    return '哈希 $hash';
  }

  @override
  String traceSubValue(String hash) {
    return '值 $hash';
  }

  @override
  String traceSubRemote(String time) {
    return '远程 $time';
  }

  @override
  String traceSubLocal(String time) {
    return '本地 $time';
  }

  @override
  String get traceDetailAt => '时间';

  @override
  String get traceDetailDirection => '方向';

  @override
  String get traceDetailOriginDevice => '来源设备';

  @override
  String get traceDetailCounter => '计数器';

  @override
  String get traceDetailHash => '数据包 / blob 哈希';

  @override
  String get traceDetailEntity => '实体';

  @override
  String get traceDetailWorldId => 'World ID';

  @override
  String get traceDetailName => '名称';

  @override
  String get traceDetailField => '字段';

  @override
  String get traceDetailRemoteTs => '远程时间戳';

  @override
  String get traceDetailLocalTs => '本地时间戳';

  @override
  String get traceDetailValueHash => '值哈希';

  @override
  String get traceDetailValuePreview => '值预览';

  @override
  String get traceDetailMessage => '消息';

  @override
  String get traceDetailDetail => '详细信息';
}
