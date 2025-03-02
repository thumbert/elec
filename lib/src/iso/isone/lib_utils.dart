import 'dart:io';

import 'package:date/date.dart';
import 'package:http/http.dart';

/// Check if the ISO has cleared the DA market 
Future<bool> isDamPublished(Date date) async {
  final tomorrow = Date.today(location: date.location).next;
  if (date.isBefore(tomorrow)) {
    return true;
  }
  if (date.isAfter(tomorrow)) {
    return false;
  }

  var url =
      'https://www.iso-ne.com/isoexpress/web/reports/pricing/-/tree/lmps-da-hourly';
  var res = await get(Uri.parse(url));
  if (res.statusCode != HttpStatus.ok) {
    throw StateError('Failed to read the url $url');
  }
  var text = res.body;
  final tag = 'WW_DALMP_ISO_${date.toIso8601String().replaceAll('-', '')}.csv';
  return text.contains(tag);
}
