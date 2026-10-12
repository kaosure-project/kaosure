import 'package:flutter/material.dart';

// Native names remain recognizable after changing the display language.
const appLanguageNames = <String, String>{
  'th': 'ไทย',
  'en': 'English',
  'ja': '日本語',
  'zh-Hans': '简体中文',
  'my': 'မြန်မာ',
  'lo': 'ລາວ',
  'vi': 'Tiếng Việt',
};

String appLanguageName(Locale? locale, String systemLabel) {
  if (locale == null) { return systemLabel; }
  if (locale.languageCode == 'zh') { return appLanguageNames['zh-Hans']!; }
  return appLanguageNames[locale.toLanguageTag()] ??
      appLanguageNames[locale.languageCode] ?? locale.toLanguageTag();
}
