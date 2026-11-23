// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appMenuFile => 'Файл';

  @override
  String get appMenuEdit => 'Правка';

  @override
  String get appMenuView => 'Вид';

  @override
  String get appMenuTools => 'Инструменты';

  @override
  String get appMenuDebug => 'Отладка';

  @override
  String get appMenuHelp => 'Справка';

  @override
  String get appMenuWindow => 'Окно';

  @override
  String get appMenuOpen => 'Открыть...';

  @override
  String get appMenuOpenDatabase => 'Открыть базу данных...';

  @override
  String get appMenuNewDatabase => 'Новая база данных...';

  @override
  String get appMenuExportObsidian => 'Экспорт в Obsidian...';

  @override
  String get appMenuImportObsidian => 'Импорт из Obsidian...';

  @override
  String get appMenuExit => 'Выход';

  @override
  String get appMenuFind => 'Найти...';

  @override
  String get appMenuTheme => 'Тема';

  @override
  String get appMenuThemeEllipsis => 'Тема...';

  @override
  String get appThemeSystem => 'Системная';

  @override
  String get appThemeLight => 'Светлая';

  @override
  String get appThemeDark => 'Тёмная';

  @override
  String get appMenuTimeline => 'Хронология...';

  @override
  String get appMenuTimeReport => 'Отчёт по времени...';

  @override
  String get appMenuCompactDatabase => 'Сжать базу данных...';

  @override
  String get appMenuSyncNow => 'Синхронизировать';

  @override
  String get appMenuSyncP2p => 'Синхронизация P2P...';

  @override
  String get appMenuPreferences => 'Настройки...';

  @override
  String get appMenuViewChangeHistory => 'История изменений...';

  @override
  String get appMenuGenerateTestData => 'Создать тестовые данные';

  @override
  String get appMenuGenerateLargeDataset => 'Создать большой набор данных';

  @override
  String get appMenuClearAllData => 'Удалить все данные';

  @override
  String get appMenuCheckForUpdate => 'Проверить обновления...';

  @override
  String get appMenuLogs => 'Журналы';

  @override
  String get appMenuSyncLog => 'Журнал синхронизации...';

  @override
  String get appMenuAppLog => 'Журнал приложения...';

  @override
  String appMenuAbout(String appName) {
    return 'О программе $appName';
  }

  @override
  String get appMacMenuCheckForUpdate => 'Проверить обновления…';

  @override
  String get appMacMenuSettings => 'Настройки…';

  @override
  String appMacMenuQuit(String appName) {
    return 'Завершить $appName';
  }

  @override
  String get appMacMenuOpen => 'Открыть…';

  @override
  String get appMacMenuNewDatabase => 'Новая база данных…';

  @override
  String get appMacMenuExportObsidian => 'Экспорт в Obsidian…';

  @override
  String get appMacMenuImportObsidian => 'Импорт из Obsidian…';

  @override
  String get appMacMenuUndo => 'Отменить';

  @override
  String get appMacMenuRedo => 'Повторить';

  @override
  String get appMacMenuCut => 'Вырезать';

  @override
  String get appMacMenuPaste => 'Вставить';

  @override
  String get appMacMenuSelectAll => 'Выбрать все';

  @override
  String get appMacMenuFind => 'Найти…';

  @override
  String get appMacMenuTimeline => 'Хронология…';

  @override
  String get appMacMenuTimeReport => 'Отчёт по времени…';

  @override
  String get appMacMenuCompactDatabase => 'Сжать базу данных…';

  @override
  String get appMacMenuSyncP2p => 'Синхронизация P2P…';

  @override
  String get appMacMenuViewChangeHistory => 'История изменений…';

  @override
  String get appMacMenuSyncLog => 'Журнал синхронизации…';

  @override
  String get appMacMenuAppLog => 'Журнал приложения…';

  @override
  String appMacMenuChecked(String label) {
    return '✓ $label';
  }

  @override
  String get appOpenDatabaseDialogTitle => 'Открыть базу данных';

  @override
  String get appCreateDatabaseDialogTitle => 'Создать базу данных';

  @override
  String get appIncorrectPasswordRetry =>
      'Неверный пароль. Попробуйте ещё раз.';

  @override
  String appDatabaseOpened(String fileName) {
    return 'Открыто: $fileName';
  }

  @override
  String appOpenDatabaseFailed(String error) {
    return 'Не удалось открыть базу данных: $error';
  }

  @override
  String appDatabaseCreated(String fileName) {
    return 'Создано: $fileName';
  }

  @override
  String appCreateDatabaseFailed(String error) {
    return 'Не удалось создать базу данных: $error';
  }

  @override
  String get appOpenDatabaseFirst => 'Сначала откройте базу данных';

  @override
  String get appNoDatabaseOpen => 'База данных не открыта';

  @override
  String appCannotReadDatabaseFile(String error) {
    return 'Не удаётся прочитать файл базы данных: $error';
  }

  @override
  String get appWrongPasswordOrCorrupt =>
      'Неверный пароль или база данных повреждена';

  @override
  String get appExportObsidianDialogTitle => 'Экспорт в папку Obsidian';

  @override
  String get appImportObsidianDialogTitle => 'Импорт из папки Obsidian';

  @override
  String get appImportObsidianZipDialogTitle => 'Импорт .zip из Obsidian';

  @override
  String get appExportingObsidian => 'Экспорт в формат Obsidian...';

  @override
  String get appImportingObsidian => 'Импорт из формата Obsidian...';

  @override
  String appCountTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count задачи',
      many: '$count задач',
      few: '$count задачи',
      one: '$count задача',
    );
    return '$_temp0';
  }

  @override
  String appCountTimelineFiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count файла хронологии',
      many: '$count файлов хронологии',
      few: '$count файла хронологии',
      one: '$count файл хронологии',
    );
    return '$_temp0';
  }

  @override
  String appCountImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изображения',
      many: '$count изображений',
      few: '$count изображения',
      one: '$count изображение',
    );
    return '$_temp0';
  }

  @override
  String appCountTimeRecords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи времени',
      many: '$count записей времени',
      few: '$count записи времени',
      one: '$count запись времени',
    );
    return '$_temp0';
  }

  @override
  String appExportResult(String tasks, String timelineFiles, String images) {
    return 'Экспортировано: $tasks, $timelineFiles, $images';
  }

  @override
  String appImportResult(String tasks, String timeRecords) {
    return 'Импортировано: $tasks, $timeRecords';
  }

  @override
  String appExportFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String appImportFailed(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String appObsidianExportShareTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Экспорт Obsidian ($count задачи)',
      many: 'Экспорт Obsidian ($count задач)',
      few: 'Экспорт Obsidian ($count задачи)',
      one: 'Экспорт Obsidian ($count задача)',
    );
    return '$_temp0';
  }

  @override
  String appDirectoryDoesNotExist(String path) {
    return 'Папка не существует: $path';
  }

  @override
  String get appSyncNotConfigured =>
      'Синхронизация не настроена. Сначала откройте настройки синхронизации.';

  @override
  String get appNoSyncServer =>
      'Сервер синхронизации не настроен. Используйте «Синхронизация P2P...» (Shift+F5) или добавьте сервер в настройках.';

  @override
  String get appUnsyncedChangesTitle => 'Несинхронизированные изменения';

  @override
  String get appUnsyncedChangesBody =>
      'Есть несинхронизированные изменения. Синхронизировать их?';

  @override
  String get appDontSync => 'Не синхронизировать';

  @override
  String get appSync => 'Синхронизировать';

  @override
  String get appSelectTaskFirst => 'Сначала выберите задачу';

  @override
  String get appGenerateTestDataBody =>
      'Будут созданы примеры задач с иерархией и записями времени.\n\nПродолжить?';

  @override
  String get appGenerate => 'Создать';

  @override
  String get appTestDataGenerated => 'Тестовые данные созданы';

  @override
  String get appGenerateLargeDatasetBody =>
      'Будет создан большой набор данных:\n- 20 задач верхнего уровня\n- до 5 уровней вложенности\n- до 6 дочерних задач у каждой\n- записи времени для многих задач\n\nЭто может занять некоторое время. Продолжить?';

  @override
  String get appGeneratingData => 'Создание данных...';

  @override
  String get appLargeDatasetGenerated => 'Большой набор данных создан';

  @override
  String get appClearAllDataBody =>
      'Все задачи, записи времени и вложения будут удалены безвозвратно.\n\nЭто действие нельзя отменить. Вы уверены?';

  @override
  String get appDeleteAll => 'Удалить всё';

  @override
  String get appAllDataCleared => 'Все данные удалены';

  @override
  String get appCompactDatabaseTitle => 'Сжатие базы данных';

  @override
  String get appCompactDatabaseBody =>
      'Файл базы данных будет перезаписан, и место, занятое удалёнными задачами, вложениями и старой историей изменений, вернётся на диск.\n\nСодержимое удалённых вложений тоже освобождается; если вы восстановите такое вложение, оно будет снова загружено с сервера.\n\nНичего из того, что вы видите, не удаляется. Для большой базы данных это займёт время, и пользоваться приложением до окончания нельзя.';

  @override
  String get appCompact => 'Сжать';

  @override
  String get appCompactingDatabase => 'Сжатие базы данных...';

  @override
  String appCompactingFailed(String error) {
    return 'Ошибка сжатия: $error';
  }

  @override
  String get appDatabaseCompacted => 'База данных сжата';

  @override
  String appDatabaseCompactedFreed(String freed, String size) {
    return 'База данных сжата — освобождено $freed (теперь $size)';
  }

  @override
  String appDatabaseCompactedAlready(String size) {
    return 'База данных сжата — уже была компактной ($size)';
  }

  @override
  String appDatabaseCompactedWithNote(String result, String note) {
    return '$result. $note';
  }

  @override
  String get appFindTooltip => 'Найти';

  @override
  String get appSyncNowTooltip => 'Синхронизировать';

  @override
  String get appBiometricFailed =>
      'Биометрическая проверка не пройдена. Введите пароль.';

  @override
  String get appSavedPasswordIncorrect =>
      'Сохранённый пароль неверен. Введите пароль.';

  @override
  String get appLoading => 'Загрузка...';

  @override
  String get appFailedToOpenDatabaseTitle => 'Не удалось открыть базу данных';

  @override
  String get appOpenAnotherDatabase => 'Открыть другую базу данных…';

  @override
  String get appBiometricReason => 'Разблокировка базы данных Noo';

  @override
  String appWelcomeTitle(String appName) {
    return 'Добро пожаловать в $appName';
  }

  @override
  String get appWelcomeIntro =>
      'Выберите, где хранить зашифрованную базу данных. Позже это можно изменить в меню «Файл».';

  @override
  String get appUseDefaultLocation => 'Использовать расположение по умолчанию';

  @override
  String get appResolving => 'Определение…';

  @override
  String get appCreateNewDatabaseOption => 'Создать базу данных…';

  @override
  String get appCreateNewDatabaseSubtitle =>
      'Выбрать расположение для новой зашифрованной базы данных.';

  @override
  String get appOpenExistingDatabaseOption =>
      'Открыть существующую базу данных…';

  @override
  String get appOpenExistingDatabaseSubtitle =>
      'Использовать существующий файл .noo из другого места.';

  @override
  String get appQuit => 'Выход';

  @override
  String get appWelcomeSyncHint =>
      'Уже есть база данных на другом устройстве? Создайте здесь новую с тем же паролем, затем настройте синхронизацию в разделе «Настройки → Синхронизация» с тем же именем пользователя — заметки появятся после первой синхронизации.';

  @override
  String get appTaskFallbackTitle => 'Задача';

  @override
  String get appTabNotes => 'Заметка';

  @override
  String get appTabTime => 'Время';

  @override
  String get appTabFiles => 'Файлы';

  @override
  String appTabFilesCount(int count) {
    return 'Файлы ($count)';
  }

  @override
  String get appStartTracking => 'Начать учёт времени';

  @override
  String get appStopTracking => 'Остановить учёт времени';

  @override
  String get appNoTaskSelected => 'Задача не выбрана.';

  @override
  String get appAttachmentsHeading => 'Вложения';

  @override
  String get appModified => 'Изменено';

  @override
  String get appWordWrapOnTooltip =>
      'Перенос строк включён — нажмите, чтобы выключить';

  @override
  String get appWordWrapOffTooltip =>
      'Перенос строк выключен — нажмите, чтобы включить';

  @override
  String get appTimeTodayTap => 'Время за сегодня — нажмите, чтобы открыть';

  @override
  String get appHideTimeTracking => 'Скрыть учёт времени';

  @override
  String get appTimeTodayClick => 'Время за сегодня — нажмите для подробностей';

  @override
  String get appViewTimeline => 'Показать хронологию';

  @override
  String get appAttachmentsTap => 'Вложения — нажмите, чтобы открыть';

  @override
  String get appHideAttachments => 'Скрыть вложения';

  @override
  String get appAttachmentsClick => 'Вложения — нажмите, чтобы показать';

  @override
  String get appAddAttachment => 'Добавить вложение';

  @override
  String get appUntitledInPath => '(без названия)';

  @override
  String get appSyncStatusDisabled =>
      'Синхронизация выключена — нажмите, чтобы синхронизировать';

  @override
  String get appSyncStatusUnknown =>
      'Ещё не синхронизировано — нажмите, чтобы синхронизировать';

  @override
  String get appSyncStatusIdle =>
      'Синхронизировано — нажмите, чтобы синхронизировать';

  @override
  String get appSyncStatusSyncing => 'Синхронизация...';

  @override
  String get appSyncStatusError =>
      'Ошибка синхронизации — нажмите, чтобы повторить';

  @override
  String get appSyncStatusPending =>
      'Есть несинхронизированные изменения — нажмите, чтобы синхронизировать';

  @override
  String get appSyncStatusIncoming =>
      'Другие устройства прислали изменения — нажмите, чтобы синхронизировать';

  @override
  String appTrackingChipTooltip(String title) {
    return 'Идёт учёт времени для «$title» — нажмите, чтобы перейти';
  }

  @override
  String appStopTrackingTask(String title) {
    return 'Остановить учёт времени для «$title»';
  }

  @override
  String appTrackingMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String appPendingMore(int count) {
    return 'и ещё $count';
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
      other: '$count объекта',
      many: '$count объектов',
      few: '$count объекта',
      one: '$count объект',
    );
    return '$_temp0';
  }

  @override
  String appCountChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения',
      many: '$count изменений',
      few: '$count изменения',
      one: '$count изменение',
    );
    return '$_temp0';
  }

  @override
  String appPendingSummary(String items, String changes) {
    return 'Ожидают синхронизации: $items, $changes';
  }

  @override
  String get appPendingFieldTitle => 'название';

  @override
  String get appPendingFieldContent => 'содержимое';

  @override
  String get appPendingFieldMoved => 'перемещено';

  @override
  String get appPendingFieldReordered => 'порядок';

  @override
  String get appPendingFieldFlags => 'флаги';

  @override
  String get appPendingFieldDeleted => 'удалено';

  @override
  String get appPendingFieldName => 'имя';

  @override
  String get appPendingFieldStartTime => 'время начала';

  @override
  String get appPendingFieldEndTime => 'время окончания';

  @override
  String get appJustNow => 'только что';

  @override
  String appMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count мин назад',
      many: '$count мин назад',
      few: '$count мин назад',
      one: '$count мин назад',
    );
    return '$_temp0';
  }

  @override
  String appHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ч назад',
      many: '$count ч назад',
      few: '$count ч назад',
      one: '$count ч назад',
    );
    return '$_temp0';
  }

  @override
  String appDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count д назад',
      many: '$count д назад',
      few: '$count д назад',
      one: '$count д назад',
    );
    return '$_temp0';
  }

  @override
  String get appEnterPasswordTitle => 'Введите пароль';

  @override
  String get appSetDatabasePasswordTitle => 'Пароль базы данных';

  @override
  String get appPasswordLabel => 'Пароль';

  @override
  String get appConfirmPasswordLabel => 'Подтверждение пароля';

  @override
  String get appPleaseEnterPassword => 'Введите пароль';

  @override
  String get appPasswordTooShort =>
      'Пароль должен содержать не менее 4 символов';

  @override
  String get appPasswordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get appPasswordWarning =>
      'Пароль используется для шифрования базы данных. Если вы его забудете, данные восстановить не удастся.';

  @override
  String get appCreate => 'Создать';

  @override
  String get appStrengthVeryWeak => 'Очень слабый';

  @override
  String get appStrengthWeak => 'Слабый';

  @override
  String get appStrengthFair => 'Средний';

  @override
  String get appStrengthGood => 'Хороший';

  @override
  String get appStrengthStrong => 'Надёжный';

  @override
  String get appTagline => 'Компактный аутлайнер с учётом времени';

  @override
  String get appAboutDescription =>
      'Кроссплатформенный аутлайнер для упорядочивания мыслей, задач и проектов со встроенным учётом времени.';

  @override
  String get appBuiltWithFlutter => 'Создано на Flutter';

  @override
  String get appCheckForUpdateTitle => 'Проверка обновлений';

  @override
  String appCouldNotOpen(String url) {
    return 'Не удалось открыть $url';
  }

  @override
  String get appOpenReleasePage => 'Открыть страницу выпуска';

  @override
  String get appDownloadApk => 'Скачать APK';

  @override
  String get appDownloadDiskImage => 'Скачать образ диска';

  @override
  String get appCheckingForUpdate => 'Проверка наличия новой версии...';

  @override
  String get appUpdateCheckFailed => 'Не удалось проверить обновления';

  @override
  String appUpToDate(String appName, String version) {
    return '$appName $version — последняя версия.';
  }

  @override
  String appUpdateAvailable(String appName, String version, String installed) {
    return 'Доступна версия $appName $version (установлена $installed).';
  }

  @override
  String appDownloadingUpdate(String appName, String version) {
    return 'Загрузка $appName $version...';
  }

  @override
  String appDownloadProgress(String received, String total) {
    return '$received из $total';
  }

  @override
  String appUpdateReadyToInstall(String appName, String version) {
    return '$appName $version загружена и проверена. При установке $appName закроется, файлы программы будут заменены, и программа запустится снова. Базы данных не затрагиваются.';
  }

  @override
  String appUpdateInstalled(String appName, String version) {
    return '$appName $version установлена. Перезапустите программу, чтобы начать работу с новой версией.';
  }

  @override
  String get appLater => 'Позже';

  @override
  String get appInstall => 'Установить';

  @override
  String get appInstallAndRestart => 'Установить и перезапустить';

  @override
  String get appRestartNow => 'Перезапустить';

  @override
  String get appUpdGithubTimeout => 'GitHub не ответил вовремя';

  @override
  String appUpdCannotReachGithub(String error) {
    return 'Не удаётся связаться с GitHub: $error';
  }

  @override
  String appUpdGithubStatus(int status) {
    return 'GitHub вернул код $status при запросе последнего выпуска';
  }

  @override
  String appUpdUnexpectedDataDetail(String error) {
    return 'Неожиданные данные о выпуске: $error';
  }

  @override
  String get appUpdUnexpectedData => 'Неожиданные данные о выпуске';

  @override
  String get appUpdNoInPlace =>
      'На этой платформе обновление на месте недоступно';

  @override
  String appUpdNoWindowsInstaller(String version) {
    return 'В выпуске $version нет установщика для Windows';
  }

  @override
  String appUpdNoWindowsZip(String version) {
    return 'В выпуске $version нет ZIP-архива для Windows';
  }

  @override
  String appUpdCannotWrite(String path) {
    return 'Нет доступа на запись в $path; скачайте новую версию вручную';
  }

  @override
  String appUpdZipMissingExe(String fileName, String path) {
    return '$fileName не содержит $path';
  }

  @override
  String appUpdInvalidZip(String error) {
    return 'Загруженный файл не является корректным ZIP-архивом: $error';
  }

  @override
  String appUpdUnsafeZipPath(String path) {
    return 'ZIP-архив содержит небезопасный путь: $path';
  }

  @override
  String appUpdCannotUnpack(String error) {
    return 'Не удаётся распаковать загруженный файл: $error';
  }

  @override
  String get appUpdNotAppImage => 'Программа запущена не из AppImage';

  @override
  String appUpdNoAppImage(String version) {
    return 'В выпуске $version нет AppImage для Linux';
  }

  @override
  String appUpdCannotChmod(String error) {
    return 'Не удаётся сделать новый AppImage исполняемым: $error';
  }

  @override
  String appUpdCannotReplace(String path, String error) {
    return 'Не удаётся заменить $path: $error';
  }

  @override
  String appUpdDownloadFailed(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String appUpdDownloadStatus(int status) {
    return 'Ошибка загрузки: сервер вернул код $status';
  }

  @override
  String appUpdCannotSave(String error) {
    return 'Не удаётся сохранить загруженный файл: $error';
  }

  @override
  String appUpdInterrupted(String error) {
    return 'Загрузка прервана: $error';
  }

  @override
  String get appUpdChecksumMismatch =>
      'Загруженный файл не соответствует опубликованной контрольной сумме';

  @override
  String appUpdNoChecksums(String version) {
    return 'Для выпуска $version не опубликованы контрольные суммы; скачайте его вручную';
  }

  @override
  String get appUpdChecksumTimeout => 'Истекло время загрузки контрольных сумм';

  @override
  String appUpdChecksumFailed(String error) {
    return 'Ошибка загрузки контрольных сумм: $error';
  }

  @override
  String appUpdChecksumStatus(int status) {
    return 'Ошибка загрузки контрольных сумм: сервер вернул код $status';
  }

  @override
  String appUpdNotListed(String fileName, String checksumsFile) {
    return '$fileName отсутствует в $checksumsFile';
  }

  @override
  String get appLogCopied => 'Журнал приложения скопирован в буфер обмена';

  @override
  String get appLogTitle => 'Журнал приложения';

  @override
  String get appLogSaveDialogTitle => 'Сохранить журнал приложения';

  @override
  String appSavedTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String appSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get appShare => 'Поделиться';

  @override
  String get appClearLogTooltip => 'Очистить журнал';

  @override
  String get appClearLogButton => 'Очистить журнал';

  @override
  String get appSaveEllipsis => 'Сохранить...';

  @override
  String get appSearchHint => 'Поиск';

  @override
  String get appLogLevelAll => 'Все';

  @override
  String get appLogLevelWarnings => 'Предупреждения и ошибки';

  @override
  String get appLogLevelErrors => 'Ошибки';

  @override
  String get appLogEmpty => 'В журнале пока ничего нет.';

  @override
  String get appLogNoMatch => 'Нет подходящих строк.';

  @override
  String get appHistoryTitle => 'История изменений';

  @override
  String get appHistoryFilter => 'Фильтр: ';

  @override
  String appHistoryAll(int count) {
    return 'Все ($count)';
  }

  @override
  String appHistoryTasks(int count) {
    return 'Задачи ($count)';
  }

  @override
  String appHistoryFiles(int count) {
    return 'Файлы ($count)';
  }

  @override
  String appHistoryTimeline(int count) {
    return 'Хронология ($count)';
  }

  @override
  String appHistoryError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get appHistoryEmpty => 'Записи истории не найдены';

  @override
  String appHistoryFieldsChanged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Изменено $count поля',
      many: 'Изменено $count полей',
      few: 'Изменено $count поля',
      one: 'Изменено $count поле',
      zero: 'Изменено 0 полей',
    );
    return '$_temp0';
  }

  @override
  String appHistoryShowing(int shown, int total, int changes) {
    return 'Показано $shown из $total групп записей (всего изменений полей: $changes)';
  }

  @override
  String get appHistoryOld => 'Было:';

  @override
  String get appHistoryNew => 'Стало:';

  @override
  String get commonOk => 'ОК';

  @override
  String get commonCancel => 'Отмена';

  @override
  String get commonClose => 'Закрыть';

  @override
  String get commonSave => 'Сохранить';

  @override
  String get commonSaveAs => 'Сохранить как...';

  @override
  String get commonDelete => 'Удалить';

  @override
  String get commonRename => 'Переименовать';

  @override
  String get commonRemove => 'Убрать';

  @override
  String get commonAdd => 'Добавить';

  @override
  String get commonOpen => 'Открыть';

  @override
  String get commonCopy => 'Копировать';

  @override
  String get commonApply => 'Применить';

  @override
  String get commonRetry => 'Повторить';

  @override
  String get commonYes => 'Да';

  @override
  String get commonNo => 'Нет';

  @override
  String get commonBrowse => 'Обзор...';

  @override
  String get commonError => 'Ошибка';

  @override
  String get commonShow => 'Показать';

  @override
  String get commonHide => 'Скрыть';

  @override
  String get commonClear => 'Очистить';

  @override
  String get commonRefresh => 'Обновить';

  @override
  String get commonTest => 'Проверить';

  @override
  String get commonDownload => 'Скачать';

  @override
  String get commonNone => 'Нет';

  @override
  String get commonSystemDefault => 'По умолчанию в системе';

  @override
  String get commonUntitled => 'Без названия';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get editorImageNotAvailable => 'Изображение недоступно';

  @override
  String get editorImageResize => 'Изменить размер...';

  @override
  String get editorImageReplace => 'Заменить изображение...';

  @override
  String get editorImageSaveAs => 'Сохранить изображение как...';

  @override
  String get editorImageRemoveFromText => 'Убрать из текста';

  @override
  String get editorImageRemoveFromTextHint => 'Файл остаётся во вложениях';

  @override
  String get editorImageDelete => 'Удалить изображение';

  @override
  String get editorImageDeleteHint => 'Также удаляет вложение';

  @override
  String get editorImageKeptInOtherTask =>
      'Изображение убрано из текста. Файл принадлежит другой задаче и остался в ней.';

  @override
  String get editorResizeImageTitle => 'Размер изображения';

  @override
  String get editorResizeWidth => 'Ширина';

  @override
  String editorResizePercentOf(int percent, int natural) {
    return '$percent% от $natural пикс.';
  }

  @override
  String get editorResizeOriginalSize => 'Исходный размер';

  @override
  String get editorInsertImage => 'Вставить изображение';

  @override
  String get editorReplaceImageDialogTitle => 'Заменить изображение';

  @override
  String get editorSaveImageDialogTitle => 'Сохранить изображение';

  @override
  String editorSavedFile(String name) {
    return 'Сохранено: $name';
  }

  @override
  String get editorAttachFileTooltipCompact =>
      'Прикрепить файл\n(долгое нажатие — показать вложения)';

  @override
  String get editorAttachFileTooltip =>
      'Прикрепить файл\n(долгое нажатие — показать или скрыть вложения)';

  @override
  String get editorStopRecording => 'Остановить запись';

  @override
  String get editorRecordVoiceMemo => 'Записать голосовую заметку';

  @override
  String get editorRecordVoiceMemoTooltip =>
      'Записать голосовую заметку\n(долгое нажатие — записать без распознавания)';

  @override
  String editorAttachedOne(String name) {
    return 'Прикреплён файл $name';
  }

  @override
  String editorAttachedMany(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Прикреплено $count файла',
      many: 'Прикреплено $count файлов',
      few: 'Прикреплено $count файла',
      one: 'Прикреплён $count файл',
    );
    return '$_temp0';
  }

  @override
  String get editorFontFamily => 'Шрифт';

  @override
  String get editorFontSize => 'Размер шрифта';

  @override
  String get editorSizeLabel => 'Размер';

  @override
  String get editorSizeSmall => 'Мелкий';

  @override
  String get editorSizeLarge => 'Крупный';

  @override
  String get editorSizeHuge => 'Огромный';

  @override
  String get editorStartTyping => 'Начните печатать...';

  @override
  String get editorLinkedTaskGone =>
      'Задача, на которую указывает ссылка, больше не существует.';

  @override
  String get editorRemoveFormatting => 'Очистить форматирование';

  @override
  String editorFormatAsTable(String separator) {
    return 'Оформить как таблицу ($separator)';
  }

  @override
  String get editorWordWrapOff => 'Выключить перенос строк';

  @override
  String get editorWordWrapOn => 'Включить перенос строк';

  @override
  String editorErrorMessage(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get editorTaskNotFound => 'Задача не найдена';

  @override
  String get editorSelectTask => 'Выберите задачу для редактирования';

  @override
  String editorSaveFailed(String error) {
    return 'Не удалось сохранить задачу: $error';
  }

  @override
  String get editorChangesMerged =>
      'Пока вы редактировали эту заметку, она была изменена в другом месте. Оба изменения объединены.';

  @override
  String editorConflictCopyKept(String copyTitle) {
    return 'Пока вы редактировали эту заметку, она была изменена в другом месте. Ваш текст сохранён; другая версия сохранена как «$copyTitle».';
  }

  @override
  String get treeNewTask => 'Новая задача (Ctrl+N)';

  @override
  String get treeNewChildTask => 'Новая дочерняя задача (Ctrl+Shift+N)';

  @override
  String get treeDeleteTask => 'Удалить задачу';

  @override
  String get treeExpandAll => 'Развернуть все';

  @override
  String get treeCollapseAll => 'Свернуть все';

  @override
  String get treeNoTasks => 'Задач пока нет';

  @override
  String get treeCreateFirstTask => 'Создать первую задачу';

  @override
  String get treeTrackedHere => 'По этой задаче идёт учёт времени';

  @override
  String get treeTrackedInside => 'Идёт учёт времени по вложенной задаче';

  @override
  String get treeHiddenFromAgents =>
      'Скрыто от ИИ-агентов вместе со всем содержимым';

  @override
  String get treeMoveUp => 'Переместить вверх';

  @override
  String get treeMoveDown => 'Переместить вниз';

  @override
  String get treeMoveToParentLevel => 'На уровень выше';

  @override
  String get treeMoveUnderPrevious => 'Вложить в предыдущую';

  @override
  String get treeAddChildTask => 'Добавить дочернюю задачу';

  @override
  String get treeStartTracking => 'Начать учёт времени';

  @override
  String get treeStopTracking => 'Остановить учёт времени';

  @override
  String get treeTimeline => 'Хронология...';

  @override
  String get searchHint => 'Поиск задач...';

  @override
  String searchResultCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count результата',
      many: '$count результатов',
      few: '$count результата',
      one: '$count результат',
    );
    return '$_temp0';
  }

  @override
  String get searchNoMatches => 'Совпадений нет';

  @override
  String get searchUntitled => '(без названия)';

  @override
  String get attachImageNotAvailable => 'Изображение недоступно';

  @override
  String get attachTryAgain => 'Повторить';

  @override
  String get attachPlay => 'Воспроизвести';

  @override
  String get attachPause => 'Пауза';

  @override
  String attachLoadFailed(String error) {
    return 'Не удалось загрузить вложения: $error';
  }

  @override
  String get attachNone => 'Нет вложений';

  @override
  String get attachAddFile => 'Добавить файл';

  @override
  String get attachNotDownloaded =>
      'Это вложение ещё не загружено — выполните синхронизацию, чтобы получить его';

  @override
  String get attachContentLoadFailed =>
      'Не удалось загрузить содержимое вложения';

  @override
  String get attachDownloading => 'Загрузка вложения…';

  @override
  String get attachExportDialogTitle => 'Экспорт вложения';

  @override
  String attachExported(String name) {
    return 'Экспортировано: $name';
  }

  @override
  String attachNoAppCanOpen(String name) {
    return 'Нет приложения, которое может открыть $name';
  }

  @override
  String get attachImageInNoteTitle => 'Изображение используется в заметке';

  @override
  String attachImageInNoteBody(String name) {
    return '«$name» показано в заметке этой задачи, поэтому его нельзя удалить отсюда.\n\nНажмите на изображение в заметке и выберите «Удалить изображение», чтобы удалить и картинку, и файл, или «Убрать из текста», чтобы сохранить файл и затем удалить его здесь.';
  }

  @override
  String get attachDeleteTitle => 'Удалить вложение?';

  @override
  String attachDeleteConfirm(String name) {
    return 'Вы действительно хотите удалить «$name»?';
  }

  @override
  String get attachRenameTitle => 'Переименование вложения';

  @override
  String get attachFileName => 'Имя файла';

  @override
  String get attachShowPreview => 'Показать предпросмотр';

  @override
  String get attachHidePreview => 'Скрыть предпросмотр';

  @override
  String get attachShare => 'Поделиться';

  @override
  String get attachExport => 'Экспорт';

  @override
  String get attachTranscribe => 'Распознать речь';

  @override
  String get attachCannotPlay => 'Не удаётся воспроизвести этот файл';

  @override
  String get attachPlaybackUnavailable => 'Воспроизведение недоступно';

  @override
  String voiceStoppedAtLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'Запись остановлена: достигнут лимит в $_temp0. Заметка сохранена.';
  }

  @override
  String voiceReachedLimit(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минуту',
    );
    return 'Достигнут лимит в $_temp0';
  }

  @override
  String get voiceDismiss => 'Закрыть';

  @override
  String get voiceOpeningMic => 'Включение микрофона…';

  @override
  String get voiceSaving => 'Сохранение…';

  @override
  String get voiceSavedTranscribing => 'Сохранено. Распознавание…';

  @override
  String voiceSavedTranscribingPercent(int percent) {
    return 'Сохранено. Распознавание… $percent%';
  }

  @override
  String get voiceDiscard => 'Отменить запись';

  @override
  String get voiceStop => 'Стоп';

  @override
  String get voiceChooseModelFirst =>
      'Сначала выберите модель распознавания в настройках';

  @override
  String voiceModelNotDownloaded(String model) {
    return 'Модель $model ещё не загружена — см. настройки';
  }

  @override
  String get voiceTranscribing => 'Распознавание…';

  @override
  String voiceTranscribingPercent(int percent) {
    return 'Распознавание… $percent%';
  }

  @override
  String voiceTranscribeFailed(String error) {
    return 'Не удалось распознать речь: $error';
  }

  @override
  String get voiceNoSpeech => 'В этой заметке не найдено речи';

  @override
  String get voiceTranscribedNoteNotOpen =>
      'Речь распознана, но заметка, к которой она относится, не открыта';

  @override
  String get voiceDiscardedDatabaseSwitched =>
      'Запись отменена, так как была открыта другая база данных.';

  @override
  String get voiceMicPermissionRefused => 'Доступ к микрофону запрещён';

  @override
  String voiceStartFailed(String error) {
    return 'Не удалось начать запись: $error';
  }

  @override
  String voiceRecordingFailed(String error) {
    return 'Ошибка записи: $error';
  }

  @override
  String voiceFinishFailed(String error) {
    return 'Не удалось завершить запись: $error';
  }

  @override
  String get voiceNoDatabase =>
      'База данных не открыта, поэтому заметку не удалось сохранить';

  @override
  String voiceSaveFailed(String error) {
    return 'Не удалось сохранить заметку: $error';
  }

  @override
  String get timeTimelineTitle => 'Хронология';

  @override
  String get timeStatsToday => 'Сегодня:';

  @override
  String get timeStatsThisMonth => 'За месяц:';

  @override
  String timeRecordingSince(String time) {
    return 'Учёт с $time';
  }

  @override
  String get timeEndBeforeStart =>
      'Время окончания должно быть позже времени начала';

  @override
  String get timeOverlaps => 'Пересекается с существующим интервалом';

  @override
  String get timeAddIntervalTitle => 'Добавить интервал';

  @override
  String get timeEditIntervalTitle => 'Изменить интервал';

  @override
  String get timeStartTime => 'Начало:';

  @override
  String get timeFinishTime => 'Окончание:';

  @override
  String get timeDurationLabel => 'Длительность:';

  @override
  String timeDurationHoursMinutes(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часа',
      many: '$hours часов',
      few: '$hours часа',
      one: '$hours час',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минута',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String timeDurationHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours часа',
      many: '$hours часов',
      few: '$hours часа',
      one: '$hours час',
    );
    return '$_temp0';
  }

  @override
  String timeDurationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes минуты',
      many: '$minutes минут',
      few: '$minutes минуты',
      one: '$minutes минута',
    );
    return '$_temp0';
  }

  @override
  String timeShortHoursMinutes(int hours, int minutes) {
    return '$hours ч $minutes мин';
  }

  @override
  String timeShortHours(int hours) {
    return '$hours ч';
  }

  @override
  String timeShortMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String timeShortSeconds(int seconds) {
    return '$seconds с';
  }

  @override
  String get timeAddEllipsis => 'Добавить...';

  @override
  String get timeNoRecords => 'Нет записей времени';

  @override
  String timeDayWithWeekday(int day, String weekday) {
    return '$day ($weekday)';
  }

  @override
  String get timeNow => 'сейчас';

  @override
  String get timeRemoveIntervalTitle => 'Удалить интервал?';

  @override
  String get timeRemoveIntervalConfirm =>
      'Вы действительно хотите удалить этот интервал времени?';

  @override
  String get timeNotTracking => 'Учёт не ведётся';

  @override
  String get timeStopTracking => 'Остановить учёт времени';

  @override
  String get timeStartTracking => 'Начать учёт времени';

  @override
  String get timeBackToFullWindow => 'Вернуться к полному окну';

  @override
  String get timeReportTitle => 'Отчёт по времени';

  @override
  String get timeReportSaveTitle => 'Сохранить отчёт по времени';

  @override
  String timeReportGenerateFailed(String error) {
    return 'Не удалось создать отчёт: $error';
  }

  @override
  String get timeReportCopied => 'Отчёт скопирован в буфер обмена';

  @override
  String timeReportSavedTo(String path) {
    return 'Сохранено в $path';
  }

  @override
  String timeReportSaveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String get timeReportTasks => 'Задачи';

  @override
  String get timeReportNoTasks => 'Нет задач.';

  @override
  String get timeReportClearSelection => 'Снять выделение';

  @override
  String timeReportSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Выбрано $count',
      many: 'Выбрано $count',
      few: 'Выбрано $count',
      one: 'Выбрана $count',
    );
    return '$_temp0';
  }

  @override
  String get timeReportIncludeDescendants => 'Включать вложенные задачи';

  @override
  String get timeReportIncludeDescendantsHint =>
      'Учитывать также время дочерних задач каждого выбранного узла.';

  @override
  String get timeReportDateRange => 'Период';

  @override
  String timeReportFrom(String date) {
    return 'С: $date';
  }

  @override
  String timeReportTo(String date) {
    return 'По: $date';
  }

  @override
  String get timeReportFormat => 'Формат';

  @override
  String get timeReportFormatTree => 'Дерево (только итоги)';

  @override
  String get timeReportFormatTreeWithDays => 'Дерево с разбивкой по дням';

  @override
  String get timeReportFormatFlat => 'Плоский список интервалов';

  @override
  String get timeReportShowEmpty => 'Показывать задачи без времени';

  @override
  String get timeReportUntitled => '(без названия)';

  @override
  String get timeReportSelectTasks =>
      'Выберите одну или несколько задач, чтобы создать отчёт.';

  @override
  String get timeReportNoRecordsInPeriod =>
      'Нет записей времени за выбранный период.';

  @override
  String get timeReportTextPeriod => 'Период:';

  @override
  String get timeReportTextTotal => 'Итого:';

  @override
  String get timeReportTextGenerated => 'Создан:';

  @override
  String get timeReportTextClipped =>
      'Записи, выходящие за границы периода, обрезаны по нему.';

  @override
  String timeReportTextSelf(String duration) {
    return 'собственное: $duration';
  }

  @override
  String get timeReportTextOngoing => 'идёт';

  @override
  String timeReportTotal(String duration, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return 'Итого: $duration   •   $_temp0';
  }

  @override
  String get timeReportRegenerate => 'Обновить';

  @override
  String get timeReportShare => 'Поделиться…';

  @override
  String get timeReportSave => 'Сохранить…';

  @override
  String get timeReportPresetToday => 'Сегодня';

  @override
  String get timeReportPresetThisWeek => 'Эта неделя';

  @override
  String get timeReportPresetThisMonth => 'Этот месяц';

  @override
  String get timeReportPresetLastMonth => 'Прошлый месяц';

  @override
  String get timeReportPresetThisYear => 'Этот год';

  @override
  String get prefsTitle => 'Настройки';

  @override
  String get prefsTabAppearance => 'Внешний вид';

  @override
  String get prefsTabBehavior => 'Поведение';

  @override
  String get prefsTabVoiceMemos => 'Голосовые заметки';

  @override
  String get prefsTabSync => 'Синхронизация';

  @override
  String get prefsTabMcp => 'MCP';

  @override
  String prefsFieldLabel(String label) {
    return '$label:';
  }

  @override
  String get prefsGroupLanguage => 'Язык';

  @override
  String get prefsInterfaceLanguage => 'Интерфейс';

  @override
  String get prefsLanguageHint =>
      'Переводы на языки, кроме английского, выполнены машинно; исправления приветствуются.';

  @override
  String get prefsGroupTheme => 'Тема';

  @override
  String get prefsThemeMode => 'Режим';

  @override
  String get prefsThemeSystem => 'Системная';

  @override
  String get prefsThemeLight => 'Светлая';

  @override
  String get prefsThemeDark => 'Тёмная';

  @override
  String get prefsGroupStyle => 'Стиль';

  @override
  String get prefsGroupColour => 'Цвет';

  @override
  String get prefsLook => 'Оформление';

  @override
  String get prefsLookHint =>
      'Классическое: прямые углы, плоские кнопки с рамкой, без эффекта волны, полосы прокрутки видны всегда, заголовок окна в цвете акцента и меню под ним.';

  @override
  String get prefsUiStyleModern => 'Современное';

  @override
  String get prefsUiStyleClassic => 'Классическое';

  @override
  String get prefsAccentColour => 'Цвет акцента';

  @override
  String get prefsAccentTeal => 'Бирюзовый';

  @override
  String get prefsAccentBlue => 'Синий';

  @override
  String get prefsAccentIndigo => 'Индиго';

  @override
  String get prefsAccentPurple => 'Фиолетовый';

  @override
  String get prefsAccentPink => 'Розовый';

  @override
  String get prefsAccentRed => 'Красный';

  @override
  String get prefsAccentOrange => 'Оранжевый';

  @override
  String get prefsAccentAmber => 'Янтарный';

  @override
  String get prefsAccentGreen => 'Зелёный';

  @override
  String get prefsAccentGraphite => 'Графитовый';

  @override
  String get prefsGroupWindow => 'Окно';

  @override
  String get prefsSystemTitleBar => 'Системный заголовок окна';

  @override
  String get prefsSystemTitleBarHint =>
      'Рамка, заголовок и кнопки окна в том виде, в каком их рисует рабочий стол, а строка меню — под ними.';

  @override
  String get prefsGroupEditorFont => 'Шрифт редактора (текст заметки)';

  @override
  String get prefsGroupTreeFont => 'Шрифт дерева (структура)';

  @override
  String get prefsGroupInterfaceFont => 'Шрифт интерфейса (меню и диалоги)';

  @override
  String get prefsFontFamily => 'Гарнитура';

  @override
  String get prefsFontCustom => 'Другой…';

  @override
  String get prefsCustomName => 'Название';

  @override
  String prefsCustomFamilyExample(String font) {
    return 'например, $font';
  }

  @override
  String get prefsFontSize => 'Размер';

  @override
  String get prefsUnitPt => 'пт';

  @override
  String get prefsFontStyle => 'Начертание';

  @override
  String get prefsBold => 'Жирный';

  @override
  String get prefsItalic => 'Курсив';

  @override
  String get prefsPreview => 'Образец';

  @override
  String get prefsPreviewText =>
      'Съешь же ещё этих мягких французских булок, да выпей чаю.';

  @override
  String get prefsScale => 'Масштаб';

  @override
  String get prefsFontSansSerif => 'Без засечек';

  @override
  String get prefsFontSerif => 'С засечками';

  @override
  String get prefsFontMonospace => 'Моноширинный';

  @override
  String get prefsGroupTimeTracking => 'Учёт времени';

  @override
  String get prefsEnableTimeTracking => 'Включить учёт времени';

  @override
  String get prefsEnableTimeTrackingHint =>
      'Запуск и остановка учёта, хронология и отчёты по времени. При выключении они скрываются; записанное время сохраняется';

  @override
  String get prefsShowSeconds => 'Показывать секунды';

  @override
  String get prefsShowSecondsHint => 'Показывать секунды в длительности';

  @override
  String get prefsMiniTracker => 'Мини-окно во время учёта';

  @override
  String get prefsMiniTrackerHint =>
      'Пока идёт учёт времени, при сворачивании окно превращается в маленькие часы поверх других окон';

  @override
  String get prefsGroupSaving => 'Сохранение';

  @override
  String get prefsAutoSaveEvery => 'Автосохранение каждые';

  @override
  String get prefsUnitSec => 'с';

  @override
  String get prefsGroupEditor => 'Редактор';

  @override
  String get prefsTabWidth => 'Ширина табуляции';

  @override
  String get prefsUnitSpaces => 'пробелов';

  @override
  String get prefsTabAsSpaces => 'Заменять табуляцию пробелами';

  @override
  String get prefsTabAsSpacesHint =>
      'Клавиша Tab вставляет пробелы вместо символа табуляции';

  @override
  String get prefsWordWrap => 'Перенос строк';

  @override
  String get prefsWordWrapHint =>
      'Выключено: длинные строки не переносятся, и заметка прокручивается по горизонтали (Shift + колесо). Также доступно в контекстном меню редактора и в строке состояния';

  @override
  String get prefsMonospaceOnly => 'Только моноширинные шрифты';

  @override
  String get prefsMonospaceOnlyHint =>
      'Меню «Шрифт» на панели инструментов предлагает только моноширинные шрифты, чтобы выровненный текст оставался выровненным';

  @override
  String get prefsFloatingButtons => 'Плавающие кнопки';

  @override
  String get prefsFloatingButtonsHint =>
      'Кнопки «Прикрепить файл» и «Записать голосовую заметку» поверх заметки; кнопки на панели инструментов остаются в любом случае';

  @override
  String get prefsPaste => 'Вставка';

  @override
  String get prefsPasteHint => 'Ctrl+Shift+V всегда вставляет простой текст';

  @override
  String get prefsPasteKeep => 'Сохранять форматирование';

  @override
  String get prefsPasteStrip => 'Убирать цвета и шрифты';

  @override
  String get prefsPastePlain => 'Только простой текст';

  @override
  String get prefsTableColumns => 'Столбцы таблицы';

  @override
  String get prefsTableColumnsHint =>
      'По какому символу команда «Оформить как таблицу» (контекстное меню редактора) делит строки на столбцы. Не внутри URL и текста в кавычках';

  @override
  String get prefsSeparatorColon => 'Двоеточие  ( : )';

  @override
  String get prefsSeparatorEquals => 'Знак равенства  ( = )';

  @override
  String get prefsSeparatorPipe => 'Вертикальная черта  ( | )';

  @override
  String get prefsSeparatorSemicolon => 'Точка с запятой  ( ; )';

  @override
  String get prefsSeparatorComma => 'Запятая  ( , )';

  @override
  String get prefsSeparatorTab => 'Tab';

  @override
  String get prefsGroupToolbarButtons => 'Кнопки панели инструментов';

  @override
  String get prefsToolbarButtonsHint =>
      'Снимите флажок, чтобы убрать кнопку с панели инструментов редактора.';

  @override
  String get prefsToolbarUndoRedo => 'Отменить / Повторить';

  @override
  String get prefsToolbarFont => 'Шрифт';

  @override
  String get prefsToolbarSize => 'Размер';

  @override
  String get prefsToolbarBold => 'Жирный';

  @override
  String get prefsToolbarItalic => 'Курсив';

  @override
  String get prefsToolbarUnderline => 'Подчёркнутый';

  @override
  String get prefsToolbarStrikeThrough => 'Зачёркнутый';

  @override
  String get prefsToolbarInlineCode => 'Код';

  @override
  String get prefsToolbarTextColor => 'Цвет текста';

  @override
  String get prefsToolbarHighlightColor => 'Цвет выделения';

  @override
  String get prefsToolbarClearFormat => 'Очистить форматирование';

  @override
  String get prefsToolbarHeadings => 'Заголовки';

  @override
  String get prefsToolbarNumberedList => 'Нумерованный список';

  @override
  String get prefsToolbarBulletedList => 'Маркированный список';

  @override
  String get prefsToolbarChecklist => 'Список флажков';

  @override
  String get prefsToolbarCodeBlock => 'Блок кода';

  @override
  String get prefsToolbarQuote => 'Цитата';

  @override
  String get prefsToolbarIndent => 'Отступ';

  @override
  String get prefsToolbarLink => 'Ссылка';

  @override
  String get prefsToolbarInsertImage => 'Вставить изображение';

  @override
  String get prefsToolbarVoiceMemo => 'Голосовая заметка';

  @override
  String get prefsGroupSecurity => 'Безопасность';

  @override
  String get prefsRememberPassword => 'Запоминать пароль';

  @override
  String get prefsRememberPasswordHint =>
      'Хранить пароль базы данных в системном хранилище ключей';

  @override
  String get prefsBiometricUnlock => 'Биометрическая разблокировка';

  @override
  String get prefsBiometricUnavailableHint =>
      'Недоступно — сначала настройте отпечаток пальца или блокировку экрана в настройках Android';

  @override
  String get prefsBiometricHint =>
      'Подтверждать отпечатком пальца, лицом или блокировкой экрана перед использованием сохранённого пароля';

  @override
  String get prefsBlockScreenshots => 'Запретить снимки экрана';

  @override
  String get prefsBlockScreenshotsHint =>
      'Скрывать содержимое приложения на снимках экрана, в записи экрана и в списке недавних приложений';

  @override
  String get prefsGroupStartup => 'Запуск';

  @override
  String get prefsSingleInstance => 'Один экземпляр';

  @override
  String get prefsSingleInstanceHint =>
      'Разрешить только одно окно; повторный запуск активирует уже открытое. Вступает в силу при следующем запуске.';

  @override
  String get prefsVoiceGroupDevices => 'Устройства';

  @override
  String get prefsVoiceMicrophone => 'Микрофон';

  @override
  String get prefsVoiceMicrophoneHint =>
      'Используется для голосовых заметок и для проверки ниже.';

  @override
  String get prefsVoiceSpeaker => 'Динамик';

  @override
  String get prefsVoiceSpeakerHint =>
      'Относится к голосовым заметкам. Другие аудиовложения воспроизводятся через системное устройство по умолчанию.';

  @override
  String get prefsVoiceDevicesLooking => 'Поиск…';

  @override
  String prefsVoiceDevicesError(String error) {
    return 'Не удалось получить список аудиоустройств: $error';
  }

  @override
  String get prefsVoiceDevicesUnavailable => 'Недоступно';

  @override
  String prefsVoiceDeviceDefault(String name) {
    return '$name (по умолчанию)';
  }

  @override
  String prefsVoiceDeviceMissing(String name) {
    return '$name (не подключено)';
  }

  @override
  String get prefsVoiceGroupTranscription => 'Распознавание речи';

  @override
  String get prefsVoiceModel => 'Модель';

  @override
  String get prefsVoiceModelHintNone =>
      'Заметки записываются и хранятся только как аудио.';

  @override
  String get prefsVoiceModelHintLocal =>
      'Работает на этом устройстве. Ничего никуда не отправляется.';

  @override
  String get prefsVoiceModelOff => 'Выключено';

  @override
  String prefsVoiceModelItem(String model, String size) {
    return '$model · $size';
  }

  @override
  String prefsVoiceModelItemRecommended(String model, String size) {
    return '$model · $size · рекомендуется';
  }

  @override
  String prefsMegabytes(String count) {
    return '$count МБ';
  }

  @override
  String get prefsVoiceTranscribeAfter => 'Распознавать после записи';

  @override
  String get prefsVoiceTranscribeAfterHint =>
      'Сначала заметка сохраняется, затем распознаётся по сохранённому аудио. Если выключено, заметка сохраняется без текста; пункт «Распознать речь» в меню вложения можно использовать позже.';

  @override
  String get prefsVoiceLanguage => 'Язык';

  @override
  String get prefsVoiceLanguageAuto => 'Определять автоматически';

  @override
  String get prefsVoiceFooter =>
      'Запись работает и без модели — заметки всегда сохраняются как аудио и воспроизводятся как любое другое вложение. Модель лишь добавляет текст.';

  @override
  String get prefsVoiceGroupCheck => 'Проверка';

  @override
  String get prefsVoiceCheckIntro =>
      'Записывает несколько секунд, воспроизводит их и распознаёт, используя выбранные выше устройства и модель. Ничего не сохраняется.';

  @override
  String get prefsVoiceStop => 'Стоп';

  @override
  String get prefsVoiceTestAgain => 'Проверить снова';

  @override
  String get prefsVoiceCheckRecording =>
      'Идёт запись — произнесите фразу и нажмите «Стоп».';

  @override
  String get prefsVoiceCheckPlaying => 'Воспроизведение…';

  @override
  String get prefsVoiceCheckTranscribing => 'Распознавание…';

  @override
  String prefsVoiceCheckTranscribingPercent(int percent) {
    return 'Распознавание… $percent%';
  }

  @override
  String prefsVoiceCheckDone(String duration) {
    return 'Записано: $duration.';
  }

  @override
  String get prefsVoiceCheckFailed => 'Проверка не завершилась.';

  @override
  String get prefsVoiceDownloading => 'Загрузка…';

  @override
  String prefsVoiceDownloadProgress(int percent, String size) {
    return '$percent% из $size';
  }

  @override
  String prefsVoiceModelReady(String model) {
    return 'Модель $model загружена и готова к работе.';
  }

  @override
  String prefsVoiceModelNotDownloaded(String size) {
    return 'Не загружена — $size с HuggingFace.';
  }

  @override
  String get prefsCheckBusy =>
      'Идёт запись голосовой заметки. Сначала завершите её.';

  @override
  String get prefsCheckPermissionRefused => 'Доступ к микрофону запрещён.';

  @override
  String prefsCheckMicWouldNotOpen(String error) {
    return 'Не удалось открыть микрофон: $error';
  }

  @override
  String prefsCheckRecordingFailed(String error) {
    return 'Ошибка записи: $error';
  }

  @override
  String prefsCheckNotFinished(String error) {
    return 'Не удалось завершить запись: $error';
  }

  @override
  String get prefsCheckNothingRecorded =>
      'Ничего не записано. Записывайте чуть дольше или выберите другой микрофон.';

  @override
  String get prefsCheckMalformed => 'Запись повреждена и не воспроизводится.';

  @override
  String prefsCheckPlaybackFailed(String error) {
    return 'Ошибка воспроизведения: $error';
  }

  @override
  String get prefsCheckNoModel =>
      'Запись и воспроизведение работают. Модель не выбрана, поэтому распознавать нечем.';

  @override
  String prefsCheckModelMissing(String model) {
    return 'Запись и воспроизведение работают. Модель $model ещё не загружена, поэтому распознавание не выполнялось.';
  }

  @override
  String prefsCheckTranscriptionFailed(String error) {
    return 'Ошибка распознавания: $error';
  }

  @override
  String get prefsCheckSilence =>
      'Микрофон передал тишину — индикатор уровня не двигался. Проверьте, что выбрано нужное устройство и что приложению разрешён доступ к нему.';

  @override
  String get prefsCheckNoSpeech =>
      'Запись и воспроизведение работают, но whisper не нашёл речи. Говорите ближе к микрофону или выберите другой язык.';

  @override
  String get prefsCheckQuiet =>
      'Индикатор уровня не двигался — сигнал очень тихий.';

  @override
  String get prefsDownloadCancelled => 'Загрузка отменена.';

  @override
  String prefsDownloadFailed(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get prefsUntitled => '(без названия)';

  @override
  String get prefsMcpTokenSessionOnly =>
      'Сохранён только на этот сеанс: системное хранилище ключей отказало. Если связка ключей заблокирована, разблокируйте её и нажмите «Создать заново».';

  @override
  String get prefsMcpRegenerateTitle => 'Создать новый токен?';

  @override
  String get prefsMcpRegenerateBody =>
      'Агенты, настроенные с текущим токеном, перестанут работать, пока вы не вставите новый токен в их настройки.';

  @override
  String get prefsMcpRegenerate => 'Создать заново';

  @override
  String get prefsMcpGroupAccess => 'Доступ агентов';

  @override
  String get prefsMcpEnable => 'Включить сервер MCP';

  @override
  String get prefsMcpEnableHint =>
      'Разрешить локальным ИИ-агентам для программирования читать это дерево через 127.0.0.1. По умолчанию выключено.';

  @override
  String get prefsMcpReadOnly => 'Только чтение';

  @override
  String get prefsMcpReadOnlyHint =>
      'Агенты могут искать и читать задачи, но не могут создавать, изменять, перемещать или удалять их.';

  @override
  String get prefsMcpGroupEndpoint => 'Адрес';

  @override
  String get prefsMcpPort => 'Порт';

  @override
  String get prefsMcpUrl => 'URL';

  @override
  String get prefsMcpCopyUrl => 'Копировать URL';

  @override
  String get prefsMcpToken => 'Токен';

  @override
  String get prefsMcpTokenHint =>
      'Этим токеном может воспользоваться любой, кто может запускать программы от вашего имени. Обращайтесь с ним как с паролем.';

  @override
  String get prefsMcpNoTokenYet =>
      'Токена ещё нет — включите сервер, чтобы создать его';

  @override
  String get prefsMcpShowToken => 'Показать токен';

  @override
  String get prefsMcpHideToken => 'Скрыть токен';

  @override
  String get prefsMcpCopyToken => 'Копировать токен';

  @override
  String get prefsMcpCopied => 'Скопировано.';

  @override
  String get prefsMcpGroupExcluded => 'Исключённые ветки';

  @override
  String get prefsMcpExcludedIntro =>
      'Задачи, скрытые от сервера MCP вместе со всем их содержимым.';

  @override
  String get prefsMcpLoading => 'Загрузка…';

  @override
  String get prefsMcpOutlineReadError => 'Не удалось прочитать дерево задач.';

  @override
  String get prefsMcpChoose => 'Выбрать…';

  @override
  String get prefsMcpNothingExcluded =>
      'Ничего не исключено — агентам видно всё дерево.';

  @override
  String prefsMcpMoreBranches(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'и ещё $count',
      many: 'и ещё $count',
      few: 'и ещё $count',
      one: 'и ещё $count',
    );
    return '$_temp0';
  }

  @override
  String prefsMcpListening(String url) {
    return 'Ожидает подключений на $url';
  }

  @override
  String prefsMcpPortUnavailable(String port) {
    return 'Порт $port недоступен. Выберите другой порт.';
  }

  @override
  String get prefsMcpNoAccessToken =>
      'Нет токена доступа. Нажмите «Создать заново», чтобы создать его.';

  @override
  String get prefsMcpWaitingDatabase => 'Ожидание открытия базы данных.';

  @override
  String get prefsMcpNotRunning => 'Не запущен.';

  @override
  String prefsMcpLastRequest(String time) {
    return 'Последний запрос в $time';
  }

  @override
  String get prefsMcpNoRequests => 'Запросов пока не было';

  @override
  String prefsMcpRejected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count запроса отклонено (неверный или отсутствующий токен)',
      many: '$count запросов отклонено (неверный или отсутствующий токен)',
      few: '$count запроса отклонено (неверный или отсутствующий токен)',
      one: '$count запрос отклонён (неверный или отсутствующий токен)',
    );
    return '$_temp0';
  }

  @override
  String get prefsMcpEnableFirst => '<сначала включите сервер>';

  @override
  String get prefsMcpGroupSetup => 'Настройка агента';

  @override
  String get prefsMcpClient => 'Клиент';

  @override
  String get prefsMcpStdioBridge =>
      'Агент, который поддерживает только stdio, можно подключить через мост:';

  @override
  String get prefsMcpTargetTerminal => 'Выполните в терминале:';

  @override
  String prefsMcpTargetFile(String file) {
    return 'Добавьте в $file:';
  }

  @override
  String get prefsMcpNoteClaudeCode =>
      'Настраивается для вашего пользователя, поэтому дерево доступно в любом проекте.';

  @override
  String get prefsMcpNoteCodex =>
      'Чтобы не хранить токен в файле, замените http_headers на bearer_token_env_var = \"NOO_MCP_TOKEN\" и задайте эту переменную в своей оболочке.';

  @override
  String get prefsMcpNoteOpenCode =>
      'oauth: false важно — без этого OpenCode воспринимает ответ 401 этого сервера как предложение начать регистрацию OAuth, которую не может завершить.';

  @override
  String get prefsMcpExcludedDialogIntro =>
      'Отмеченная задача скрывается от сервера MCP вместе со всем содержимым — агенты не могут её прочитать, изменить или удалить что-либо, что её содержит.';

  @override
  String get prefsMcpNoDatabase => 'База данных не открыта.';

  @override
  String get prefsMcpNoTasks => 'В этом дереве ещё нет задач.';

  @override
  String get prefsMcpCollapse => 'Свернуть';

  @override
  String get prefsMcpExpand => 'Развернуть';

  @override
  String get prefsMcpHiddenWithParent => 'скрыта с родительской';

  @override
  String get syncGroupSynchronization => 'Синхронизация';

  @override
  String get syncEnable => 'Включить синхронизацию';

  @override
  String get syncEnableHint => 'Синхронизировать эту базу данных с сервером';

  @override
  String get syncGroupIdentity => 'Идентификация';

  @override
  String get syncNeedsUserName =>
      'Введите имя пользователя, чтобы начать синхронизацию. Без него ничего не синхронизируется — ни через сервер, ни без него.';

  @override
  String get syncUserName => 'Имя пользователя';

  @override
  String get syncUserNameHint =>
      'Одинаковое на всех ваших устройствах. Вместе с паролем базы данных из него получаются ключи шифрования, поэтому устройства синхронизируются, только если совпадает и то, и другое.';

  @override
  String get syncDeviceName => 'Имя устройства';

  @override
  String get syncDeviceNameHint =>
      'Под этим именем устройство видно соседним устройствам';

  @override
  String get syncGroupServer => 'Сервер синхронизации (необязательно)';

  @override
  String get syncServerIntro =>
      'Оставьте пустым, чтобы синхронизироваться только с соседними устройствами в той же сети. Сервер дополнительно позволяет устройствам синхронизироваться, когда они далеко друг от друга; он хранит зашифрованные данные, которые не может прочитать.';

  @override
  String get syncServerUrl => 'URL сервера';

  @override
  String get syncServerPassword => 'Пароль';

  @override
  String get syncServerPasswordHint =>
      'Пароль вашей учётной записи на сервере. Это не пароль базы данных, и он никогда не используется как ключ шифрования.';

  @override
  String get syncTestConnection => 'Проверить соединение';

  @override
  String get syncRegister => 'Зарегистрироваться';

  @override
  String get syncGroupSchedule => 'Расписание';

  @override
  String get syncScheduleNeedsServer =>
      'Для синхронизации при запуске и выходе нужен сервер. Устройства в одной сети синхронизируются по вашему запросу через «Инструменты → Синхронизация P2P...»';

  @override
  String get syncAutosyncOnStart => 'Синхронизировать при запуске';

  @override
  String get syncAutosyncOnStartHint =>
      'Синхронизировать, когда приложение открывает базу данных';

  @override
  String get syncCheckOnStart => 'Проверять входящие изменения при запуске';

  @override
  String get syncCheckOnStartHint =>
      'Спрашивать сервер, прислали ли другие устройства изменения, без синхронизации, и показывать это на значке синхронизации. Не нужно, если включена синхронизация при запуске';

  @override
  String get syncAskOnExit => 'Предлагать синхронизацию при выходе';

  @override
  String get syncAskOnExitHint =>
      'Предлагать синхронизировать несохранённые на сервере изменения перед закрытием приложения';

  @override
  String get syncGroupServerStorage => 'Хранилище на сервере';

  @override
  String get syncGroupPeerToPeer => 'Между устройствами';

  @override
  String get syncPeerToPeerIntro =>
      'Устройства в одной сети с одинаковыми именем пользователя и паролем базы данных могут синхронизироваться напрямую — сервер не нужен. Откройте «Инструменты → Синхронизация P2P...» на каждом из них: они найдут друг друга и синхронизируются, пока это окно открыто, а в остальное время не видны в сети.';

  @override
  String get syncStorageNoServer =>
      'В этой конфигурации на сервере ничего не хранится. При синхронизации между устройствами все пакеты хранятся на самих устройствах.';

  @override
  String get syncStorageIntro =>
      'Сервер хранит все когда-либо сделанные зашифрованные изменения, поэтому его объём растёт с числом правок, а не с размером вашего дерева.';

  @override
  String get syncStorageReading => 'Чтение…';

  @override
  String get syncStoragePressRefresh =>
      'Нажмите «Обновить», чтобы узнать текущий объём.';

  @override
  String get syncStorageEmpty => 'На сервере пока ничего не хранится.';

  @override
  String syncStorageTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$size в $count пакета',
      many: '$size в $count пакетах',
      few: '$size в $count пакетах',
      one: '$size в $count пакете',
    );
    return '$_temp0';
  }

  @override
  String syncStorageDeviceCounters(int first, int last) {
    return 'Счётчики $first–$last';
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
      other: 'Счётчики $first–$last, $snapshots снимка',
      many: 'Счётчики $first–$last, $snapshots снимков',
      few: 'Счётчики $first–$last, $snapshots снимка',
      one: 'Счётчики $first–$last, $snapshots снимок',
    );
    return '$_temp0';
  }

  @override
  String syncStorageBlobs(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'И ещё $count вложения ($size), которые хранятся один раз и общие для всех ссылающихся на них пакетов.',
      many:
          'И ещё $count вложений ($size), которые хранятся один раз и общие для всех ссылающихся на них пакетов.',
      few:
          'И ещё $count вложения ($size), которые хранятся один раз и общие для всех ссылающихся на них пакетов.',
      one:
          'И ещё $count вложение ($size), которое хранится один раз и общее для всех ссылающихся на него пакетов.',
    );
    return '$_temp0';
  }

  @override
  String syncStorageLocal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'На этом устройстве хранятся $count из них ($size).',
      many: 'На этом устройстве хранятся $count из них ($size).',
      few: 'На этом устройстве хранятся $count из них ($size).',
      one: 'На этом устройстве хранится $count из них ($size).',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactOnServer => 'Сжать данные на сервере';

  @override
  String get syncResetIdentity => 'Сбросить идентификатор устройства';

  @override
  String get syncNotConfiguredOnDevice =>
      'На этом устройстве синхронизация не настроена.';

  @override
  String syncStorageReadFailed(String error) {
    return 'Не удалось получить данные о хранилище на сервере: $error';
  }

  @override
  String get syncResetConfirm =>
      'Это устройство начнёт синхронизироваться под новым идентификатором, и при следующей синхронизации опубликует полную копию текущей базы данных. Другие ваши устройства объединят её обычным образом — ничего не потеряется.\n\nДелайте это, если синхронизация сообщает, что история этого устройства разошлась; обычно это значит, что база данных была восстановлена из резервной копии после того, как уже синхронизировалась.\n\nСтарый идентификатор будет отображаться в списке хранилища на сервере, пока вы не выполните сжатие.';

  @override
  String get syncReset => 'Сбросить';

  @override
  String syncResetFailed(String error) {
    return 'Не удалось сбросить идентификатор устройства: $error';
  }

  @override
  String get syncCompactConfirm =>
      'Это устройство выполнит синхронизацию, а затем загрузит один снимок всей базы данных. После этого сервер удалит все сохранённые изменения, которые уже содержатся в снимке; так же поступит каждое устройство, получив снимок.\n\nЗаметки, время и вложения не затрагиваются — удаляется лишь запись отдельных прошлых правок, предшествующих снимку.\n\nСначала обновите Noo на других устройствах: более старая версия не может прочитать поток, начало которого удалено.';

  @override
  String get syncCompact => 'Сжать';

  @override
  String get syncCompactFailed => 'Сжатие не удалось.';

  @override
  String get syncCompactNothing => 'Пока нечего сжимать.';

  @override
  String syncCompactRelayFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'На сервере освобождено $size ($count пакета)',
      many: 'На сервере освобождено $size ($count пакетов)',
      few: 'На сервере освобождено $size ($count пакета)',
      one: 'На сервере освобождено $size ($count пакет)',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactRelayUnsupported =>
      'Снимок загружен, но этот сервер пока не поддерживает сжатие, поэтому сохранил свои копии';

  @override
  String get syncCompactRelayNothing =>
      'Снимок загружен; на сервере не осталось ничего для удаления';

  @override
  String syncCompactLocalFreed(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'На этом устройстве освобождено $size ($count пакета)',
      many: 'На этом устройстве освобождено $size ($count пакетов)',
      few: 'На этом устройстве освобождено $size ($count пакета)',
      one: 'На этом устройстве освобождено $size ($count пакет)',
    );
    return '$_temp0';
  }

  @override
  String syncCompactSummary(String relay, String local, String size) {
    return '$relay. $local. Размер самого снимка — $size.';
  }

  @override
  String syncCompactSummaryNoLocal(String relay, String size) {
    return '$relay. Размер самого снимка — $size.';
  }

  @override
  String get syncTestSuccess => 'Успешно: сервер доступен';

  @override
  String get syncTestUnreachable => 'Ошибка: сервер недоступен';

  @override
  String syncErrorWith(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get syncRegisterNeedsCredentials =>
      'Ошибка: нужны имя пользователя и пароль';

  @override
  String syncRegisterSuccess(String user) {
    return 'Успешно: учётная запись «$user» создана. Настройки сохранены.';
  }

  @override
  String syncRegisterSuccessUnlimited(String user) {
    return 'Успешно: учётная запись «$user» создана с неограниченным хранилищем на сервере. Настройки сохранены.';
  }

  @override
  String syncRegisterSuccessQuota(String user, String size) {
    return 'Успешно: учётная запись «$user» создана, хранилище на сервере — $size. Настройки сохранены.';
  }

  @override
  String get syncStagePreparing => 'Подготовка';

  @override
  String get syncStageAuthenticating => 'Проверка учётных данных';

  @override
  String get syncStagePushing => 'Отправка изменений';

  @override
  String get syncStageApplying => 'Применение изменений';

  @override
  String get syncStatePending => 'Ожидание';

  @override
  String get syncStateActive => 'Выполняется…';

  @override
  String get syncStateDone => 'Готово';

  @override
  String get syncStateSkipped => 'Пропущено';

  @override
  String get syncStateFailed => 'Ошибка';

  @override
  String get syncCancelling => 'Отмена…';

  @override
  String get syncSynchronizing => 'Синхронизация…';

  @override
  String get syncCancelled => 'Синхронизация отменена';

  @override
  String get syncFailed => 'Ошибка синхронизации';

  @override
  String get syncTitle => 'Синхронизация';

  @override
  String get syncComplete => 'Синхронизация завершена';

  @override
  String get syncNow => 'Синхронизировать';

  @override
  String get syncShowFullLogTooltip => 'Показать полный журнал';

  @override
  String get syncShowFullLog => 'Полный журнал';

  @override
  String get syncMoreSeeFullLog => 'см. «Полный журнал»';

  @override
  String get syncGroupProgress => 'Ход выполнения';

  @override
  String get syncNoRunYet =>
      'Синхронизация ещё не выполнялась. Нажмите «Синхронизировать»; здесь появятся подробности последней синхронизации.';

  @override
  String get syncCancelledNote =>
      'Остановлено по вашему запросу. Всё, что успело синхронизироваться, сохранено; следующая синхронизация продолжит с этого места.';

  @override
  String get syncGroupSummary => 'Итоги';

  @override
  String get syncChangesPushed => 'Отправлено изменений';

  @override
  String get syncChangesApplied => 'Применено изменений';

  @override
  String get syncGroupApplied => 'Применено — с других устройств';

  @override
  String get syncGroupPushed => 'Отправлено — с этого устройства';

  @override
  String get syncGroupLwwSkipped =>
      'Не применено — на этом устройстве уже есть более новое значение';

  @override
  String get syncGroupUnreadable => 'Не удалось прочитать';

  @override
  String get syncLwwTieNote =>
      'Если отметки времени точно совпадают, значения на обоих устройствах остаются как есть и поэтому различаются. Измените объект ещё раз на том устройстве, чью версию хотите сохранить.';

  @override
  String get syncLwwOlderNote =>
      'Входящее значение старше значения на этом устройстве, поэтому оно не записано. Если оно должно было победить, проверьте, что часы на обоих устройствах совпадают.';

  @override
  String get syncSkewSame => 'одинаковое время';

  @override
  String syncSkewSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'локальное на $seconds с позже',
      many: 'локальное на $seconds с позже',
      few: 'локальное на $seconds с позже',
      one: 'локальное на $seconds с позже',
    );
    return '$_temp0';
  }

  @override
  String syncSkewMinutes(int minutes, int seconds) {
    return 'локальное на $minutes мин $seconds с позже';
  }

  @override
  String syncSkewHours(int hours, int minutes) {
    return 'локальное на $hours ч $minutes мин позже';
  }

  @override
  String syncSkewDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'локальное на $days дня позже',
      many: 'локальное на $days дней позже',
      few: 'локальное на $days дня позже',
      one: 'локальное на $days день позже',
    );
    return '$_temp0';
  }

  @override
  String syncLwwSkipTimes(String incoming, String local, String skew) {
    return 'входящее $incoming · локальное $local ($skew)';
  }

  @override
  String syncSkippedPacketLine(String id, String stage, String detail) {
    return '$id  ·  ошибка на этапе $stage  ·  $detail';
  }

  @override
  String get syncSkippedDecryptNote =>
      'Эти пакеты не удалось расшифровать: пароль этой базы данных отличается от пароля на устройстве, которое их записало. Синхронизация не повторяет их: сделайте пароли одинаковыми, затем заново сохраните затронутые объекты на другом устройстве, чтобы они были отправлены снова.';

  @override
  String get syncSkippedUnreadableNote =>
      'Эти пакеты не удалось прочитать, и синхронизация их пропустила — сами по себе их изменения не придут. Заново сохраните затронутые объекты на другом устройстве, чтобы отправить их снова.';

  @override
  String get syncP2pNotConfigured =>
      'Синхронизация не настроена. Сначала укажите имя пользователя в разделе «Настройки → Синхронизация».';

  @override
  String syncP2pStartFailed(String error) {
    return 'Не удалось запустить синхронизацию между устройствами: $error';
  }

  @override
  String get syncP2pStarting => 'Запуск...';

  @override
  String get syncP2pLooking => 'Поиск устройств в этой сети...';

  @override
  String get syncP2pIntro =>
      'Откройте «Синхронизация P2P...» и на другом устройстве. Устройства синхронизируются, как только найдут друг друга; после закрытия этого окна они перестают быть видны.';

  @override
  String get syncP2pTitle => 'Синхронизация P2P';

  @override
  String get syncP2pSyncAgain => 'Синхронизировать снова';

  @override
  String get syncP2pFound => 'Найдено — ожидание синхронизации';

  @override
  String get syncP2pSyncing => 'Синхронизация...';

  @override
  String get syncP2pUpToDate => 'Синхронизировано — изменений нет';

  @override
  String syncP2pReceived(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Синхронизировано — получено $count изменения',
      many: 'Синхронизировано — получено $count изменений',
      few: 'Синхронизировано — получено $count изменения',
      one: 'Синхронизировано — получено $count изменение',
    );
    return '$_temp0';
  }

  @override
  String syncP2pFailed(String error) {
    return 'Ошибка — $error';
  }

  @override
  String get syncP2pUnknownError => 'неизвестная ошибка';

  @override
  String syncP2pReceivedFrom(String device, int count) {
    return 'Получено от $device ($count)';
  }

  @override
  String syncP2pSentTo(String device, int count) {
    return 'Отправлено на $device ($count)';
  }

  @override
  String syncQuotaUsed(String used, String quota, int percent) {
    return 'Использовано $used из $quota ($percent%)';
  }

  @override
  String get syncQuotaSemantics => 'Использование хранилища на сервере';

  @override
  String get syncQuotaFull =>
      'Заполнено: сервер не принимает новые изменения, пока вы не выполните сжатие или не удалите вложения.';

  @override
  String get syncQuotaNearlyFull =>
      'Почти заполнено. Сжатие обычно освобождает большую часть места.';

  @override
  String get syncNotConfiguredOpenSettings =>
      'Синхронизация не настроена. Сначала откройте настройки синхронизации.';

  @override
  String get syncNoServerConfigured =>
      'Сервер синхронизации не настроен. Используйте «Синхронизация P2P...» для локальной синхронизации или добавьте сервер в разделе «Настройки → Синхронизация».';

  @override
  String get syncAlreadyInProgress => 'Синхронизация уже выполняется';

  @override
  String get syncAlreadyInProgressSentence => 'Синхронизация уже выполняется.';

  @override
  String syncApplyOneOf(int total, String done, String totalText) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$done из $totalText изменения',
      many: '$done из $totalText изменений',
      few: '$done из $totalText изменений',
      one: '$done из $totalText изменения',
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
      other: '$countText изменения · пакет $current из $packets',
      many: '$countText изменений · пакет $current из $packets',
      few: '$countText изменения · пакет $current из $packets',
      one: '$countText изменение · пакет $current из $packets',
    );
    return '$_temp0';
  }

  @override
  String syncApplyChanges(int count, String countText) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countText изменения',
      many: '$countText изменений',
      few: '$countText изменения',
      one: '$countText изменение',
    );
    return '$_temp0';
  }

  @override
  String syncApplySecondsLeft(String progress, int seconds) {
    return '$progress · осталось около $seconds с';
  }

  @override
  String syncApplyMinutesLeft(String progress, int minutes) {
    return '$progress · осталось около $minutes мин';
  }

  @override
  String syncForkDetected(int remote, int local) {
    return 'Обнаружено ветвление потока устройства: удалённый узел хранит для этого устройства пакет со счётчиком $remote, а это устройство находится на $local, и подтвердить, что предшествующие данные совпадают, невозможно (база данных восстановлена из резервной копии?). Чтобы возобновить синхронизацию, используйте «Сбросить идентификатор устройства» в разделе «Настройки → Синхронизация».';
  }

  @override
  String syncStreamDiverged(
    int counter,
    String source,
    String localHash,
    String remoteHash,
  ) {
    return 'Поток устройства разошёлся на пакете со счётчиком $counter: это устройство и $source хранят разное содержимое под одним идентификатором ($localHash здесь и $remoteHash там). Скорее всего, база данных восстановлена из резервной копии и повторно использовала уже опубликованные номера пакетов. Чтобы возобновить синхронизацию, используйте «Сбросить идентификатор устройства» в разделе «Настройки → Синхронизация»; база данных будет опубликована заново под новым идентификатором, и ничего не потеряется.';
  }

  @override
  String syncStreamGap(String expected, int local) {
    return 'На сервере отсутствует часть истории этого устройства: он ожидает следующим пакет №$expected, а самый ранний пакет на этом устройстве — №$local, и промежуточных пакетов здесь уже нет (скорее всего, сервер восстановлен из более старой резервной копии после того, как это устройство выполнило сжатие). Чтобы возобновить синхронизацию, используйте «Сбросить идентификатор устройства» в разделе «Настройки → Синхронизация»; база данных будет опубликована заново под новым идентификатором, и ничего не потеряется.';
  }

  @override
  String get syncIdentityReset =>
      'Теперь это устройство синхронизируется под новым идентификатором. При следующей синхронизации оно опубликует полную копию текущей базы данных, которую все остальные устройства объединят обычным образом.';

  @override
  String syncIdentityResetDiscarded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Теперь это устройство синхронизируется под новым идентификатором. При следующей синхронизации оно опубликует полную копию текущей базы данных, которую все остальные устройства объединят обычным образом. Отброшено $count непригодного пакета.',
      many:
          'Теперь это устройство синхронизируется под новым идентификатором. При следующей синхронизации оно опубликует полную копию текущей базы данных, которую все остальные устройства объединят обычным образом. Отброшено $count непригодных пакетов.',
      few:
          'Теперь это устройство синхронизируется под новым идентификатором. При следующей синхронизации оно опубликует полную копию текущей базы данных, которую все остальные устройства объединят обычным образом. Отброшено $count непригодных пакета.',
      one:
          'Теперь это устройство синхронизируется под новым идентификатором. При следующей синхронизации оно опубликует полную копию текущей базы данных, которую все остальные устройства объединят обычным образом. Отброшен $count непригодный пакет.',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDerivingKey => 'Получение ключа шифрования';

  @override
  String get syncDetailSignedIn => 'Вход уже выполнен';

  @override
  String get syncDetailPackaging => 'Упаковка локальных изменений';

  @override
  String get syncDetailRecovering =>
      'Восстановление собственной истории устройства';

  @override
  String get syncDetailUploading => 'Отправка на сервер';

  @override
  String get syncDetailNoLocalChanges => 'Нет локальных изменений';

  @override
  String syncDetailPushed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отправлено $count изменения',
      many: 'Отправлено $count изменений',
      few: 'Отправлено $count изменения',
      one: 'Отправлено $count изменение',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailDownloading => 'Загрузка изменений с других устройств';

  @override
  String syncDetailAttachmentsDownloaded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Загружено $count вложения',
      many: 'Загружено $count вложений',
      few: 'Загружено $count вложения',
      one: 'Загружено $count вложение',
    );
    return '$_temp0';
  }

  @override
  String syncDetailAttachmentsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Осталось загрузить $count вложения',
      many: 'Осталось загрузить $count вложений',
      few: 'Осталось загрузить $count вложения',
      one: 'Осталось загрузить $count вложение',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailUpToDate => 'Изменений нет';

  @override
  String syncDetailApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Применено $count изменения',
      many: 'Применено $count изменений',
      few: 'Применено $count изменения',
      one: 'Применено $count изменение',
    );
    return '$_temp0';
  }

  @override
  String get syncDetailCancelled => 'Отменено';

  @override
  String syncAttachmentNotDownloaded(String name) {
    return 'Вложение «$name» ещё не загружено на это устройство, а изменение, сделанное на этом устройстве, ссылается на него, поэтому изменения этого устройства не попадут на сервер, пока оно не появится. Синхронизируйтесь снова, когда оно загрузится, или синхронизируйтесь с соседним устройством, на котором оно есть.';
  }

  @override
  String syncAttachmentTooLarge(String name, String size) {
    return 'Сервер отклонил вложение «$name» ($size) как слишком большое. Всё остальное синхронизируется; само вложение попадёт на другие устройства только через синхронизацию P2P.';
  }

  @override
  String syncAttachmentTooLargeLimit(String name, String size, String limit) {
    return 'Сервер отклонил вложение «$name» ($size) как слишком большое (ограничение — $limit). Всё остальное синхронизируется; само вложение попадёт на другие устройства только через синхронизацию P2P.';
  }

  @override
  String syncAttachmentOverQuota(String name, String size) {
    return 'Вложение «$name» ($size) не помещается в ваше хранилище на сервере. Всё остальное синхронизируется; чтобы освободить место, сожмите данные на сервере или удалите большие вложения, а до тех пор вложение попадёт на другие устройства только через синхронизацию P2P.';
  }

  @override
  String syncAttachmentOverQuotaUsage(
    String name,
    String size,
    String used,
    String quota,
  ) {
    return 'Вложение «$name» ($size) не помещается в ваше хранилище на сервере (использовано $used из $quota). Всё остальное синхронизируется; чтобы освободить место, сожмите данные на сервере или удалите большие вложения, а до тех пор вложение попадёт на другие устройства только через синхронизацию P2P.';
  }

  @override
  String syncBytes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count байта',
      many: '$count байт',
      few: '$count байта',
      one: '$count байт',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactUnavailable =>
      'Сервер синхронизации не настроен. Сжатие публикует снимок на сервере-ретрансляторе; при синхронизации только с соседними устройствами освобождать на сервере нечего.';

  @override
  String get syncCompactStageSyncing => 'Синхронизация перед сжатием';

  @override
  String get syncCompactStageChecking =>
      'Проверка актуальности данных на этом устройстве';

  @override
  String get syncCompactStagePackaging => 'Упаковка снимка всей базы данных';

  @override
  String get syncCompactStageAttachments =>
      'Отправка вложений, на которые ссылается снимок';

  @override
  String get syncCompactStageUploading => 'Отправка снимка';

  @override
  String get syncCompactStageReclaiming =>
      'Освобождение места на этом устройстве';

  @override
  String get syncCompactStageReadingUsage =>
      'Получение данных о хранилище на сервере';

  @override
  String syncCompactNeedsSync(String error) {
    return 'Для сжатия сначала нужна завершённая синхронизация: $error';
  }

  @override
  String get syncCompactDidNotFinish => 'Сжатие не завершилось.';

  @override
  String get syncCompactRaced =>
      'Другая синхронизация успела упаковать изменения первой. Попробуйте выполнить сжатие ещё раз.';

  @override
  String get syncCompactSnapshotMissing =>
      'Снимок упакован, но отсутствует в локальном хранилище.';

  @override
  String get syncCompactMissingAttachments =>
      'На этом устройстве всё ещё не хватает некоторых вложений. Синхронизируйтесь, пока не загрузятся все вложения, затем выполните сжатие.';

  @override
  String syncCompactRelayRefused(String error) {
    return 'Сервер-ретранслятор отклонил снимок: $error';
  }

  @override
  String syncCompactError(String error) {
    return 'Ошибка сжатия: $error';
  }

  @override
  String syncCompactBlockedUnreadable(int count, String packets) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Это устройство не смогло прочитать $count пакета ($packets), поэтому его состояние не является объединением всего журнала. Сжатие удалило бы пакеты, которые это устройство так и не применило.',
      many:
          'Это устройство не смогло прочитать $count пакетов ($packets), поэтому его состояние не является объединением всего журнала. Сжатие удалило бы пакеты, которые это устройство так и не применило.',
      few:
          'Это устройство не смогло прочитать $count пакета ($packets), поэтому его состояние не является объединением всего журнала. Сжатие удалило бы пакеты, которые это устройство так и не применило.',
      one:
          'Это устройство не смогло прочитать $count пакет ($packets), поэтому его состояние не является объединением всего журнала. Сжатие удалило бы пакеты, которые это устройство так и не применило.',
    );
    return '$_temp0';
  }

  @override
  String get syncCompactBlockedUnsynced =>
      'На этом устройстве есть несинхронизированные правки. Сначала синхронизируйтесь, затем выполните сжатие.';

  @override
  String syncCompactBlockedAttachments(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'На этом устройстве ещё не хватает вложений (осталось загрузить $count), поэтому снимок не сможет их предоставить, и сервер их удалит. Синхронизируйтесь, пока не загрузятся все вложения, затем выполните сжатие.',
      many:
          'На этом устройстве ещё не хватает вложений (осталось загрузить $count), поэтому снимок не сможет их предоставить, и сервер их удалит. Синхронизируйтесь, пока не загрузятся все вложения, затем выполните сжатие.',
      few:
          'На этом устройстве ещё не хватает вложений (осталось загрузить $count), поэтому снимок не сможет их предоставить, и сервер их удалит. Синхронизируйтесь, пока не загрузятся все вложения, затем выполните сжатие.',
      one:
          'На этом устройстве ещё не хватает вложений (осталось загрузить $count), поэтому снимок не сможет их предоставить, и сервер их удалит. Синхронизируйтесь, пока не загрузятся все вложения, затем выполните сжатие.',
    );
    return '$_temp0';
  }

  @override
  String syncCompactBlockedBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Это устройство применило не всё, что хранит, для $count устройства. Синхронизируйтесь снова, затем выполните сжатие.',
      many:
          'Это устройство применило не всё, что хранит, для $count устройств. Синхронизируйтесь снова, затем выполните сжатие.',
      few:
          'Это устройство применило не всё, что хранит, для $count устройств. Синхронизируйтесь снова, затем выполните сжатие.',
      one:
          'Это устройство применило не всё, что хранит, для $count устройства. Синхронизируйтесь снова, затем выполните сжатие.',
    );
    return '$_temp0';
  }

  @override
  String get syncCollectNoRelay =>
      'Синхронизация только с соседними устройствами не гарантирует, что удалённое вложение ещё есть на другом устройстве, поэтому ни одно не было освобождено.';

  @override
  String get syncCollectUnsynced =>
      'На этом устройстве есть изменения, которые ещё не сохранены на сервере. Сначала синхронизируйтесь, затем выполните сжатие.';

  @override
  String syncSummarySnapshotOf(String device) {
    return 'Снимок $device';
  }

  @override
  String syncSummarySnapshotFields(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count поля — вся база данных',
      many: '$count полей — вся база данных',
      few: '$count поля — вся база данных',
      one: '$count поле — вся база данных',
    );
    return '$_temp0';
  }

  @override
  String syncSummaryNode(String name) {
    return 'Узел «$name»';
  }

  @override
  String syncSummaryFile(String name) {
    return 'Файл «$name»';
  }

  @override
  String get syncSummaryFileFallback => 'файл';

  @override
  String get syncSummaryTimeChunk => 'Интервал времени';

  @override
  String syncSummaryRenamedTo(String title) {
    return 'переименовано в «$title»';
  }

  @override
  String get syncSummaryContentEdited => 'изменено содержимое';

  @override
  String get syncSummaryMoved => 'перемещено';

  @override
  String get syncSummaryReordered => 'изменён порядок';

  @override
  String get syncSummaryFlagsChanged => 'изменены флаги';

  @override
  String get syncSummaryRenamed => 'переименовано';

  @override
  String get syncSummaryContentUpdated => 'обновлено содержимое';

  @override
  String syncSummaryFrom(String time) {
    return 'с $time';
  }

  @override
  String syncSummaryUntil(String time) {
    return 'до $time';
  }

  @override
  String get syncValueTopLevel => 'верхний уровень';

  @override
  String get syncStorageFull =>
      'Хранилище на сервере заполнено. Сожмите данные на сервере («Настройки → Синхронизация → Хранилище на сервере») или удалите большие вложения; то, что не отправлено, остаётся на этом устройстве.';

  @override
  String syncStorageFullUsage(String used, String quota) {
    return 'Хранилище на сервере заполнено (использовано $used из $quota). Сожмите данные на сервере («Настройки → Синхронизация → Хранилище на сервере») или удалите большие вложения; то, что не отправлено, остаётся на этом устройстве.';
  }

  @override
  String syncStorageStreams(String detail) {
    return 'Сервер не принимает ещё один поток устройства для этой учётной записи: $detail';
  }

  @override
  String get syncStorageServerDisk =>
      'На сервере закончилось место на диске. Ничего не потеряно; повторите синхронизацию позже.';

  @override
  String syncStorageRefused(String detail) {
    return 'Сервер отказался сохранять новые данные: $detail';
  }

  @override
  String get syncRegAccountLimit =>
      'Этот сервер не принимает новые учётные записи: достигнуто их максимальное число.';

  @override
  String get syncRegClosed =>
      'Этот сервер не принимает регистрации. Попросите учётную запись у его администратора.';

  @override
  String get syncRegTaken => 'Это имя пользователя уже занято.';

  @override
  String get syncRegInvalid =>
      'Имя пользователя должно содержать 3–50 символов, а пароль сервера — 8–128.';

  @override
  String get syncRegTooManyFromNetwork =>
      'Сегодня из этой сети зарегистрировано слишком много учётных записей.';

  @override
  String syncRegTooManyFromNetworkWait(String wait) {
    return 'Сегодня из этой сети зарегистрировано слишком много учётных записей. Повторите через $wait.';
  }

  @override
  String get syncRegTooManyAttempts => 'Слишком много попыток.';

  @override
  String syncRegTooManyAttemptsWait(String wait) {
    return 'Слишком много попыток. Повторите через $wait.';
  }

  @override
  String get syncRegBusy => 'Сервер занят. Повторите попытку чуть позже.';

  @override
  String syncRegFailed(int status) {
    return 'Ошибка регистрации (HTTP $status)';
  }

  @override
  String syncRegFailedDetail(int status, String detail) {
    return 'Ошибка регистрации (HTTP $status): $detail';
  }

  @override
  String syncWaitSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count секунды',
      many: '$count секунд',
      few: '$count секунды',
      one: '$count секунду',
    );
    return '$_temp0';
  }

  @override
  String syncWaitMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count минуты',
      many: '$count минут',
      few: '$count минуты',
      one: '$count минуту',
    );
    return '$_temp0';
  }

  @override
  String syncWaitHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count часа',
      many: '$count часов',
      few: '$count часа',
      one: '$count час',
    );
    return '$_temp0';
  }

  @override
  String syncTimeoutNoResponse(String host, int seconds) {
    return 'Нет ответа от $host в течение $seconds с';
  }

  @override
  String syncTimeoutStalled(String host, int seconds) {
    return 'Ответ от $host не поступал $seconds с';
  }

  @override
  String traceMoreRows(int count, String where) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '…и ещё $count — $where',
      many: '…и ещё $count — $where',
      few: '…и ещё $count — $where',
      one: '…и ещё $count — $where',
    );
    return '$_temp0';
  }

  @override
  String get traceMoreSeeSyncLog => 'см. журнал синхронизации';

  @override
  String get traceAtTopLevel => 'на верхнем уровне';

  @override
  String traceInPath(String path) {
    return 'в $path';
  }

  @override
  String get traceRowNew => '(новое)';

  @override
  String get traceRowRemoved => '(удалено)';

  @override
  String get traceShowHowTooltip => 'Показать, как произошло это изменение';

  @override
  String traceBytes(int count) {
    return '$count Б';
  }

  @override
  String traceKilobytes(String size) {
    return '$size КБ';
  }

  @override
  String traceMegabytes(String size) {
    return '$size МБ';
  }

  @override
  String get traceDecisionApplied => 'применено';

  @override
  String get traceDecisionCreated => 'создано здесь';

  @override
  String get traceDecisionConflictCopy =>
      'применено — заменённое значение сохранено как конфликтная копия';

  @override
  String get traceDecisionMerged =>
      'объединено с правкой, сделанной здесь, — сохранены оба изменения';

  @override
  String get traceDecisionCycleToRoot =>
      'перемещено на верхний уровень — с таким родителем образовался бы цикл';

  @override
  String get traceDecisionParentMissing =>
      'размещено на верхнем уровне до появления родителя';

  @override
  String get traceDecisionBlobPending =>
      'применено — данные вложения поступят отдельно';

  @override
  String get traceDecisionSent => 'отправлено';

  @override
  String get traceDecisionForwarded => 'переслано';

  @override
  String get traceRouteRelay => 'Загружено с сервера-ретранслятора.';

  @override
  String traceRouteRelayStored(String time) {
    return 'Загружено с сервера-ретранслятора, который сохранил его $time.';
  }

  @override
  String traceRoutePeerForwarded(String peer, String author) {
    return 'Переслано устройством $peer по локальной сети — автор: $author.';
  }

  @override
  String traceRoutePeerDirect(String peer) {
    return 'Напрямую от $peer по локальной сети.';
  }

  @override
  String get traceRouteStoredEarlier =>
      'Уже было на этом устройстве после предыдущего обмена; применено в этом.';

  @override
  String traceRouteStoredAt(String time) {
    return 'Уже было на этом устройстве — получено $time; применено в этом обмене.';
  }

  @override
  String traceRouteStoredAtFrom(String time, String source) {
    return 'Уже было на этом устройстве — получено $time от $source; применено в этом обмене.';
  }

  @override
  String get traceRoutePackagedUploaded =>
      'Упаковано здесь и отправлено на сервер-ретранслятор.';

  @override
  String get traceRoutePackagedAlreadyHeld =>
      'Упаковано здесь; сервер-ретранслятор уже получил его другим путём.';

  @override
  String get traceRoutePackagedBlocked =>
      'Упаковано здесь; ещё не отправлено — не удалось отправить нужное ему вложение.';

  @override
  String get traceRoutePackagedWaiting =>
      'Упаковано здесь; ожидает, когда его заберёт сервер-ретранслятор или другое устройство.';

  @override
  String traceRouteServedForwarded(String peer, String author) {
    return 'Получено устройством $peer по локальной сети — переслано от имени $author.';
  }

  @override
  String traceRouteServedDirect(String peer) {
    return 'Получено устройством $peer по локальной сети.';
  }

  @override
  String get traceBlobDownloaded => 'загружено сейчас';

  @override
  String traceBlobDownloadedSized(String size) {
    return 'загружено сейчас ($size)';
  }

  @override
  String traceBlobDownloadedFrom(String source) {
    return 'загружено сейчас от $source';
  }

  @override
  String traceBlobDownloadedFromSized(String source, String size) {
    return 'загружено сейчас от $source ($size)';
  }

  @override
  String get traceBlobWaiting =>
      'ещё не загружено — поступит при следующей синхронизации или при открытии';

  @override
  String get traceBlobHeld => 'уже есть на этом устройстве';

  @override
  String get traceBlobUploaded => 'отправлено на сервер-ретранслятор';

  @override
  String traceBlobUploadedSized(String size) {
    return 'отправлено на сервер-ретранслятор ($size)';
  }

  @override
  String get traceBlobOnRelay => 'уже были на сервере-ретрансляторе';

  @override
  String get traceBlobOffered => 'доступно на этом устройстве для других';

  @override
  String traceBlobLine(String id, String state) {
    return '$id — $state';
  }

  @override
  String traceSnapshotWhole(String device) {
    return 'Снимок сжатия: вся база данных $device в одном пакете.';
  }

  @override
  String traceSnapshotPart(String device) {
    return 'Часть снимка полного состояния от $device. Снимок содержит всю базу данных автора; этот объект показан, потому что здесь он отличался.';
  }

  @override
  String get traceFieldsHeading => 'Поля';

  @override
  String traceTimeEdited(String time) {
    return 'изменено $time';
  }

  @override
  String traceTimeTheirs(String time) {
    return 'у них $time';
  }

  @override
  String traceTimeThisDevice(String time) {
    return 'это устройство $time';
  }

  @override
  String tracePacketHeading(String device, String counter) {
    return 'Пакет $device №$counter';
  }

  @override
  String tracePacketHeadingSnapshot(String device, String counter) {
    return 'Пакет $device №$counter (снимок)';
  }

  @override
  String tracePacketWritten(String time) {
    return 'записан $time';
  }

  @override
  String tracePacketChanges(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count изменения',
      many: '$count изменений',
      few: '$count изменения',
      one: '$count изменение',
    );
    return '$_temp0';
  }

  @override
  String tracePacketAuthorTooltip(String id) {
    return 'Устройство-автор $id';
  }

  @override
  String tracePacketFromDevice(String id) {
    return 'с устройства $id';
  }

  @override
  String get traceCopyHashTooltip => 'Копировать хеш пакета';

  @override
  String get traceAttachmentBytesHeading => 'Данные вложения';

  @override
  String get traceShowInSyncLog => 'Показать в журнале синхронизации';

  @override
  String get traceTriggerRelay => 'Синхронизация с сервером';

  @override
  String get traceTriggerCheck => 'Проверка входящих изменений';

  @override
  String get traceTriggerLan => 'Соседние устройства';

  @override
  String get traceTriggerLanReturn => 'Соседнее устройство (по запросу)';

  @override
  String get traceTriggerLanServe => 'Передано соседнему устройству';

  @override
  String get traceTriggerPackage => 'Упаковка локальных изменений';

  @override
  String get traceTriggerCompaction => 'Сжатие';

  @override
  String get traceTriggerIdentityReset => 'Сброс идентификатора устройства';

  @override
  String get traceTriggerAttachment => 'Загрузка вложения';

  @override
  String get traceTriggerBlobCollect => 'Очистка вложений';

  @override
  String get traceOutcomeRunning => 'выполняется';

  @override
  String get traceOutcomeFailed => 'ошибка';

  @override
  String get traceOutcomeDeclined => 'отклонено';

  @override
  String get traceOutcomeBusy => 'занято';

  @override
  String get traceOutcomeInterrupted => 'прервано';

  @override
  String traceCopiedJson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Скопировано $count события в формате JSON',
      many: 'Скопировано $count событий в формате JSON',
      few: 'Скопировано $count события в формате JSON',
      one: 'Скопировано $count событие в формате JSON',
    );
    return '$_temp0';
  }

  @override
  String get traceClearTitle => 'Очистить журнал синхронизации?';

  @override
  String get traceClearBody =>
      'Все записанные на этом устройстве сеансы и события будут удалены. Синхронизированные данные не затрагиваются.';

  @override
  String get traceTitle => 'Журнал синхронизации';

  @override
  String get traceCopyAsJson => 'Копировать как JSON';

  @override
  String get traceClearLogTooltip => 'Очистить журнал';

  @override
  String get traceClearLogButton => 'Очистить журнал';

  @override
  String traceSummaryApplied(int count) {
    return 'применено: $count';
  }

  @override
  String traceSummaryWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count предупреждения',
      many: '$count предупреждений',
      few: '$count предупреждения',
      one: '$count предупреждение',
    );
    return '$_temp0';
  }

  @override
  String traceSummaryErrors(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ошибки',
      many: '$count ошибок',
      few: '$count ошибки',
      one: '$count ошибка',
    );
    return '$_temp0';
  }

  @override
  String get traceNothingExchanged => 'Обмена не было';

  @override
  String get traceNoRuns =>
      'Синхронизаций пока не записано. Сеансы появятся здесь, когда это устройство синхронизируется с сервером или с соседними устройствами.';

  @override
  String get traceAllRuns => 'Все сеансы';

  @override
  String traceRunsRecorded(int count) {
    return 'записано: $count';
  }

  @override
  String traceAllRunsCount(int count) {
    return 'Все сеансы ($count)';
  }

  @override
  String get traceRunLabel => 'Сеанс';

  @override
  String get traceSearchHint => 'Поиск: имя узла, id, хеш, устройство, тип…';

  @override
  String get traceLevelAll => 'Все';

  @override
  String get traceLevelWarnings => 'Предупреждения';

  @override
  String get traceLevelErrors => 'Ошибки';

  @override
  String get traceDirectionAll => 'Входящие и исходящие';

  @override
  String get traceDirectionIncoming => 'Входящие';

  @override
  String get traceDirectionOutgoing => 'Исходящие';

  @override
  String get traceDirectionLocal => 'Локальные';

  @override
  String get traceNoEvents => 'Нет подходящих событий.';

  @override
  String traceEventsTruncated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Показаны первые $count события. Уточните поиск или выберите сеанс, чтобы увидеть остальные.',
      many:
          'Показаны первые $count событий. Уточните поиск или выберите сеанс, чтобы увидеть остальные.',
      few:
          'Показаны первые $count события. Уточните поиск или выберите сеанс, чтобы увидеть остальные.',
      one:
          'Показано первое $count событие. Уточните поиск или выберите сеанс, чтобы увидеть остальные.',
    );
    return '$_temp0';
  }

  @override
  String traceRunNumber(int id) {
    return 'Сеанс №$id';
  }

  @override
  String get traceEmptyValue => '(пусто)';

  @override
  String traceSubHash(String hash) {
    return 'хеш $hash';
  }

  @override
  String traceSubValue(String hash) {
    return 'значение $hash';
  }

  @override
  String traceSubRemote(String time) {
    return 'удалённое $time';
  }

  @override
  String traceSubLocal(String time) {
    return 'локальное $time';
  }

  @override
  String get traceDetailAt => 'Время';

  @override
  String get traceDetailDirection => 'Направление';

  @override
  String get traceDetailOriginDevice => 'Исходное устройство';

  @override
  String get traceDetailCounter => 'Счётчик';

  @override
  String get traceDetailHash => 'Хеш пакета / блоба';

  @override
  String get traceDetailEntity => 'Объект';

  @override
  String get traceDetailWorldId => 'World id';

  @override
  String get traceDetailName => 'Имя';

  @override
  String get traceDetailField => 'Поле';

  @override
  String get traceDetailRemoteTs => 'Удалённая отметка времени';

  @override
  String get traceDetailLocalTs => 'Локальная отметка времени';

  @override
  String get traceDetailValueHash => 'Хеш значения';

  @override
  String get traceDetailValuePreview => 'Значение';

  @override
  String get traceDetailMessage => 'Сообщение';

  @override
  String get traceDetailDetail => 'Подробности';
}
