/// Whether the system can draw Chinese or Japanese text (Linux).
///
/// None of the bundled fonts carries CJK, so Chinese and Japanese come from
/// the system's fonts. Windows, macOS and Android always have some; a Linux
/// install may not, and then the whole interface is boxes. The engine finds
/// fallback faces through fontconfig, so fontconfig is the one to ask.
library;

import 'dart:io';

/// The interface languages whose text needs a CJK font, mapped to the
/// fontconfig language tag that says a face covers them.
const Map<String, String> kCjkFontLanguages = <String, String>{
  'zh': 'zh-cn',
  'ja': 'ja',
};

/// Answers whether a font for [languageCode] is installed: true or false, or
/// null when it cannot be told (not Linux, no `fc-list`, or the language
/// needs no CJK font).
typedef CjkFontProbe = Future<bool?> Function(String languageCode);

/// The real probe: `fc-list :lang=<tag> family` lists every face covering
/// that language's orthography, so an empty answer means none is installed.
Future<bool?> probeCjkFonts(String languageCode) async {
  final tag = kCjkFontLanguages[languageCode];
  if (tag == null || !Platform.isLinux) return null;
  try {
    final result = await Process.run('fc-list', [':lang=$tag', 'family'])
        .timeout(const Duration(seconds: 5));
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trim().isNotEmpty;
  } catch (_) {
    // fontconfig's tools are not installed, or it hung: do not guess.
    return null;
  }
}

/// The command that installs CJK fonts on this distribution, from
/// `/etc/os-release`, or null when it is not one we know.
Future<String?> cjkFontInstallCommand() async {
  try {
    final text = await File('/etc/os-release').readAsString();
    return cjkFontInstallCommandFor(text);
  } catch (_) {
    return null;
  }
}

/// [cjkFontInstallCommand] for the given `os-release` contents.
String? cjkFontInstallCommandFor(String osRelease) {
  final ids = <String>{};
  for (final line in osRelease.split('\n')) {
    final eq = line.indexOf('=');
    if (eq < 0) continue;
    final key = line.substring(0, eq).trim();
    if (key != 'ID' && key != 'ID_LIKE') continue;
    final value = line.substring(eq + 1).trim().replaceAll(RegExp('["\']'), '');
    ids.addAll(value.split(RegExp(r'\s+')));
  }
  if (ids.intersection({'debian', 'ubuntu'}).isNotEmpty) {
    return 'sudo apt install fonts-noto-cjk';
  }
  if (ids.intersection({'fedora', 'rhel', 'centos'}).isNotEmpty) {
    return 'sudo dnf install google-noto-sans-cjk-fonts';
  }
  if (ids.intersection({'arch', 'manjaro'}).isNotEmpty) {
    return 'sudo pacman -S noto-fonts-cjk';
  }
  if (ids.intersection({'opensuse', 'suse', 'opensuse-tumbleweed'}).isNotEmpty) {
    return 'sudo zypper install noto-sans-cjk-fonts';
  }
  return null;
}
