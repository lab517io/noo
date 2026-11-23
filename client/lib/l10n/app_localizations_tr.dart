// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appMenuFile => 'Dosya';

  @override
  String get appMenuEdit => 'Düzen';

  @override
  String get appMenuView => 'Görünüm';

  @override
  String get appMenuTools => 'Araçlar';

  @override
  String get appMenuDebug => 'Hata ayıklama';

  @override
  String get appMenuHelp => 'Yardım';

  @override
  String get appMenuWindow => 'Pencere';

  @override
  String get appMenuOpen => 'Aç...';

  @override
  String get appMenuOpenDatabase => 'Veritabanı aç...';

  @override
  String get appMenuNewDatabase => 'Yeni veritabanı...';

  @override
  String get appMenuExportObsidian => 'Obsidian\'a aktar...';

  @override
  String get appMenuImportObsidian => 'Obsidian\'dan içe aktar...';

  @override
  String get appMenuExit => 'Çıkış';

  @override
  String get appMenuFind => 'Bul...';

  @override
  String get appMenuTheme => 'Tema';

  @override
  String get appMenuThemeEllipsis => 'Tema...';

  @override
  String get appThemeSystem => 'Sistem';

  @override
  String get appThemeLight => 'Açık';

  @override
  String get appThemeDark => 'Koyu';

  @override
  String get appMenuTimeline => 'Zaman çizelgesi...';

  @override
  String get appMenuTimeReport => 'Zaman raporu...';

  @override
  String get appMenuCompactDatabase => 'Veritabanını sıkıştır...';

  @override
  String get appMenuSyncNow => 'Şimdi eşitle';

  @override
  String get appMenuSyncP2p => 'P2P eşitle...';

  @override
  String get appMenuPreferences => 'Tercihler...';

  @override
  String get appMenuViewChangeHistory => 'Değişiklik geçmişini görüntüle...';

  @override
  String get appMenuGenerateTestData => 'Test verisi oluştur';

  @override
  String get appMenuGenerateLargeDataset => 'Büyük veri kümesi oluştur';

  @override
  String get appMenuClearAllData => 'Tüm verileri temizle';

  @override
  String get appMenuCheckForUpdate => 'Güncellemeleri denetle...';

  @override
  String get appMenuLogs => 'Günlükler';

  @override
  String get appMenuSyncLog => 'Eşitleme günlüğü...';

  @override
  String get appMenuAppLog => 'Uygulama günlüğü...';

  @override
  String appMenuAbout(String appName) {
    return '$appName hakkında';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Güncellemeleri denetle…';

  @override
  String get appMacMenuSettings => 'Ayarlar…';

  @override
  String appMacMenuQuit(String appName) {
    return '$appName uygulamasından çık';
  }

  @override
  String get appMacMenuOpen => 'Aç…';

  @override
  String get appMacMenuNewDatabase => 'Yeni veritabanı…';

  @override
  String get appMacMenuExportObsidian => 'Obsidian\'a aktar…';

  @override
  String get appMacMenuImportObsidian => 'Obsidian\'dan içe aktar…';

  @override
  String get appMacMenuUndo => 'Geri al';

  @override
  String get appMacMenuRedo => 'Yinele';

  @override
  String get appMacMenuCut => 'Kes';

  @override
  String get appMacMenuPaste => 'Yapıştır';

  @override
  String get appMacMenuSelectAll => 'Tümünü seç';

  @override
  String get appMacMenuFind => 'Bul…';

  @override
  String get appMacMenuTimeline => 'Zaman çizelgesi…';

  @override
  String get appMacMenuTimeReport => 'Zaman raporu…';

  @override
  String get appMacMenuCompactDatabase => 'Veritabanını sıkıştır…';

  @override
  String get appMacMenuSyncP2p => 'P2P eşitle…';

  @override
  String get appMacMenuViewChangeHistory => 'Değişiklik geçmişini görüntüle…';

  @override
  String get appMacMenuSyncLog => 'Eşitleme günlüğü…';

  @override
  String get appMacMenuAppLog => 'Uygulama günlüğü…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Veritabanı aç';

  @override
  String get appCreateDatabaseDialogTitle => 'Yeni veritabanı oluştur';

  @override
  String get appIncorrectPasswordRetry =>
      'Parola yanlış. Lütfen yeniden deneyin.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Açıldı: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Veritabanı açılamadı: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Oluşturuldu: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Veritabanı oluşturulamadı: $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Önce bir veritabanı açın';

  @override
  String get appNoDatabaseOpen => 'Açık veritabanı yok';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Veritabanı dosyası okunamıyor: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt => 'Parola yanlış veya veritabanı bozuk';

  @override
  String get appExportObsidianDialogTitle => 'Obsidian dizinine aktar';

  @override
  String get appImportObsidianDialogTitle => 'Obsidian dizininden içe aktar';

  @override
  String get appImportObsidianZipDialogTitle =>
      'Obsidian .zip dosyasını içe aktar';

  @override
  String get appExportingObsidian => 'Obsidian biçimine aktarılıyor...';

  @override
  String get appImportingObsidian => 'Obsidian biçiminden içe aktarılıyor...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görev',
      one: '$count görev',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zaman çizelgesi dosyası',
      one: '$count zaman çizelgesi dosyası',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count görsel',
      one: '$count görsel',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zaman kaydı',
      one: '$count zaman kaydı',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Dışa aktarıldı: $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'İçe aktarıldı: $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String appImportFailed(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Obsidian dışa aktarımı ($count görev)',
      one: 'Obsidian dışa aktarımı ($count görev)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'Dizin mevcut değil: $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Eşitleme yapılandırılmamış. Önce eşitleme ayarlarını açın.';

  @override
  String get appNoSyncServer =>
      'Eşitleme sunucusu yapılandırılmamış. P2P eşitle... (Shift+F5) komutunu kullanın veya Tercihler\'den bir sunucu ekleyin.';

  @override
  String get appUnsyncedChangesTitle => 'Eşitlenmemiş değişiklikler';

  @override
  String get appUnsyncedChangesBody =>
      'Eşitlenmemiş değişiklikler var; eşitlemek istiyor musunuz?';

  @override
  String get appDontSync => 'Eşitleme';

  @override
  String get appSync => 'Eşitle';

  @override
  String get appSelectTaskFirst => 'Önce bir görev seçin';

  @override
  String get appGenerateTestDataBody =>
      'Bu işlem hiyerarşisi ve zaman kayıtları olan örnek görevler oluşturur.\n\nDevam edilsin mi?';

  @override
  String get appGenerate => 'Oluştur';

  @override
  String get appTestDataGenerated => 'Test verisi başarıyla oluşturuldu';

  @override
  String get appGenerateLargeDatasetBody =>
      'Bu işlem şunları içeren büyük bir veri kümesi oluşturur:\n- 20 üst düzey görev\n- En fazla 5 düzey derinlik\n- Görev başına en fazla 6 alt görev\n- Birçok görev için zaman kayıtları\n\nBu biraz zaman alabilir. Devam edilsin mi?';

  @override
  String get appGeneratingData => 'Veri oluşturuluyor...';

  @override
  String get appLargeDatasetGenerated =>
      'Büyük veri kümesi başarıyla oluşturuldu';

  @override
  String get appClearAllDataBody =>
      'Bu işlem tüm görevleri, zaman kayıtlarını ve ekleri kalıcı olarak siler.\n\nBu işlem geri alınamaz. Emin misiniz?';

  @override
  String get appDeleteAll => 'Tümünü sil';

  @override
  String get appAllDataCleared => 'Tüm veriler temizlendi';

  @override
  String get appCompactDatabaseTitle => 'Veritabanını sıkıştır';

  @override
  String get appCompactDatabaseBody =>
      'Veritabanı dosyasını yeniden yazar; böylece silinmiş görevlerin, eklerin ve eski değişiklik geçmişinin kapladığı alan diske geri verilir.\n\nSilinmiş eklerin içerikleri de serbest bırakılır; bunlardan birini geri yüklerseniz sunucudan yeniden indirilir.\n\nHâlâ görebildiğiniz hiçbir şey kaldırılmaz. Büyük bir veritabanında bu işlem biraz sürer ve bitene kadar uygulama kullanılamaz.';

  @override
  String get appCompact => 'Sıkıştır';

  @override
  String get appCompactingDatabase => 'Veritabanı sıkıştırılıyor...';

  @override
  String appCompactingFailed(String error) {
    return 'Sıkıştırma başarısız: $error';
  }

  @override
  String get appDatabaseCompacted => 'Veritabanı sıkıştırıldı';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'Veritabanı sıkıştırıldı — $freed boşaltıldı (şimdi $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'Veritabanı sıkıştırıldı — zaten sıkıştırılmıştı ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Bul';

  @override
  String get appSyncNowTooltip => 'Şimdi eşitle';

  @override
  String get appBiometricFailed =>
      'Biyometrik doğrulama başarısız. Lütfen parolayı girin.';

  @override
  String get appSavedPasswordIncorrect =>
      'Kayıtlı parola yanlış. Lütfen parolayı girin.';

  @override
  String get appLoading => 'Yükleniyor...';

  @override
  String get appFailedToOpenDatabaseTitle => 'Veritabanı açılamadı';

  @override
  String get appOpenAnotherDatabase => 'Başka bir veritabanı aç…';

  @override
  String get appBiometricReason => 'Noo veritabanınızın kilidini açın';

  @override
  String appWelcomeTitle(String appName) {
    return '$appName uygulamasına hoş geldiniz';
  }

  @override
  String get appWelcomeIntro =>
      'Şifreli veritabanınızın nerede saklanacağını seçin. Bunu daha sonra Dosya menüsünden değiştirebilirsiniz.';

  @override
  String get appUseDefaultLocation => 'Varsayılan konumu kullan';

  @override
  String get appResolving => 'Belirleniyor…';

  @override
  String get appCreateNewDatabaseOption => 'Yeni veritabanı oluştur…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Yeni bir şifreli veritabanı için özel bir konum seçin.';

  @override
  String get appOpenExistingDatabaseOption => 'Mevcut veritabanını aç…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Başka bir konumdaki mevcut bir .noo dosyasını kullanın.';

  @override
  String get appQuit => 'Çık';

  @override
  String get appWelcomeSyncHint =>
      'Başka bir cihazda zaten bir veritabanınız mı var? Burada aynı parolayla yeni bir veritabanı oluşturun, ardından Tercihler → Eşitleme bölümünde aynı kullanıcı adıyla eşitlemeyi kurun — notlarınız ilk eşitlemede gelecektir.';

  @override
  String get appTaskFallbackTitle => 'Görev';

  @override
  String get appTabNotes => 'Notlar';

  @override
  String get appTabTime => 'Zaman';

  @override
  String get appTabFiles => 'Dosyalar';

  @override
  String appTabFilesCount(int count) {
    return 'Dosyalar ($count)';
  }

  @override
  String get appStartTracking => 'Takibi başlat';

  @override
  String get appStopTracking => 'Takibi durdur';

  @override
  String get appNoTaskSelected => 'Görev seçilmedi.';

  @override
  String get appAttachmentsHeading => 'Ekler';

  @override
  String get appModified => 'Değiştirildi';

  @override
  String get appWordWrapOnTooltip =>
      'Sözcük kaydırma açık — kapatmak için tıklayın';

  @override
  String get appWordWrapOffTooltip =>
      'Sözcük kaydırma kapalı — açmak için tıklayın';

  @override
  String get appTimeTodayTap => 'Bugün takip edilen süre — açmak için dokunun';

  @override
  String get appHideTimeTracking => 'Zaman takibini gizle';

  @override
  String get appTimeTodayClick =>
      'Bugün takip edilen süre — ayrıntılar için tıklayın';

  @override
  String get appViewTimeline => 'Zaman çizelgesini görüntüle';

  @override
  String get appAttachmentsTap => 'Ekler — açmak için dokunun';

  @override
  String get appHideAttachments => 'Ekleri gizle';

  @override
  String get appAttachmentsClick => 'Ekler — göstermek için tıklayın';

  @override
  String get appAddAttachment => 'Ek ekle';

  @override
  String get appUntitledInPath => '(adsız)';

  @override
  String get appSyncStatusDisabled =>
      'Eşitleme devre dışı — eşitlemek için tıklayın';

  @override
  String get appSyncStatusUnknown =>
      'Henüz eşitlenmedi — eşitlemek için tıklayın';

  @override
  String get appSyncStatusIdle => 'Eşitlendi — eşitlemek için tıklayın';

  @override
  String get appSyncStatusSyncing => 'Eşitleniyor...';

  @override
  String get appSyncStatusError =>
      'Eşitleme hatası — yeniden denemek için tıklayın';

  @override
  String get appSyncStatusPending =>
      'Bekleyen değişiklikler — eşitlemek için tıklayın';

  @override
  String get appSyncStatusIncoming =>
      'Diğer cihazlar değişiklik gönderdi — eşitlemek için tıklayın';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Zaman takibi: \"$title\" — oraya gitmek için tıklayın';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Takibi durdur: \"$title\"';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String appPendingMore(int count) {
    return '+$count tane daha';
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
      other: '$count öge',
      one: '1 öge',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik',
      one: '1 değişiklik',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'Eşitlenmeyi bekleyen: $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'başlık';

  @override
  String get appPendingFieldContent => 'içerik';

  @override
  String get appPendingFieldMoved => 'taşındı';

  @override
  String get appPendingFieldReordered => 'yeniden sıralandı';

  @override
  String get appPendingFieldFlags => 'bayraklar';

  @override
  String get appPendingFieldDeleted => 'silindi';

  @override
  String get appPendingFieldName => 'ad';

  @override
  String get appPendingFieldStartTime => 'başlangıç zamanı';

  @override
  String get appPendingFieldEndTime => 'bitiş zamanı';

  @override
  String get appJustNow => 'az önce';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dk önce',
      one: '$count dk önce',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sa önce',
      one: '$count sa önce',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count g önce',
      one: '$count g önce',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Parolayı girin';

  @override
  String get appSetDatabasePasswordTitle => 'Veritabanı parolasını belirleyin';

  @override
  String get appPasswordLabel => 'Parola';

  @override
  String get appConfirmPasswordLabel => 'Parolayı onaylayın';

  @override
  String get appPleaseEnterPassword => 'Lütfen bir parola girin';

  @override
  String get appPasswordTooShort => 'Parola en az 4 karakter olmalıdır';

  @override
  String get appPasswordsDoNotMatch => 'Parolalar eşleşmiyor';

  @override
  String get appPasswordWarning =>
      'Parola veritabanınızı şifrelemek için kullanılacak. Unutursanız veriler kurtarılamaz.';

  @override
  String get appCreate => 'Oluştur';

  @override
  String get appStrengthVeryWeak => 'Çok zayıf';

  @override
  String get appStrengthWeak => 'Zayıf';

  @override
  String get appStrengthFair => 'Orta';

  @override
  String get appStrengthGood => 'İyi';

  @override
  String get appStrengthStrong => 'Güçlü';

  @override
  String get appTagline => 'Zaman takipli küçük anahat düzenleyici';

  @override
  String get appAboutDescription =>
      'Düşüncelerinizi, görevlerinizi ve projelerinizi düzenlemek için yerleşik zaman takibine sahip, platformlar arası bir masaüstü anahat düzenleyici.';

  @override
  String get appBuiltWithFlutter => 'Flutter ile geliştirildi';

  @override
  String get appCheckForUpdateTitle => 'Güncellemeleri denetle';

  @override
  String appCouldNotOpen(String url) {
    return 'Açılamadı: $url';
  }

  @override
  String get appOpenReleasePage => 'Sürüm sayfasını aç';

  @override
  String get appDownloadApk => 'APK\'yı indir';

  @override
  String get appDownloadDiskImage => 'Disk görüntüsünü indir';

  @override
  String get appCheckingForUpdate => 'Yeni sürüm denetleniyor...';

  @override
  String get appUpdateCheckFailed => 'Güncelleme denetimi başarısız';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version en son sürümdür.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return '$appName $version kullanılabilir (yüklü sürüm: $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return '$appName $version indiriliyor...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received / $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version indirildi ve doğrulandı. Yükleme sırasında $appName kapanır, program dosyaları değiştirilir ve uygulama yeniden başlatılır. Veritabanlarınıza dokunulmaz.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version yüklendi. Kullanmaya başlamak için yeniden başlatın.';
  }

  @override
  String get appLater => 'Daha sonra';

  @override
  String get appInstall => 'Yükle';

  @override
  String get appInstallAndRestart => 'Yükle ve yeniden başlat';

  @override
  String get appRestartNow => 'Şimdi yeniden başlat';

  @override
  String get appUpdGithubTimeout => 'GitHub zamanında yanıt vermedi';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'GitHub\'a ulaşılamıyor: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub en son sürüm için $status yanıtını verdi';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Beklenmeyen sürüm verisi: $error';
  }

  @override
  String get appUpdUnexpectedData => 'Beklenmeyen sürüm verisi';

  @override
  String get appUpdNoInPlace => 'Bu platformda yerinde güncelleme yok';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return '$version sürümünün Windows yükleyicisi yok';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return '$version sürümünün Windows ZIP dosyası yok';
  }

  @override
  String appUpdCannotWrite(String path) {
    return 'Yazılamıyor: $path; yeni sürümü elle indirin';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return 'İndirilen dosyada ($fileName) şu öge yok: $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'İndirilen dosya geçerli bir ZIP değil: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'ZIP güvenli olmayan bir yol içeriyor: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'İndirilen dosya açılamıyor: $error';
  }

  @override
  String get appUpdNotAppImage => 'Bir AppImage\'dan çalıştırılmıyor';

  @override
  String appUpdNoAppImage(String version) {
    return '$version sürümünün Linux AppImage dosyası yok';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Yeni AppImage çalıştırılabilir yapılamıyor: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return 'Değiştirilemiyor: $path: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'İndirme başarısız: sunucu $status yanıtını verdi';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'İndirilen dosya kaydedilemiyor: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'İndirme kesildi: $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'İndirilen dosya yayımlanan sağlama toplamıyla eşleşmiyor';

  @override
  String appUpdNoChecksums(String version) {
    return '$version sürümü sağlama toplamı yayımlamıyor; elle indirin';
  }

  @override
  String get appUpdChecksumTimeout =>
      'Sağlama toplamı indirmesi zaman aşımına uğradı';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Sağlama toplamı indirilemedi: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Sağlama toplamı indirilemedi: sunucu $status yanıtını verdi';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName, $checksumsFile içinde listelenmiyor';
  }

  @override
  String get appLogCopied => 'Uygulama günlüğü panoya kopyalandı';

  @override
  String get appLogTitle => 'Uygulama günlüğü';

  @override
  String get appLogSaveDialogTitle => 'Uygulama günlüğünü kaydet';

  @override
  String appSavedTo(String path) {
    return 'Kaydedildi: $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get appShare => 'Paylaş';

  @override
  String get appClearLogTooltip => 'Günlüğü temizle';

  @override
  String get appClearLogButton => 'Günlüğü temizle';

  @override
  String get appSaveEllipsis => 'Kaydet...';

  @override
  String get appSearchHint => 'Ara';

  @override
  String get appLogLevelAll => 'Tümü';

  @override
  String get appLogLevelWarnings => 'Uyarılar ve hatalar';

  @override
  String get appLogLevelErrors => 'Hatalar';

  @override
  String get appLogEmpty => 'Henüz hiçbir şey günlüğe kaydedilmedi.';

  @override
  String get appLogNoMatch => 'Eşleşen satır yok.';

  @override
  String get appHistoryTitle => 'Değişiklik geçmişi';

  @override
  String get appHistoryFilter => 'Filtre: ';

  @override
  String appHistoryAll(int count) {
    return 'Tümü ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Görevler ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'Dosyalar ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Zaman çizelgesi ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Hata: $error';
  }

  @override
  String get appHistoryEmpty => 'Geçmiş kaydı bulunamadı';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alan değişti',
      one: '1 alan değişti',
      zero: '0 alan değişti',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return 'Gruplanmış $total kaydın $shown tanesi gösteriliyor (toplam $changes alan değişikliği)';
  }

  @override
  String get appHistoryOld => 'Eski:';

  @override
  String get appHistoryNew => 'Yeni:';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonSave => 'Kaydet';

  @override
  String get commonSaveAs => 'Farklı kaydet...';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonRename => 'Yeniden adlandır';

  @override
  String get commonRemove => 'Kaldır';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get commonOpen => 'Aç';

  @override
  String get commonCopy => 'Kopyala';

  @override
  String get commonApply => 'Uygula';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get commonYes => 'Evet';

  @override
  String get commonNo => 'Hayır';

  @override
  String get commonBrowse => 'Gözat...';

  @override
  String get commonError => 'Hata';

  @override
  String get commonShow => 'Göster';

  @override
  String get commonHide => 'Gizle';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonRefresh => 'Yenile';

  @override
  String get commonTest => 'Test et';

  @override
  String get commonDownload => 'İndir';

  @override
  String get commonNone => 'Yok';

  @override
  String get commonSystemDefault => 'Sistem varsayılanı';

  @override
  String get commonUntitled => 'Adsız';

  @override
  String get languageSystem => 'Sistem varsayılanı';

  @override
  String get editorImageNotAvailable => 'Görsel kullanılamıyor';

  @override
  String get editorImageResize => 'Yeniden boyutlandır...';

  @override
  String get editorImageReplace => 'Görseli değiştir...';

  @override
  String get editorImageSaveAs => 'Görseli farklı kaydet...';

  @override
  String get editorImageRemoveFromText => 'Metinden kaldır';

  @override
  String get editorImageRemoveFromTextHint => 'Dosyayı Ekler\'de tutar';

  @override
  String get editorImageDelete => 'Görseli sil';

  @override
  String get editorImageDeleteHint => 'Eki de siler';

  @override
  String get editorImageKeptInOtherTask =>
      'Görsel metinden kaldırıldı. Dosya başka bir göreve ait olduğu için orada tutuldu.';

  @override
  String get editorResizeImageTitle => 'Görseli yeniden boyutlandır';

  @override
  String get editorResizeWidth => 'Genişlik';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '%$percent / $natural px';
  }

  @override
  String get editorResizeOriginalSize => 'Özgün boyut';

  @override
  String get editorInsertImage => 'Görsel ekle';

  @override
  String get editorReplaceImageDialogTitle => 'Görseli değiştir';

  @override
  String get editorSaveImageDialogTitle => 'Görseli kaydet';

  @override
  String editorSavedFile(String name) {
    return 'Kaydedildi: $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Dosya ekle\n(ekleri göstermek için uzun basın)';

  @override
  String get editorAttachFileTooltip =>
      'Dosya ekle\n(ekleri göstermek veya gizlemek için uzun basın)';

  @override
  String get editorStopRecording => 'Kaydı durdur';

  @override
  String get editorRecordVoiceMemo => 'Sesli not kaydet';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Sesli not kaydet\n(metne dökmeden kaydetmek için uzun basın)';

  @override
  String editorAttachedOne(String name) {
    return 'Eklendi: $name';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dosya eklendi',
      one: '1 dosya eklendi',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Yazı tipi ailesi';

  @override
  String get editorFontSize => 'Yazı tipi boyutu';

  @override
  String get editorSizeLabel => 'Boyut';

  @override
  String get editorSizeSmall => 'Küçük';

  @override
  String get editorSizeLarge => 'Büyük';

  @override
  String get editorSizeHuge => 'Çok büyük';

  @override
  String get editorStartTyping => 'Yazmaya başlayın...';

  @override
  String get editorLinkedTaskGone =>
      'Bağlantı verilen görev artık mevcut değil.';

  @override
  String get editorRemoveFormatting => 'Biçimlendirmeyi kaldır';

  @override
  String editorFormatAsTable(String separator) {
    return 'Tablo olarak biçimlendir ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Sözcük kaydırmayı kapat';

  @override
  String get editorWordWrapOn => 'Sözcük kaydırmayı aç';

  @override
  String editorErrorMessage(String error) {
    return 'Hata: $error';
  }

  @override
  String get editorTaskNotFound => 'Görev bulunamadı';

  @override
  String get editorSelectTask => 'Düzenlemek için bir görev seçin';

  @override
  String editorSaveFailed(String error) {
    return 'Görev kaydedilemedi: $error';
  }

  @override
  String get editorChangesMerged =>
      'Bu not siz düzenlerken başka bir yerde değiştirildi. İki değişiklik birleştirildi.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'Bu not siz düzenlerken başka bir yerde değiştirildi. Metniniz kaydedildi; diğer sürüm \"$copyTitle\" adıyla tutuldu.';
  }

  @override
  String get treeNewTask => 'Yeni görev (Ctrl+N)';

  @override
  String get treeNewChildTask => 'Yeni alt görev (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Görevi sil';

  @override
  String get treeExpandAll => 'Tümünü genişlet';

  @override
  String get treeCollapseAll => 'Tümünü daralt';

  @override
  String get treeNoTasks => 'Henüz görev yok';

  @override
  String get treeCreateFirstTask => 'İlk görevinizi oluşturun';

  @override
  String get treeTrackedHere => 'Bu görevde zaman takip ediliyor';

  @override
  String get treeTrackedInside => 'İçerideki bir görevde zaman takip ediliyor';

  @override
  String get treeHiddenFromAgents =>
      'Altındaki her şeyle birlikte yapay zekâ ajanlarından gizli';

  @override
  String get treeMoveUp => 'Yukarı taşı';

  @override
  String get treeMoveDown => 'Aşağı taşı';

  @override
  String get treeMoveToParentLevel => 'Üst düzeye taşı';

  @override
  String get treeMoveUnderPrevious => 'Öncekinin altına taşı';

  @override
  String get treeAddChildTask => 'Alt görev ekle';

  @override
  String get treeStartTracking => 'Takibi başlat';

  @override
  String get treeStopTracking => 'Takibi durdur';

  @override
  String get treeTimeline => 'Zaman çizelgesi...';

  @override
  String get searchHint => 'Görevlerde ara...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sonuç',
      one: '1 sonuç',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Eşleşme yok';

  @override
  String get searchUntitled => '(adsız)';

  @override
  String get attachImageNotAvailable => 'Görsel kullanılamıyor';

  @override
  String get attachTryAgain => 'Yeniden dene';

  @override
  String get attachPlay => 'Oynat';

  @override
  String get attachPause => 'Duraklat';

  @override
  String attachLoadFailed(String error) {
    return 'Ekler yüklenemedi: $error';
  }

  @override
  String get attachNone => 'Ek yok';

  @override
  String get attachAddFile => 'Dosya ekle';

  @override
  String get attachNotDownloaded =>
      'Bu ek henüz indirilmedi — almak için eşitleyin';

  @override
  String get attachContentLoadFailed => 'Ek içeriği yüklenemedi';

  @override
  String get attachDownloading => 'Ek indiriliyor…';

  @override
  String get attachExportDialogTitle => 'Eki dışa aktar';

  @override
  String attachExported(String name) {
    return 'Dışa aktarıldı: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'Bu dosyayı açabilecek uygulama yok: $name';
  }

  @override
  String get attachImageInNoteTitle => 'Görsel notta kullanılıyor';

  @override
  String attachImageInNoteBody(String name) {
    return '\"$name\" bu görevin notunda gösteriliyor, bu yüzden buradan silinemez.\n\nHem resmi hem dosyayı kaldırmak için nottaki görsele tıklayıp \"Görseli sil\" komutunu seçin; dosyayı tutmak için \"Metinden kaldır\" komutunu seçin, ardından burada silebilirsiniz.';
  }

  @override
  String get attachDeleteTitle => 'Ek silinsin mi?';

  @override
  String attachDeleteConfirm(String name) {
    return '\"$name\" silinsin mi? Emin misiniz?';
  }

  @override
  String get attachRenameTitle => 'Eki yeniden adlandır';

  @override
  String get attachFileName => 'Dosya adı';

  @override
  String get attachShowPreview => 'Önizlemeyi göster';

  @override
  String get attachHidePreview => 'Önizlemeyi gizle';

  @override
  String get attachShare => 'Paylaş';

  @override
  String get attachExport => 'Dışa aktar';

  @override
  String get attachTranscribe => 'Metne dök';

  @override
  String get attachCannotPlay => 'Bu dosya oynatılamıyor';

  @override
  String get attachPlaybackUnavailable => 'Oynatma kullanılamıyor';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakikalık',
      one: '$minutes dakikalık',
    );
    return 'Kayıt $_temp0 sınırda durduruldu. Sesli not kaydedildi.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakikalık',
      one: '$minutes dakikalık',
    );
    return '$_temp0 sınıra ulaşıldı';
  }

  @override
  String get voiceDismiss => 'Kapat';

  @override
  String get voiceOpeningMic => 'Mikrofon açılıyor…';

  @override
  String get voiceSaving => 'Kaydediliyor…';

  @override
  String get voiceSavedTranscribing => 'Kaydedildi. Metne dökülüyor…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Kaydedildi. Metne dökülüyor… %$percent';
  }

  @override
  String get voiceDiscard => 'At';

  @override
  String get voiceStop => 'Durdur';

  @override
  String get voiceChooseModelFirst =>
      'Önce Tercihler\'den bir metne dökme modeli seçin';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'Model henüz indirilmedi: $model — Tercihler\'e bakın';
  }

  @override
  String get voiceTranscribing => 'Metne dökülüyor…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Metne dökülüyor… %$percent';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Metne dökülemedi: $error';
  }

  @override
  String get voiceNoSpeech => 'Bu sesli notta konuşma bulunamadı';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Metne döküldü, ancak ait olduğu not açık değil';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'Başka bir veritabanı açıldığı için kayıt atıldı.';

  @override
  String get voiceMicPermissionRefused => 'Mikrofon izni reddedildi';

  @override
  String voiceStartFailed(String error) {
    return 'Kayıt başlatılamadı: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Kayıt başarısız: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Kayıt tamamlanamadı: $error';
  }

  @override
  String get voiceNoDatabase =>
      'Açık veritabanı olmadığı için sesli not kaydedilemedi';

  @override
  String voiceSaveFailed(String error) {
    return 'Sesli not kaydedilemedi: $error';
  }

  @override
  String get timeTimelineTitle => 'Zaman çizelgesi';

  @override
  String get timeStatsToday => 'Bugün:';

  @override
  String get timeStatsThisMonth => 'Bu ay:';

  @override
  String timeRecordingSince(String time) {
    return 'Kayıt başlangıcı: $time';
  }

  @override
  String get timeEndBeforeStart =>
      'Bitiş zamanı başlangıç zamanından sonra olmalıdır';

  @override
  String get timeOverlaps => 'Mevcut bir aralıkla çakışıyor';

  @override
  String get timeAddIntervalTitle => 'Zaman aralığı ekle';

  @override
  String get timeEditIntervalTitle => 'Zaman aralığını düzenle';

  @override
  String get timeStartTime => 'Başlangıç:';

  @override
  String get timeFinishTime => 'Bitiş:';

  @override
  String get timeDurationLabel => 'Süre:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours saat',
      one: '$hours saat',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakika',
      one: '$minutes dakika',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours saat',
      one: '$hours saat',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes dakika',
      one: '$minutes dakika',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String timeShortHours(int hours) {
    return '$hours sa';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '$seconds sn';
  }

  @override
  String get timeAddEllipsis => 'Ekle...';

  @override
  String get timeNoRecords => 'Zaman kaydı yok';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'şimdi';

  @override
  String get timeRemoveIntervalTitle => 'Aralık kaldırılsın mı?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Bu zaman aralığını kaldırmak istediğinizden emin misiniz?';

  @override
  String get timeNotTracking => 'Takip yok';

  @override
  String get timeStopTracking => 'Takibi durdur';

  @override
  String get timeStartTracking => 'Takibi başlat';

  @override
  String get timeBackToFullWindow => 'Tam pencereye dön';

  @override
  String get timeReportTitle => 'Zaman raporu';

  @override
  String get timeReportSaveTitle => 'Zaman raporunu kaydet';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Rapor oluşturulamadı: $error';
  }

  @override
  String get timeReportCopied => 'Rapor panoya kopyalandı';

  @override
  String timeReportSavedTo(String path) {
    return 'Kaydedildi: $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get timeReportTasks => 'Görevler';

  @override
  String get timeReportNoTasks => 'Kullanılabilir görev yok.';

  @override
  String get timeReportClearSelection => 'Seçimi temizle';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seçili',
      one: '$count seçili',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Alt ögeleri dahil et';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Seçili her düğümün alt görevlerindeki süreyi de raporla.';

  @override
  String get timeReportDateRange => 'Tarih aralığı';

  @override
  String timeReportFrom(String date) {
    return 'Başlangıç: $date';
  }

  @override
  String timeReportTo(String date) {
    return 'Bitiş: $date';
  }

  @override
  String get timeReportFormat => 'Biçim';

  @override
  String get timeReportFormatTree => 'Ağaç (yalnızca toplamlar)';

  @override
  String get timeReportFormatTreeWithDays => 'Günlük dökümlü ağaç';

  @override
  String get timeReportFormatFlat => 'Düz aralık listesi';

  @override
  String get timeReportShowEmpty => 'Boş görevleri göster';

  @override
  String get timeReportUntitled => '(adsız)';

  @override
  String get timeReportSelectTasks =>
      'Rapor oluşturmak için bir veya daha fazla görev seçin.';

  @override
  String get timeReportNoRecordsInPeriod => 'Seçilen dönemde zaman kaydı yok.';

  @override
  String get timeReportTextPeriod => 'Dönem:';

  @override
  String get timeReportTextTotal => 'Toplam:';

  @override
  String get timeReportTextGenerated => 'Oluşturulma:';

  @override
  String get timeReportTextClipped =>
      'Dönem sınırlarını aşan kayıtlar döneme göre kırpılır.';

  @override
  String timeReportTextSelf(String duration) {
    return 'kendisi: $duration';
  }

  @override
  String get timeReportTextOngoing => 'devam ediyor';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kayıt',
      one: '1 kayıt',
    );
    return 'Toplam: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Yeniden oluştur';

  @override
  String get timeReportShare => 'Paylaş…';

  @override
  String get timeReportSave => 'Kaydet…';

  @override
  String get timeReportPresetToday => 'Bugün';

  @override
  String get timeReportPresetThisWeek => 'Bu hafta';

  @override
  String get timeReportPresetThisMonth => 'Bu ay';

  @override
  String get timeReportPresetLastMonth => 'Geçen ay';

  @override
  String get timeReportPresetThisYear => 'Bu yıl';

  @override
  String get prefsTitle => 'Tercihler';

  @override
  String get prefsTabAppearance => 'Görünüm';

  @override
  String get prefsTabBehavior => 'Davranış';

  @override
  String get prefsTabVoiceMemos => 'Sesli notlar';

  @override
  String get prefsTabSync => 'Eşitleme';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => 'Dil';

  @override
  String get prefsInterfaceLanguage => 'Arayüz';

  @override
  String get prefsLanguageHint =>
      'İngilizce dışındaki çeviriler makine çevirisidir; düzeltmelere açığız.';

  @override
  String get prefsGroupTheme => 'Tema';

  @override
  String get prefsThemeMode => 'Mod';

  @override
  String get prefsThemeSystem => 'Sistem';

  @override
  String get prefsThemeLight => 'Açık';

  @override
  String get prefsThemeDark => 'Koyu';

  @override
  String get prefsGroupStyle => 'Stil';

  @override
  String get prefsGroupColour => 'Renk';

  @override
  String get prefsLook => 'Görünüş';

  @override
  String get prefsLookHint =>
      'Klasik: köşeli kenarlar, düz çerçeveli düğmeler, dalga efekti yok, kaydırma çubukları her zaman görünür ve vurgu renginde bir başlık çubuğu, menü onun altında.';

  @override
  String get prefsUiStyleModern => 'Modern';

  @override
  String get prefsUiStyleClassic => 'Klasik';

  @override
  String get prefsAccentColour => 'Vurgu rengi';

  @override
  String get prefsAccentTeal => 'Camgöbeği';

  @override
  String get prefsAccentBlue => 'Mavi';

  @override
  String get prefsAccentIndigo => 'Çivit mavisi';

  @override
  String get prefsAccentPurple => 'Mor';

  @override
  String get prefsAccentPink => 'Pembe';

  @override
  String get prefsAccentRed => 'Kırmızı';

  @override
  String get prefsAccentOrange => 'Turuncu';

  @override
  String get prefsAccentAmber => 'Kehribar';

  @override
  String get prefsAccentGreen => 'Yeşil';

  @override
  String get prefsAccentGraphite => 'Grafit';

  @override
  String get prefsGroupWindow => 'Pencere';

  @override
  String get prefsSystemTitleBar => 'Sistem başlık çubuğunu kullan';

  @override
  String get prefsSystemTitleBarHint =>
      'Pencere çerçevesi, başlık ve düğmeler masaüstünün çizdiği gibi; menü çubuğu altında.';

  @override
  String get prefsGroupEditorFont => 'Düzenleyici yazı tipi (not metni)';

  @override
  String get prefsGroupTreeFont => 'Ağaç yazı tipi (anahat)';

  @override
  String get prefsGroupInterfaceFont =>
      'Arayüz yazı tipi (menüler ve iletişim kutuları)';

  @override
  String get prefsFontFamily => 'Aile';

  @override
  String get prefsFontCustom => 'Özel…';

  @override
  String get prefsCustomName => 'Özel ad';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'ör. $font';
  }

  @override
  String get prefsFontSize => 'Boyut';

  @override
  String get prefsUnitPt => 'pt';

  @override
  String get prefsFontStyle => 'Stil';

  @override
  String get prefsBold => 'Kalın';

  @override
  String get prefsItalic => 'İtalik';

  @override
  String get prefsPreview => 'Önizleme';

  @override
  String get prefsPreviewText => 'Pijamalı hasta yağız şoföre çabucak güvendi.';

  @override
  String get prefsScale => 'Ölçek';

  @override
  String get prefsFontSansSerif => 'Sans Serif';

  @override
  String get prefsFontSerif => 'Serif';

  @override
  String get prefsFontMonospace => 'Eş aralıklı';

  @override
  String get prefsGroupTimeTracking => 'Zaman takibi';

  @override
  String get prefsEnableTimeTracking => 'Zaman takibini etkinleştir';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Takibi başlatma/durdurma, zaman çizelgeleri ve zaman raporları. Kapatıldığında bunlar gizlenir; kaydedilen süre korunur';

  @override
  String get prefsShowSeconds => 'Saniyeleri göster';

  @override
  String get prefsShowSecondsHint => 'Sürelerde saniyeleri göster';

  @override
  String get prefsMiniTracker => 'Takip sırasında mini pencere göster';

  @override
  String get prefsMiniTrackerHint =>
      'Saat çalışırken pencereyi simge durumuna küçültmek, onu her zaman üstte duran küçük bir saate dönüştürür';

  @override
  String get prefsGroupSaving => 'Kaydetme';

  @override
  String get prefsAutoSaveEvery => 'Otomatik kaydetme aralığı';

  @override
  String get prefsUnitSec => 'sn';

  @override
  String get prefsGroupEditor => 'Düzenleyici';

  @override
  String get prefsTabWidth => 'Sekme genişliği';

  @override
  String get prefsUnitSpaces => 'boşluk';

  @override
  String get prefsTabAsSpaces => 'Sekmeleri boşluk olarak ekle';

  @override
  String get prefsTabAsSpacesHint =>
      'Tab tuşuna basıldığında sekme yerine boşluk eklenir';

  @override
  String get prefsWordWrap => 'Sözcük kaydırma';

  @override
  String get prefsWordWrapHint =>
      'Kapalıyken: uzun satırlar devam eder ve not yatay olarak kayar (Shift + tekerlek). Düzenleyicinin bağlam menüsünde ve durum çubuğunda da bulunur';

  @override
  String get prefsMonospaceOnly => 'Yalnızca eş aralıklı yazı tipleri';

  @override
  String get prefsMonospaceOnlyHint =>
      'Araç çubuğunun Yazı tipi menüsü yalnızca sabit genişlikli aileleri sunar; böylece hizalanması gereken metin hizalı kalır';

  @override
  String get prefsFloatingButtons => 'Kayan düğmeler';

  @override
  String get prefsFloatingButtonsHint =>
      'Notun üzerinde Dosya ekle ve Sesli not kaydet düğmeleri; araç çubuğu her durumda kendi düğmelerini korur';

  @override
  String get prefsPaste => 'Yapıştırma';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V her zaman düz metin yapıştırır';

  @override
  String get prefsPasteKeep => 'Biçimlendirmeyi koru';

  @override
  String get prefsPasteStrip => 'Renkleri ve yazı tiplerini kaldır';

  @override
  String get prefsPastePlain => 'Yalnızca düz metin';

  @override
  String get prefsTableColumns => 'Tablo sütunları';

  @override
  String get prefsTableColumnsHint =>
      'Tablo olarak biçimlendir komutunun (düzenleyici bağlam menüsü) sütunları ayırdığı karakter. URL\'lerin veya tırnak içindeki metnin içinde ayırmaz';

  @override
  String get prefsSeparatorColon => 'İki nokta  ( : )';

  @override
  String get prefsSeparatorEquals => 'Eşittir işareti  ( = )';

  @override
  String get prefsSeparatorPipe => 'Dikey çizgi  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Noktalı virgül  ( ; )';

  @override
  String get prefsSeparatorComma => 'Virgül  ( , )';

  @override
  String get prefsSeparatorTab => 'Sekme';

  @override
  String get prefsGroupToolbarButtons => 'Araç çubuğu düğmeleri';

  @override
  String get prefsToolbarButtonsHint =>
      'Bir düğmeyi düzenleyici araç çubuğundan kaldırmak için işaretini kaldırın.';

  @override
  String get prefsToolbarUndoRedo => 'Geri al / Yinele';

  @override
  String get prefsToolbarFont => 'Yazı tipi';

  @override
  String get prefsToolbarSize => 'Boyut';

  @override
  String get prefsToolbarBold => 'Kalın';

  @override
  String get prefsToolbarItalic => 'İtalik';

  @override
  String get prefsToolbarUnderline => 'Altı çizili';

  @override
  String get prefsToolbarStrikeThrough => 'Üstü çizili';

  @override
  String get prefsToolbarInlineCode => 'Kod';

  @override
  String get prefsToolbarTextColor => 'Metin rengi';

  @override
  String get prefsToolbarHighlightColor => 'Vurgulama rengi';

  @override
  String get prefsToolbarClearFormat => 'Biçimlendirmeyi temizle';

  @override
  String get prefsToolbarHeadings => 'Başlıklar';

  @override
  String get prefsToolbarNumberedList => 'Numaralı liste';

  @override
  String get prefsToolbarBulletedList => 'Madde işaretli liste';

  @override
  String get prefsToolbarChecklist => 'Denetim listesi';

  @override
  String get prefsToolbarCodeBlock => 'Kod bloğu';

  @override
  String get prefsToolbarQuote => 'Alıntı';

  @override
  String get prefsToolbarIndent => 'Girinti';

  @override
  String get prefsToolbarLink => 'Bağlantı';

  @override
  String get prefsToolbarInsertImage => 'Görsel ekle';

  @override
  String get prefsToolbarVoiceMemo => 'Sesli not';

  @override
  String get prefsGroupSecurity => 'Güvenlik';

  @override
  String get prefsRememberPassword => 'Parolayı hatırla';

  @override
  String get prefsRememberPasswordHint =>
      'Veritabanı parolasını sistem anahtarlığında sakla';

  @override
  String get prefsBiometricUnlock => 'Biyometrik kilit açma';

  @override
  String get prefsBiometricUnavailableHint =>
      'Kullanılamıyor — önce Android ayarlarında parmak izi veya ekran kilidi ayarlayın';

  @override
  String get prefsBiometricHint =>
      'Hatırlanan parola kullanılmadan önce parmak izi, yüz veya ekran kilidiyle onaylayın';

  @override
  String get prefsBlockScreenshots => 'Ekran görüntülerini engelle';

  @override
  String get prefsBlockScreenshotsHint =>
      'Uygulama içeriğini ekran görüntülerinde, ekran kaydında ve son uygulamalar listesinde gizle';

  @override
  String get prefsGroupStartup => 'Başlangıç';

  @override
  String get prefsSingleInstance => 'Tek örnek';

  @override
  String get prefsSingleInstanceHint =>
      'Yalnızca bir pencerenin çalışmasına izin ver; yeni bir başlatma mevcut pencereyi öne getirir. Bir sonraki başlatmada geçerli olur.';

  @override
  String get prefsVoiceGroupDevices => 'Cihazlar';

  @override
  String get prefsVoiceMicrophone => 'Mikrofon';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Sesli notlar ve aşağıdaki denetim için kullanılır.';

  @override
  String get prefsVoiceSpeaker => 'Hoparlör';

  @override
  String get prefsVoiceSpeakerHint =>
      'Sesli notlar için geçerlidir. Diğer ses ekleri sistem varsayılanından çalınır.';

  @override
  String get prefsVoiceDevicesLooking => 'Aranıyor…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'Ses cihazları listelenemedi: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Kullanılamıyor';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (varsayılan)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (bağlı değil)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Metne dökme';

  @override
  String get prefsVoiceModel => 'Model';

  @override
  String get prefsVoiceModelHintNone =>
      'Sesli notlar yalnızca ses olarak kaydedilir ve saklanır.';

  @override
  String get prefsVoiceModelHintLocal =>
      'Bu cihazda çalışır. Hiçbir yere bir şey gönderilmez.';

  @override
  String get prefsVoiceModelOff => 'Kapalı';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · önerilen';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count MB';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Kayıttan sonra metne dök';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'Sesli not önce saklanır, ardından saklanan sesten metne dökülür. Kapalıyken metne dökülmeden saklanır; ek menüsündeki \"Metne dök\" daha sonra yine kullanılabilir.';

  @override
  String get prefsVoiceLanguage => 'Dil';

  @override
  String get prefsVoiceLanguageAuto => 'Otomatik algıla';

  @override
  String get prefsVoiceFooter =>
      'Kayıt model olmadan da çalışır — sesli notlar her zaman ses olarak saklanır ve diğer ekler gibi oynatılır. Model yalnızca metni ekler.';

  @override
  String get prefsVoiceGroupCheck => 'Denetim';

  @override
  String get prefsVoiceCheckIntro =>
      'Yukarıdaki cihazları ve modeli kullanarak birkaç saniye kaydeder, geri oynatır ve metne döker. Hiçbir şey kaydedilmez.';

  @override
  String get prefsVoiceStop => 'Durdur';

  @override
  String get prefsVoiceTestAgain => 'Yeniden test et';

  @override
  String get prefsVoiceCheckRecording =>
      'Kaydediliyor — bir cümle söyleyin, ardından Durdur\'a basın.';

  @override
  String get prefsVoiceCheckPlaying => 'Geri oynatılıyor…';

  @override
  String get prefsVoiceCheckTranscribing => 'Metne dökülüyor…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Metne dökülüyor… %$percent';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return 'Kaydedilen süre: $duration.';
  }

  @override
  String get prefsVoiceCheckFailed => 'Denetim tamamlanmadı.';

  @override
  String get prefsVoiceDownloading => 'İndiriliyor…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '%$percent / $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return 'Model indirildi ve hazır: $model.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'İndirilmedi — HuggingFace\'ten $size.';
  }

  @override
  String get prefsCheckBusy => 'Bir sesli not kaydediliyor. Önce onu bitirin.';

  @override
  String get prefsCheckPermissionRefused => 'Mikrofon izni reddedildi.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'Mikrofon açılamadı: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Kayıt başarısız: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'Kayıt tamamlanamadı: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Hiçbir şey kaydedilmedi. Testi biraz daha uzun sürdürün veya başka bir mikrofon seçin.';

  @override
  String get prefsCheckMalformed => 'Kayıt bozuk geldi ve oynatılamadı.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Oynatma başarısız: $error';
  }

  @override
  String get prefsCheckNoModel =>
      'Kayıt ve oynatma çalıştı. Model seçilmediği için metne dökülecek bir şey yok.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'Kayıt ve oynatma çalıştı. Model henüz indirilmediği için ($model) hiçbir şey metne dökülmedi.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Metne dökme başarısız: $error';
  }

  @override
  String get prefsCheckSilence =>
      'Mikrofondan yalnızca sessizlik geldi — seviye göstergesi hiç kıpırdamadı. Doğru cihazın seçildiğini ve uygulamanın onu kullanma izni olduğunu denetleyin.';

  @override
  String get prefsCheckNoSpeech =>
      'Kayıt ve oynatma çalıştı, ancak whisper konuşma bulamadı. Mikrofona daha yakından konuşmayı veya başka bir dili deneyin.';

  @override
  String get prefsCheckQuiet =>
      'Seviye göstergesi hiç kıpırdamadı, yani giriş çok sessiz.';

  @override
  String get prefsDownloadCancelled => 'İndirme iptal edildi.';

  @override
  String prefsDownloadFailed(String error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get prefsUntitled => '(adsız)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Yalnızca bu oturum için kaydedildi: sistem anahtarlığı reddetti. Anahtarlığınız kilitliyse kilidini açın ve Yeniden oluştur\'a basın.';

  @override
  String get prefsMcpRegenerateTitle => 'Belirteç yeniden oluşturulsun mu?';

  @override
  String get prefsMcpRegenerateBody =>
      'Geçerli belirteçle yapılandırılmış ajanlar, yenisini ayarlarına yapıştırana kadar çalışmaz.';

  @override
  String get prefsMcpRegenerate => 'Yeniden oluştur';

  @override
  String get prefsMcpGroupAccess => 'Ajan erişimi';

  @override
  String get prefsMcpEnable => 'MCP sunucusunu etkinleştir';

  @override
  String get prefsMcpEnableHint =>
      'Yerel yapay zekâ kodlama ajanlarının bu anahattı 127.0.0.1 üzerinden okumasına izin ver. Varsayılan olarak kapalı.';

  @override
  String get prefsMcpReadOnly => 'Salt okunur';

  @override
  String get prefsMcpReadOnlyHint =>
      'Ajanlar görevleri arayıp okuyabilir, ancak oluşturamaz, değiştiremez, taşıyamaz veya silemez.';

  @override
  String get prefsMcpGroupEndpoint => 'Uç nokta';

  @override
  String get prefsMcpPort => 'Bağlantı noktası';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'URL\'yi kopyala';

  @override
  String get prefsMcpToken => 'Belirteç';

  @override
  String get prefsMcpTokenHint =>
      'Sizin adınıza program çalıştırabilen herkes bu belirteci kullanabilir. Ona parola gibi davranın.';

  @override
  String get prefsMcpNoTokenYet =>
      'Henüz belirteç yok — oluşturmak için sunucuyu etkinleştirin';

  @override
  String get prefsMcpShowToken => 'Belirteci göster';

  @override
  String get prefsMcpHideToken => 'Belirteci gizle';

  @override
  String get prefsMcpCopyToken => 'Belirteci kopyala';

  @override
  String get prefsMcpCopied => 'Kopyalandı.';

  @override
  String get prefsMcpGroupExcluded => 'Hariç tutulan dallar';

  @override
  String get prefsMcpExcludedIntro =>
      'Altındaki her şeyle birlikte MCP sunucusundan gizlenen görevler.';

  @override
  String get prefsMcpLoading => 'Yükleniyor…';

  @override
  String get prefsMcpOutlineReadError => 'Anahat okunamadı.';

  @override
  String get prefsMcpChoose => 'Seç…';

  @override
  String get prefsMcpNothingExcluded =>
      'Hiçbir şey hariç tutulmadı — ajanlar anahattın tamamını görebilir.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 've $count tane daha',
      one: 've $count tane daha',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'Dinleniyor: $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'Bağlantı noktası $port kullanılamıyor. Başka bir bağlantı noktası seçin.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'Erişim belirteci yok. Oluşturmak için Yeniden oluştur\'a basın.';

  @override
  String get prefsMcpWaitingDatabase =>
      'Bir veritabanının açılması bekleniyor.';

  @override
  String get prefsMcpNotRunning => 'Çalışmıyor.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Son istek: $time';
  }

  @override
  String get prefsMcpNoRequests => 'Henüz istek yok';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reddedildi (yanlış veya eksik belirteç)',
      one: '$count reddedildi (yanlış veya eksik belirteç)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<önce sunucuyu etkinleştirin>';

  @override
  String get prefsMcpGroupSetup => 'Ajanınızı kurun';

  @override
  String get prefsMcpClient => 'İstemci';

  @override
  String get prefsMcpStdioBridge =>
      'Yalnızca stdio konuşan bir ajan şununla köprülenebilir:';

  @override
  String get prefsMcpTargetTerminal => 'Bunu bir terminalde çalıştırın:';

  @override
  String prefsMcpTargetFile(String file) {
    return 'Şu dosyaya ekleyin: $file';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Kullanıcınız kapsamında olduğu için anahat her projede kullanılabilir.';

  @override
  String get prefsMcpNoteCodex =>
      'Belirteci dosyanın dışında tutmak için http_headers yerine bearer_token_env_var = \"NOO_MCP_TOKEN\" yazın ve bu değişkeni kabuğunuzda ayarlayın.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false önemlidir — o olmadan OpenCode bu sunucunun 401 yanıtını, tamamlayamayacağı bir OAuth kaydı başlatma daveti olarak yorumlar.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'İşaretli bir görev, altındaki her şeyle birlikte MCP sunucusundan gizlenir — ajanlar onu okuyamaz, değiştiremez veya onu içeren hiçbir şeyi silemez.';

  @override
  String get prefsMcpNoDatabase => 'Açık veritabanı yok.';

  @override
  String get prefsMcpNoTasks => 'Bu anahatta henüz görev yok.';

  @override
  String get prefsMcpCollapse => 'Daralt';

  @override
  String get prefsMcpExpand => 'Genişlet';

  @override
  String get prefsMcpHiddenWithParent => 'üst ögeyle birlikte gizli';

  @override
  String get syncGroupSynchronization => 'Eşitleme';

  @override
  String get syncEnable => 'Eşitlemeyi etkinleştir';

  @override
  String get syncEnableHint => 'Bu veritabanını bir sunucuyla eşitlenmiş tut';

  @override
  String get syncGroupIdentity => 'Kimlik';

  @override
  String get syncNeedsUserName =>
      'Eşitlemeye başlamak için bir kullanıcı adı girin. Kullanıcı adı olmadan hiçbir şey eşitlenmez — sunucu olsun ya da olmasın.';

  @override
  String get syncUserName => 'Kullanıcı adı';

  @override
  String get syncUserNameHint =>
      'Tüm cihazlarınızda aynıdır. Veritabanı parolasıyla birlikte şifreleme anahtarlarını türetir; bu yüzden cihazlar yalnızca ikisi de eşleştiğinde eşitlenir.';

  @override
  String get syncDeviceName => 'Cihaz adı';

  @override
  String get syncDeviceNameHint =>
      'Bu cihazın yakındaki cihazlara kendini tanıttığı ad';

  @override
  String get syncGroupServer => 'Eşitleme sunucusu (isteğe bağlı)';

  @override
  String get syncServerIntro =>
      'Yalnızca aynı ağdaki yakın cihazlarla eşitlemek için boş bırakın. Sunucu, cihazların birbirinden uzaktayken de eşitlenmesini sağlar; okuyamadığı şifreli verileri saklar.';

  @override
  String get syncServerUrl => 'Sunucu URL\'si';

  @override
  String get syncServerPassword => 'Parola';

  @override
  String get syncServerPasswordHint =>
      'Sunucudaki hesap parolanız. Veritabanı parolası değildir ve asla şifreleme anahtarı olarak kullanılmaz.';

  @override
  String get syncTestConnection => 'Bağlantıyı test et';

  @override
  String get syncRegister => 'Kaydol';

  @override
  String get syncGroupSchedule => 'Zamanlama';

  @override
  String get syncScheduleNeedsServer =>
      'Başlangıçta ve çıkışta eşitleme bir sunucu gerektirir. Aynı ağdaki cihazlar, siz istediğinizde Araçlar → P2P eşitle... ile eşitlenir.';

  @override
  String get syncAutosyncOnStart => 'Başlangıçta otomatik eşitle';

  @override
  String get syncAutosyncOnStartHint =>
      'Uygulama veritabanını açtığında eşitle';

  @override
  String get syncCheckOnStart => 'Başlangıçta gelen değişiklikleri denetle';

  @override
  String get syncCheckOnStartHint =>
      'Eşitleme yapmadan, diğer cihazların değişiklik gönderip göndermediğini sunucuya sor ve bunu eşitleme simgesinde göster. Başlangıçta otomatik eşitle açıkken gerekmez';

  @override
  String get syncAskOnExit => 'Çıkışta eşitlemeyi sor';

  @override
  String get syncAskOnExitHint =>
      'Uygulama kapanmadan önce bekleyen değişiklikleri eşitlemeyi öner';

  @override
  String get syncGroupServerStorage => 'Sunucu depolaması';

  @override
  String get syncGroupPeerToPeer => 'Eşler arası';

  @override
  String get syncPeerToPeerIntro =>
      'Aynı ağda, kullanıcı adınızı ve veritabanı parolanızı paylaşan cihazlar doğrudan eşitlenebilir — sunucu gerekmez. Her birinde Araçlar → P2P eşitle... penceresini açın: o pencere açıkken birbirlerini bulur ve eşitlenirler, aksi halde keşfedilemezler.';

  @override
  String get syncStorageNoServer =>
      'Bu kurulumda sunucuda hiçbir şey saklanmaz. Eşler arası eşitleme her paketi cihazların kendisinde tutar.';

  @override
  String get syncStorageIntro =>
      'Sunucu şimdiye kadar yapılan her şifreli değişikliği saklar; bu yüzden boyutu anahattınızın boyutuyla değil, düzenlemelerle büyür.';

  @override
  String get syncStorageReading => 'Okunuyor…';

  @override
  String get syncStoragePressRefresh =>
      'Geçerli kullanımı okumak için Yenile\'ye basın.';

  @override
  String get syncStorageEmpty => 'Sunucuda henüz hiçbir şey saklanmıyor.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pakette $size',
      one: '1 pakette $size',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Sayaçlar $first–$last';
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
      other: 'Sayaçlar $first–$last, $snapshots anlık görüntü',
      one: 'Sayaçlar $first–$last, $snapshots anlık görüntü',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Ayrıca $count ek ($size); bir kez saklanır ve onlara başvuran tüm paketlerce paylaşılır.',
      one:
          'Ayrıca 1 ek ($size); bir kez saklanır ve ona başvuran tüm paketlerce paylaşılır.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu cihaz bunların $count tanesini yerel olarak tutuyor ($size).',
      one: 'Bu cihaz bunların $count tanesini yerel olarak tutuyor ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Sunucudaki verileri sıkıştır';

  @override
  String get syncResetIdentity => 'Cihaz kimliğini sıfırla';

  @override
  String get syncNotConfiguredOnDevice =>
      'Bu cihazda eşitleme yapılandırılmamış.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Sunucu depolaması okunamadı: $error';
  }

  @override
  String get syncResetConfirm =>
      'Bu cihaz yeni bir kimlikle eşitlemeye başlayacak ve bir sonraki eşitlemesi geçerli veritabanının tam bir kopyasını yayımlayacak. Diğer cihazlarınız bunu normal şekilde birleştirir — hiçbir şey kaybolmaz.\n\nBunu, eşitleme bu cihazın geçmişinin ayrıştığını bildirdiğinde yapın; bu genellikle veritabanının zaten eşitlendikten sonra bir yedekten geri yüklendiği anlamına gelir.\n\nEski kimlik, sıkıştırma yapana kadar sunucunun depolama listesinde görünmeye devam eder.';

  @override
  String get syncReset => 'Sıfırla';

  @override
  String syncResetFailed(String error) {
    return 'Cihaz kimliği sıfırlanamadı: $error';
  }

  @override
  String get syncCompactConfirm =>
      'Bu cihaz eşitlenecek, ardından tüm veritabanının tek bir anlık görüntüsünü yükleyecek. Sunucu daha sonra anlık görüntünün zaten içerdiği tüm saklanan değişiklikleri siler; her cihaz da anlık görüntüyü aldığında aynısını yapar.\n\nNotlarınız, süreleriniz ve ekleriniz etkilenmez — atılan şey, anlık görüntünün altındaki tek tek geçmiş düzenlemelerin kaydıdır.\n\nÖnce diğer cihazlarınızdaki Noo\'yu güncelleyin: eski bir sürüm, başlangıcı kaldırılmış bir akışı okuyamaz.';

  @override
  String get syncCompact => 'Sıkıştır';

  @override
  String get syncCompactFailed => 'Sıkıştırma başarısız.';

  @override
  String get syncCompactNothing => 'Henüz sıkıştırılacak bir şey yok.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sunucuda $size boşaltıldı ($count paket)',
      one: 'Sunucuda $size boşaltıldı ($count paket)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Anlık görüntü yüklendi, ancak bu sunucu henüz sıkıştırmayı desteklemiyor, bu yüzden kopyalarını tuttu';

  @override
  String get syncCompactRelayNothing =>
      'Anlık görüntü yüklendi; sunucuda atılacak bir şey kalmamıştı';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bu cihazda $size boşaltıldı ($count paket)',
      one: 'Bu cihazda $size boşaltıldı ($count paket)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. Anlık görüntünün kendi boyutu: $size.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. Anlık görüntünün kendi boyutu: $size.';
  }

  @override
  String get syncTestSuccess => 'Başarılı: Sunucuya ulaşılabiliyor';

  @override
  String get syncTestUnreachable => 'Hata: Sunucuya ulaşılamıyor';

  @override
  String syncErrorWith(String error) {
    return 'Hata: $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Hata: Kullanıcı adı ve parola gerekli';

  @override
  String syncRegisterSuccess(String user) {
    return 'Başarılı: \"$user\" hesabı oluşturuldu. Ayarlar kaydedildi.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Başarılı: \"$user\" hesabı sınırsız sunucu depolamasıyla oluşturuldu. Ayarlar kaydedildi.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Başarılı: \"$user\" hesabı oluşturuldu, sunucu depolaması: $size. Ayarlar kaydedildi.';
  }

  @override
  String get syncStagePreparing => 'Hazırlanıyor';

  @override
  String get syncStageAuthenticating => 'Kimlik bilgileri doğrulanıyor';

  @override
  String get syncStagePushing => 'Değişiklikler gönderiliyor';

  @override
  String get syncStageApplying => 'Değişiklikler uygulanıyor';

  @override
  String get syncStatePending => 'Bekliyor';

  @override
  String get syncStateActive => 'Çalışıyor…';

  @override
  String get syncStateDone => 'Tamamlandı';

  @override
  String get syncStateSkipped => 'Atlandı';

  @override
  String get syncStateFailed => 'Başarısız';

  @override
  String get syncCancelling => 'İptal ediliyor…';

  @override
  String get syncSynchronizing => 'Eşitleniyor…';

  @override
  String get syncCancelled => 'Eşitleme iptal edildi';

  @override
  String get syncFailed => 'Eşitleme başarısız';

  @override
  String get syncTitle => 'Eşitleme';

  @override
  String get syncComplete => 'Eşitleme tamamlandı';

  @override
  String get syncNow => 'Şimdi eşitle';

  @override
  String get syncShowFullLogTooltip => 'Tüm günlüğü göster';

  @override
  String get syncShowFullLog => 'Tüm günlüğü göster';

  @override
  String get syncMoreSeeFullLog => 'bkz. Tüm günlüğü göster';

  @override
  String get syncGroupProgress => 'İlerleme';

  @override
  String get syncNoRunYet =>
      'Henüz eşitleme yapılmadı. Eşitlemek için “Şimdi eşitle”yi kullanın; son eşitlemenin ayrıntıları burada görünecek.';

  @override
  String get syncCancelledNote =>
      'İsteğiniz üzerine durduruldu. O ana kadar eşitlenen her şey korunur; bir sonraki eşitleme oradan devam eder.';

  @override
  String get syncGroupSummary => 'Özet';

  @override
  String get syncChangesPushed => 'Gönderilen değişiklikler';

  @override
  String get syncChangesApplied => 'Uygulanan değişiklikler';

  @override
  String get syncGroupApplied => 'Uygulandı — diğer cihazlardan';

  @override
  String get syncGroupPushed => 'Gönderildi — bu cihazdan';

  @override
  String get syncGroupLwwSkipped =>
      'Uygulanmadı — bu cihazda zaten daha yeni bir değer vardı';

  @override
  String get syncGroupUnreadable => 'Okunamadı';

  @override
  String get syncLwwTieNote =>
      'Tam olarak eşleşen zaman damgaları her iki cihazda da olduğu gibi tutulur, bu yüzden ikisi farklı kalır. Saklamak istediğiniz sürümün bulunduğu cihazda ögeyi yeniden düzenleyin.';

  @override
  String get syncLwwOlderNote =>
      'Gelen değer bu cihazdakinden daha eskiydi, bu yüzden yazılmadı. Kazanması gerekiyorduysa iki cihazın saatlerinin uyuştuğunu denetleyin.';

  @override
  String get syncSkewSame => 'aynı zaman damgası';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'yerel $seconds sn ileride',
      one: 'yerel $seconds sn ileride',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'yerel $minutes dk $seconds sn ileride';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'yerel $hours sa $minutes dk ileride';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'yerel $days gün ileride',
      one: 'yerel $days gün ileride',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'gelen $incoming · yerel $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  $stage başarısız  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'Bu paketlerin şifresi çözülemedi; bu, bu veritabanının parolasının paketleri yazan cihazdakinden farklı olduğu anlamına gelir. Eşitleme bunları yeniden denemez: parolaları eşleştirin, ardından etkilenen ögeleri diğer cihazda yeniden kaydedin ki tekrar gönderilsinler.';

  @override
  String get syncSkippedUnreadableNote =>
      'Bu paketler okunamadı ve eşitleme bunları geçti — değişiklikleri kendiliğinden gelmeyecek. Yeniden göndermek için etkilenen ögeleri diğer cihazda yeniden kaydedin.';

  @override
  String get syncP2pNotConfigured =>
      'Eşitleme yapılandırılmamış. Önce Tercihler → Eşitleme bölümünde bir kullanıcı adı belirleyin.';

  @override
  String syncP2pStartFailed(String error) {
    return 'Eşler arası eşitleme başlatılamadı: $error';
  }

  @override
  String get syncP2pStarting => 'Başlatılıyor...';

  @override
  String get syncP2pLooking => 'Bu ağdaki cihazlar aranıyor...';

  @override
  String get syncP2pIntro =>
      'Diğer cihazda da P2P eşitle... penceresini açın. Cihazlar birbirini bulur bulmaz eşitlenir; bu pencere kapatıldığında görünür olmaktan çıkarlar.';

  @override
  String get syncP2pTitle => 'P2P eşitle';

  @override
  String get syncP2pSyncAgain => 'Yeniden eşitle';

  @override
  String get syncP2pFound => 'Bulundu — eşitleme bekleniyor';

  @override
  String get syncP2pSyncing => 'Eşitleniyor...';

  @override
  String get syncP2pUpToDate => 'Eşitlendi — zaten güncel';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Eşitlendi — $count değişiklik alındı',
      one: 'Eşitlendi — 1 değişiklik alındı',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Başarısız — $error';
  }

  @override
  String get syncP2pUnknownError => 'bilinmeyen hata';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return '$device cihazından alınanlar ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return '$device cihazına gönderilenler ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return '$used / $quota kullanılıyor (%$percent)';
  }

  @override
  String get syncQuotaSemantics => 'Kullanılan sunucu depolaması';

  @override
  String get syncQuotaFull =>
      'Dolu: sıkıştırma yapana veya ekleri kaldırana kadar sunucu yeni değişiklikleri reddeder.';

  @override
  String get syncQuotaNearlyFull =>
      'Neredeyse dolu. Sıkıştırma genellikle büyük kısmını boşaltır.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'Eşitleme yapılandırılmamış. Önce eşitleme ayarlarını açın.';

  @override
  String get syncNoServerConfigured =>
      'Eşitleme sunucusu yapılandırılmamış. Yerel eşitleme için \"P2P eşitle...\" komutunu kullanın veya Tercihler → Eşitleme bölümünden bir sunucu ekleyin.';

  @override
  String get syncAlreadyInProgress => 'Eşitleme zaten sürüyor';

  @override
  String get syncAlreadyInProgressSentence => 'Bir eşitleme zaten sürüyor.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done / $totalText değişiklik',
      one: '$done / $totalText değişiklik',
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
      other: '$countText değişiklik · paket $current / $packets',
      one: '$countText değişiklik · paket $current / $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText değişiklik',
      one: '$countText değişiklik',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · yaklaşık $seconds sn kaldı';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · yaklaşık $minutes dk kaldı';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Cihaz akışında çatallanma algılandı: uzak bir düğüm bu cihaz için $remote paket sayacını tutuyor, ancak bu cihaz $local konumunda ve ikisinin öncesinde gelenler konusunda uyuştuğunu doğrulayamıyor (veritabanı bir yedekten mi geri yüklendi?). Eşitlemeye devam etmek için Tercihler → Eşitleme bölümünde \"Cihaz kimliğini sıfırla\" komutunu kullanın.';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Cihaz akışı $counter paket sayacında ayrıştı: bu cihaz ve kaynak ($source) aynı kimlik altında farklı içerik tutuyor (burada $localHash, orada $remoteHash). Bu veritabanı büyük olasılıkla bir yedekten geri yüklendi ve daha önce yayımladığı paket numaralarını yeniden kullandı. Eşitlemeye devam etmek için Tercihler → Eşitleme bölümünde \"Cihaz kimliğini sıfırla\" komutunu kullanın; bu, veritabanını yeni bir kimlikle yeniden yayımlar ve hiçbir şey kaybolmaz.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'Sunucuda bu cihazın geçmişinin bir kısmı eksik: sıradaki paket olarak #$expected bekliyor, ancak bu cihazın hâlâ tuttuğu en eski paket #$local ve aradakiler artık burada değil (sunucu büyük olasılıkla bu cihaz sıkıştırma yaptıktan sonra daha eski bir yedekten geri yüklendi). Eşitlemeye devam etmek için Tercihler → Eşitleme bölümünde \"Cihaz kimliğini sıfırla\" komutunu kullanın; bu, veritabanını yeni bir kimlikle yeniden yayımlar ve hiçbir şey kaybolmaz.';
  }

  @override
  String get syncIdentityReset =>
      'Bu cihaz artık yeni bir kimlikle eşitleniyor. Bir sonraki eşitlemesi geçerli veritabanının tam bir kopyasını yayımlar; diğer tüm cihazlar bunu normal şekilde birleştirir.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihaz artık yeni bir kimlikle eşitleniyor. Bir sonraki eşitlemesi geçerli veritabanının tam bir kopyasını yayımlar; diğer tüm cihazlar bunu normal şekilde birleştirir. Kullanılamayan $count paket atıldı.',
      one:
          'Bu cihaz artık yeni bir kimlikle eşitleniyor. Bir sonraki eşitlemesi geçerli veritabanının tam bir kopyasını yayımlar; diğer tüm cihazlar bunu normal şekilde birleştirir. Kullanılamayan $count paket atıldı.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Şifreleme anahtarı türetiliyor';

  @override
  String get syncDetailSignedIn => 'Zaten oturum açık';

  @override
  String get syncDetailPackaging => 'Yerel değişiklikler paketleniyor';

  @override
  String get syncDetailRecovering => 'Bu cihazın kendi geçmişi kurtarılıyor';

  @override
  String get syncDetailUploading => 'Sunucuya yükleniyor';

  @override
  String get syncDetailNoLocalChanges => 'Yerel değişiklik yok';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik gönderildi',
      one: '1 değişiklik gönderildi',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => 'Uzak değişiklikler indiriliyor';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ek indirildi',
      one: '1 ek indirildi',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İndirilecek $count ek kaldı',
      one: 'İndirilecek 1 ek kaldı',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Zaten güncel';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik uygulandı',
      one: '1 değişiklik uygulandı',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'İptal edildi';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return '\"$name\" eki henüz bu cihaza indirilmedi ve bu cihazın yaptığı bir değişiklik ona başvuruyor; bu yüzden ek gelene kadar bu cihazın değişiklikleri sunucuya ulaşamaz — geldiğinde yeniden eşitleyin veya eki tutan yakındaki bir cihazla eşitleyin.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'Sunucu \"$name\" ekini ($size) çok büyük olduğu için reddetti. Diğer her şey eşitlenir; ekin kendisi diğer cihazlara yalnızca P2P eşitle ile ulaşır.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'Sunucu \"$name\" ekini ($size) çok büyük olduğu için reddetti (sınır: $limit). Diğer her şey eşitlenir; ekin kendisi diğer cihazlara yalnızca P2P eşitle ile ulaşır.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return '\"$name\" eki ($size) sunucu depolamanıza sığmıyor. Diğer her şey eşitlenir; yer açmak için sunucudaki verileri sıkıştırın veya büyük ekleri kaldırın; o zamana kadar ek diğer cihazlara yalnızca P2P eşitle ile ulaşır.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return '\"$name\" eki ($size) sunucu depolamanıza sığmıyor ($used / $quota kullanılıyor). Diğer her şey eşitlenir; yer açmak için sunucudaki verileri sıkıştırın veya büyük ekleri kaldırın; o zamana kadar ek diğer cihazlara yalnızca P2P eşitle ile ulaşır.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bayt',
      one: '$count bayt',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'Eşitleme sunucusu yapılandırılmamış. Sıkıştırma, aktarma sunucusuna bir anlık görüntü yayımlar; yalnızca yakın cihaz eşitlemesiyle geri kazanılacak sunucu depolaması yoktur.';

  @override
  String get syncCompactStageSyncing => 'Sıkıştırma öncesi eşitleniyor';

  @override
  String get syncCompactStageChecking =>
      'Bu cihazın güncel olduğu denetleniyor';

  @override
  String get syncCompactStagePackaging =>
      'Tüm veritabanının anlık görüntüsü paketleniyor';

  @override
  String get syncCompactStageAttachments =>
      'Anlık görüntünün başvurduğu ekler yükleniyor';

  @override
  String get syncCompactStageUploading => 'Anlık görüntü yükleniyor';

  @override
  String get syncCompactStageReclaiming => 'Bu cihazda alan geri kazanılıyor';

  @override
  String get syncCompactStageReadingUsage => 'Sunucu depolaması okunuyor';

  @override
  String syncCompactNeedsSync(String error) {
    return 'Sıkıştırma için önce tamamlanmış bir eşitleme gerekir: $error';
  }

  @override
  String get syncCompactDidNotFinish => 'Sıkıştırma tamamlanmadı.';

  @override
  String get syncCompactRaced =>
      'Başka bir eşitleme önce paketledi. Sıkıştırmayı yeniden deneyin.';

  @override
  String get syncCompactSnapshotMissing =>
      'Anlık görüntü paketlendi ancak yerel depoda değil.';

  @override
  String get syncCompactMissingAttachments =>
      'Bu cihazda hâlâ bazı ekler eksik. Tüm ekler indirilene kadar eşitleyin, ardından sıkıştırın.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Aktarma sunucusu anlık görüntüyü reddetti: $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Sıkıştırma başarısız: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihaz $count paketi okuyamadı ($packets), bu yüzden durumu günlükteki her şeyin birleşimi değil. Sıkıştırma, bu cihazın hiç uygulamadığı paketleri atar.',
      one:
          'Bu cihaz $count paketi okuyamadı ($packets), bu yüzden durumu günlükteki her şeyin birleşimi değil. Sıkıştırma, bu cihazın hiç uygulamadığı paketleri atar.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'Bu cihazda hâlâ eşitlenmemiş düzenlemeler var. Önce eşitleyin, ardından sıkıştırın.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihazda hâlâ bazı ekler eksik (indirilecek $count ek), bu yüzden anlık görüntüsü bunları sağlayamaz ve sunucu bunları atar. Tüm ekler indirilene kadar eşitleyin, ardından sıkıştırın.',
      one:
          'Bu cihazda hâlâ bazı ekler eksik (indirilecek $count ek), bu yüzden anlık görüntüsü bunları sağlayamaz ve sunucu bunları atar. Tüm ekler indirilene kadar eşitleyin, ardından sıkıştırın.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Bu cihaz, $count cihaz için tuttuğu her şeyi henüz uygulamadı. Yeniden eşitleyin, ardından sıkıştırın.',
      one:
          'Bu cihaz, $count cihaz için tuttuğu her şeyi henüz uygulamadı. Yeniden eşitleyin, ardından sıkıştırın.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'Yalnızca yakın cihaz eşitlemesi, silinmiş bir eki başka bir cihazın hâlâ tuttuğunu garanti edemez; bu yüzden hiçbiri serbest bırakılmadı.';

  @override
  String get syncCollectUnsynced =>
      'Bu cihazda sunucunun henüz saklamadığı değişiklikler var. Önce eşitleyin, ardından sıkıştırın.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Anlık görüntü: $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alan — tüm veritabanı',
      one: '$count alan — tüm veritabanı',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Düğüm \"$name\"';
  }

  @override
  String syncSummaryFile(String name) {
    return 'Dosya \"$name\"';
  }

  @override
  String get syncSummaryFileFallback => 'dosya';

  @override
  String get syncSummaryTimeChunk => 'Zaman dilimi';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'yeni adı \"$title\"';
  }

  @override
  String get syncSummaryContentEdited => 'içerik düzenlendi';

  @override
  String get syncSummaryMoved => 'taşındı';

  @override
  String get syncSummaryReordered => 'yeniden sıralandı';

  @override
  String get syncSummaryFlagsChanged => 'bayraklar değişti';

  @override
  String get syncSummaryRenamed => 'yeniden adlandırıldı';

  @override
  String get syncSummaryContentUpdated => 'içerik güncellendi';

  @override
  String syncSummaryFrom(String time) {
    return 'başlangıç $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'bitiş $time';
  }

  @override
  String get syncValueTopLevel => 'üst düzey';

  @override
  String get syncStorageFull =>
      'Sunucu depolaması dolu. Sunucudaki verileri sıkıştırın (Tercihler → Eşitleme → Sunucu depolaması) veya büyük ekleri kaldırın; yüklenmemiş olanlar bu cihazda kalır.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'Sunucu depolaması dolu ($used / $quota kullanılıyor). Sunucudaki verileri sıkıştırın (Tercihler → Eşitleme → Sunucu depolaması) veya büyük ekleri kaldırın; yüklenmemiş olanlar bu cihazda kalır.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'Sunucu bu hesap için başka bir cihaz akışını reddediyor: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'Sunucunun disk alanı tükendi. Hiçbir şey kaybolmadı; daha sonra yeniden eşitleyin.';

  @override
  String syncStorageRefused(String detail) {
    return 'Sunucu daha fazla veri saklamayı reddetti: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'Bu sunucu yeni hesap kabul etmiyor: hesap sınırına ulaştı.';

  @override
  String get syncRegClosed =>
      'Bu sunucu yeni kayıt kabul etmiyor. Bir hesap için sunucunun işletmecisine başvurun.';

  @override
  String get syncRegTaken => 'Bu kullanıcı adı zaten alınmış.';

  @override
  String get syncRegInvalid =>
      'Kullanıcı adı 3–50, sunucu parolası 8–128 karakter olmalıdır.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Bugün bu ağdan çok fazla hesap kaydedildi.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Bugün bu ağdan çok fazla hesap kaydedildi. $wait sonra yeniden deneyin.';
  }

  @override
  String get syncRegTooManyAttempts => 'Çok fazla deneme.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Çok fazla deneme. $wait sonra yeniden deneyin.';
  }

  @override
  String get syncRegBusy => 'Sunucu meşgul. Biraz sonra yeniden deneyin.';

  @override
  String syncRegFailed(int status) {
    return 'Kayıt başarısız (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Kayıt başarısız (HTTP $status): $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saniye',
      one: '$count saniye',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika',
      one: '$count dakika',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat',
      one: '$count saat',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return '$seconds sn içinde yanıt gelmedi: $host';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'Yanıt $seconds sn boyunca durdu: $host';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…ve $count tane daha — $where',
      one: '…ve $count tane daha — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'bkz. Eşitleme günlüğü';

  @override
  String get traceAtTopLevel => 'üst düzeyde';

  @override
  String traceInPath(String path) {
    return 'konum: $path';
  }

  @override
  String get traceRowNew => '(yeni)';

  @override
  String get traceRowRemoved => '(kaldırıldı)';

  @override
  String get traceShowHowTooltip =>
      'Bu değişikliğin nasıl gerçekleştiğini göster';

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
  String get traceDecisionApplied => 'uygulandı';

  @override
  String get traceDecisionCreated => 'burada oluşturuldu';

  @override
  String get traceDecisionConflictCopy =>
      'uygulandı — yerine geçtiği değer çakışma kopyası olarak tutuldu';

  @override
  String get traceDecisionMerged =>
      'burada yapılan düzenlemeyle birleştirildi — iki değişiklik de korundu';

  @override
  String get traceDecisionCycleToRoot =>
      'üst düzeye taşındı — üst ögesi bir döngü oluştururdu';

  @override
  String get traceDecisionParentMissing =>
      'üst ögesi gelene kadar üst düzeye yerleştirildi';

  @override
  String get traceDecisionBlobPending =>
      'uygulandı — ek baytları ayrıca gelecek';

  @override
  String get traceDecisionSent => 'gönderildi';

  @override
  String get traceDecisionForwarded => 'iletildi';

  @override
  String get traceRouteRelay => 'Aktarma sunucusundan indirildi.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Aktarma sunucusundan indirildi; sunucu onu şu tarihte saklamıştı: $time.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Yerel ağ üzerinden iletildi (ileten: $peer, yazan: $author).';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Yerel ağ üzerinden doğrudan geldi: $peer.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Önceki bir alışverişten zaten bu cihazdaydı; bu alışverişte uygulandı.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Zaten bu cihazdaydı — alınma: $time; bu alışverişte uygulandı.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Zaten bu cihazdaydı — alınma: $time, kaynak: $source; bu alışverişte uygulandı.';
  }

  @override
  String get traceRoutePackagedUploaded =>
      'Burada paketlendi ve aktarma sunucusuna yüklendi.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Burada paketlendi; aktarma sunucusu onu başka bir yoldan zaten almıştı.';

  @override
  String get traceRoutePackagedBlocked =>
      'Burada paketlendi; henüz yüklenmedi — gerektirdiği bir ek yüklenemedi.';

  @override
  String get traceRoutePackagedWaiting =>
      'Burada paketlendi; aktarma sunucusunun veya bir eşin almasını bekliyor.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Yerel ağ üzerinden çekildi (çeken: $peer) — $author adına iletildi.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Yerel ağ üzerinden çekildi (çeken: $peer).';
  }

  @override
  String get traceBlobDownloaded => 'şimdi indirildi';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'şimdi indirildi ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'şimdi indirildi, kaynak: $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'şimdi indirildi, kaynak: $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'henüz indirilmedi — sonraki bir eşitlemede veya açıldığında gelecek';

  @override
  String get traceBlobHeld => 'zaten bu cihazda';

  @override
  String get traceBlobUploaded => 'aktarma sunucusuna yüklendi';

  @override
  String traceBlobUploadedSized(String size) {
    return 'aktarma sunucusuna yüklendi ($size)';
  }

  @override
  String get traceBlobOnRelay => 'aktarma sunucusunda zaten vardı';

  @override
  String get traceBlobOffered => 'başkalarının alması için bu cihazda';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'Bir sıkıştırma anlık görüntüsü: tek pakette tüm veritabanı (cihaz: $device).';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Tam durum anlık görüntüsünün parçası (cihaz: $device). Bir anlık görüntü, yazarının tüm veritabanını taşır; bu öge burada farklı olduğu için listeleniyor.';
  }

  @override
  String get traceFieldsHeading => 'Alanlar';

  @override
  String traceTimeEdited(String time) {
    return 'düzenlenme $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'karşı taraf $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'bu cihaz $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Paket $device #$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Paket $device #$counter (anlık görüntü)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'yazılma $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count değişiklik',
      one: '1 değişiklik',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Yazar cihaz $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'cihaz: $id';
  }

  @override
  String get traceCopyHashTooltip => 'Paket özetini kopyala';

  @override
  String get traceAttachmentBytesHeading => 'Ek baytları';

  @override
  String get traceShowInSyncLog => 'Eşitleme günlüğünde göster';

  @override
  String get traceTriggerRelay => 'Sunucu eşitlemesi';

  @override
  String get traceTriggerCheck => 'Gelen değişiklikleri denetle';

  @override
  String get traceTriggerLan => 'Yakın cihazlar';

  @override
  String get traceTriggerLanReturn => 'Yakın cihaz (istendi)';

  @override
  String get traceTriggerLanServe => 'Yakın cihaza sunuldu';

  @override
  String get traceTriggerPackage => 'Yerel değişiklikler paketlendi';

  @override
  String get traceTriggerCompaction => 'Sıkıştırma';

  @override
  String get traceTriggerIdentityReset => 'Cihaz kimliği sıfırlama';

  @override
  String get traceTriggerAttachment => 'Ek indirme';

  @override
  String get traceTriggerBlobCollect => 'Ek temizliği';

  @override
  String get traceOutcomeRunning => 'çalışıyor';

  @override
  String get traceOutcomeFailed => 'başarısız';

  @override
  String get traceOutcomeDeclined => 'reddedildi';

  @override
  String get traceOutcomeBusy => 'meşgul';

  @override
  String get traceOutcomeInterrupted => 'kesildi';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count olay JSON olarak kopyalandı',
      one: '$count olay JSON olarak kopyalandı',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Eşitleme günlüğü temizlensin mi?';

  @override
  String get traceClearBody =>
      'Bu cihazda kaydedilen tüm çalıştırmalar ve olaylar silinir. Eşitlenen veriler etkilenmez.';

  @override
  String get traceTitle => 'Eşitleme günlüğü';

  @override
  String get traceCopyAsJson => 'JSON olarak kopyala';

  @override
  String get traceClearLogTooltip => 'Günlüğü temizle';

  @override
  String get traceClearLogButton => 'Günlüğü temizle';

  @override
  String traceSummaryApplied(int count) {
    return '$count uygulandı';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uyarı',
      one: '1 uyarı',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '1 hata',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Hiçbir şey aktarılmadı';

  @override
  String get traceNoRuns =>
      'Henüz eşitleme kaydedilmedi. Bu cihaz sunucuyla veya yakın cihazlarla eşitlendikçe çalıştırmalar burada görünür.';

  @override
  String get traceAllRuns => 'Tüm çalıştırmalar';

  @override
  String traceRunsRecorded(int count) {
    return '$count kayıtlı';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'Tüm çalıştırmalar ($count)';
  }

  @override
  String get traceRunLabel => 'Çalıştırma';

  @override
  String get traceSearchHint => 'Ara: düğüm adı, kimlik, özet, cihaz, tür…';

  @override
  String get traceLevelAll => 'Tümü';

  @override
  String get traceLevelWarnings => 'Uyarılar';

  @override
  String get traceLevelErrors => 'Hatalar';

  @override
  String get traceDirectionAll => 'Gelen ve giden';

  @override
  String get traceDirectionIncoming => 'Gelen';

  @override
  String get traceDirectionOutgoing => 'Giden';

  @override
  String get traceDirectionLocal => 'Yerel';

  @override
  String get traceNoEvents => 'Eşleşen olay yok.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'İlk $count olay gösteriliyor. Geri kalanını görmek için aramayı daraltın veya bir çalıştırma seçin.',
      one:
          'İlk $count olay gösteriliyor. Geri kalanını görmek için aramayı daraltın veya bir çalıştırma seçin.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Çalıştırma #$id';
  }

  @override
  String get traceEmptyValue => '(boş)';

  @override
  String traceSubHash(String hash) {
    return 'özet $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'değer $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'uzak $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'yerel $time';
  }

  @override
  String get traceDetailAt => 'Zaman';

  @override
  String get traceDetailDirection => 'Yön';

  @override
  String get traceDetailOriginDevice => 'Kaynak cihaz';

  @override
  String get traceDetailCounter => 'Sayaç';

  @override
  String get traceDetailHash => 'Paket / blob özeti';

  @override
  String get traceDetailEntity => 'Varlık';

  @override
  String get traceDetailWorldId => 'World id';

  @override
  String get traceDetailName => 'Ad';

  @override
  String get traceDetailField => 'Alan';

  @override
  String get traceDetailRemoteTs => 'Uzak zaman damgası';

  @override
  String get traceDetailLocalTs => 'Yerel zaman damgası';

  @override
  String get traceDetailValueHash => 'Değer özeti';

  @override
  String get traceDetailValuePreview => 'Değer önizlemesi';

  @override
  String get traceDetailMessage => 'İleti';

  @override
  String get traceDetailDetail => 'Ayrıntı';
}
