import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/fonts.dart';
import '../../platform/cjk_fonts.dart';
import '../providers/settings_provider.dart';
import 'app_menu_bar.dart';

/// How [CjkFontNotice] asks whether a CJK font is installed. Tests override it.
final cjkFontProbeProvider = Provider<CjkFontProbe>((ref) => probeCjkFonts);

/// How the notice finds the install command for this system. Tests override it.
final cjkFontInstallCommandProvider =
    Provider<Future<String?> Function()>((ref) => cjkFontInstallCommand);

/// SharedPreferences key: the user ticked "Don't show again". Kept out of
/// `AppSettings` on purpose — it is not a preference the dialog edits, and
/// the Preferences dialog's Cancel must not bring the warning back.
const String kCjkFontWarningDismissedKey = 'cjk_font_warning_dismissed';

/// Warns, once per run and language, when the interface is in Chinese or
/// Japanese and the system has no font that can draw it (Linux — see
/// `platform/cjk_fonts.dart`).
///
/// The warning is in **English, deliberately**: it appears exactly when the
/// translated text would come out as boxes. It offers to switch the interface
/// to English and to stop asking.
///
/// Sits in `MaterialApp.builder`, below `Localizations` (so it sees the locale
/// that was resolved, from the preference or the system) and above the
/// navigator (so it shows its dialog through [rootNavigatorKey]).
class CjkFontNotice extends ConsumerStatefulWidget {
  const CjkFontNotice({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CjkFontNotice> createState() => _CjkFontNoticeState();
}

class _CjkFontNoticeState extends ConsumerState<CjkFontNotice> {
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    if (kCjkFontLanguages.containsKey(language) && _checked.add(language)) {
      unawaited(_check(language));
    }
    return widget.child;
  }

  Future<void> _check(String language) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(kCjkFontWarningDismissedKey) ?? false) return;
    final installed = await ref.read(cjkFontProbeProvider)(language);
    if (installed != false || !mounted) return;
    final command = await ref.read(cjkFontInstallCommandProvider)();
    // The navigator may not have built yet on the first frame.
    await WidgetsBinding.instance.endOfFrame;
    final navContext = rootNavigatorKey.currentContext;
    if (!mounted || navContext == null || !navContext.mounted) return;
    // Still the language that was checked? A switch away meanwhile makes the
    // warning moot.
    if (Localizations.localeOf(context).languageCode != language) return;
    final choice = await showDialog<_NoticeChoice>(
      context: navContext,
      builder: (_) => CjkFontNoticeDialog(
        languageName: language == 'ja' ? 'Japanese' : 'Chinese',
        installCommand: command,
      ),
    );
    if (choice == null) return;
    if (choice.dontShowAgain) {
      await prefs.setBool(kCjkFontWarningDismissedKey, true);
    }
    if (choice.useEnglish) {
      await ref.read(settingsProvider.notifier).setAppLanguage('en');
    }
  }
}

class _NoticeChoice {
  const _NoticeChoice({required this.dontShowAgain, required this.useEnglish});

  final bool dontShowAgain;
  final bool useEnglish;
}

/// The warning itself. English only — see [CjkFontNotice].
class CjkFontNoticeDialog extends StatefulWidget {
  const CjkFontNoticeDialog({
    super.key,
    required this.languageName,
    this.installCommand,
  });

  final String languageName;

  /// The command for this distribution, or null to list the common ones.
  final String? installCommand;

  @override
  State<CjkFontNoticeDialog> createState() => _CjkFontNoticeDialogState();
}

class _CjkFontNoticeDialogState extends State<CjkFontNoticeDialog> {
  bool _dontShowAgain = false;

  static const List<String> _commonCommands = <String>[
    'sudo apt install fonts-noto-cjk',
    'sudo dnf install google-noto-sans-cjk-fonts',
    'sudo pacman -S noto-fonts-cjk',
  ];

  void _close({required bool useEnglish}) => Navigator.of(context).pop(
        _NoticeChoice(dontShowAgain: _dontShowAgain, useEnglish: useEnglish),
      );

  @override
  Widget build(BuildContext context) {
    final commands = widget.installCommand != null
        ? <String>[widget.installCommand!]
        : _commonCommands;
    final mono = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontFamily: kMonospaceFont);
    return AlertDialog(
      title: Text('No ${widget.languageName} font installed'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The interface is set to ${widget.languageName}, but this system '
              'has no font that can display it, so text may appear as empty '
              'boxes. Install a CJK font, then restart Noo:',
            ),
            const SizedBox(height: 12),
            for (final command in commands)
              Row(
                children: [
                  Expanded(child: SelectableText(command, style: mono)),
                  IconButton(
                    tooltip: 'Copy',
                    icon: const Icon(Icons.copy, size: 18),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: command)),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              title: const Text("Don't show this again"),
              value: _dontShowAgain,
              onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _close(useEnglish: true),
          child: const Text('Switch to English'),
        ),
        FilledButton(
          onPressed: () => _close(useEnglish: false),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
