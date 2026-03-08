import 'package:flutter/widgets.dart';

String tr(
  BuildContext context, {
  required String pt,
  String? es,
  String? en,
}) {
  final localeCode = Localizations.localeOf(context).languageCode;
  if (localeCode == 'es') {
    return es ?? pt;
  }
  if (localeCode == 'en') {
    return en ?? pt;
  }
  return pt;
}
