// ignore_for_file: unused_field

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class S extends WidgetsLocalizations {
  Locale? _locale;
  String? _lang;

  S(this._locale) {
    _lang = getLang(_locale!);
  }

  static final GeneratedLocalizationsDelegate delegate =
      GeneratedLocalizationsDelegate();

  static S of(BuildContext context) {
    var s = Localizations.of<S>(context, WidgetsLocalizations);
    s!._lang = getLang(s._locale!);
    return s;
  }

  @override
  TextDirection get textDirection => TextDirection.ltr;

  // Implement required abstract methods
  @override
  String get reorderItemDown => 'Reorder Item Down';
  @override
  String get reorderItemLeft => 'Reorder Item Left';
  @override
  String get reorderItemRight => 'Reorder Item Right';
  @override
  String get reorderItemToEnd => 'Reorder Item To End';
  @override
  String get reorderItemToStart => 'Reorder Item To Start';
  @override
  String get reorderItemUp => 'Reorder Item Up'; // Added this
  String get cut => 'Cut';
  String get copy => 'Copy';
  String get paste => 'Paste';

  String get selectAll => 'Select All';
}

class en extends S {
  en(Locale locale) : super(locale);
}

class GeneratedLocalizationsDelegate
    extends LocalizationsDelegate<WidgetsLocalizations> {
  const GeneratedLocalizationsDelegate();

  List<Locale> get supportedLocales {
    return [Locale("en", "")];
  }

  LocaleResolutionCallback resolution({Locale? fallback}) {
    return (Locale? locale, Iterable<Locale> supported) {
      var languageLocale = Locale(locale!.languageCode, "");
      if (supported.contains(locale))
        return locale;
      else if (supported.contains(languageLocale))
        return languageLocale;
      else {
        var fallbackLocale = fallback ?? supported.first;
        return fallbackLocale;
      }
    };
  }

  @override
  Future<WidgetsLocalizations> load(Locale locale) {
    String lang = getLang(locale);
    switch (lang) {
      case "en":
        return SynchronousFuture<WidgetsLocalizations>(en(locale));
      default:
        return SynchronousFuture<WidgetsLocalizations>(S(locale));
    }
  }

  @override
  bool isSupported(Locale locale) => supportedLocales.contains(locale);

  @override
  bool shouldReload(GeneratedLocalizationsDelegate old) => false;
}

String getLang(Locale l) => l.countryCode != null && l.countryCode!.isEmpty
    ? l.languageCode
    : l.toString();
