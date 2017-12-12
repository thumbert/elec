library iso.isone.isoexpress;

import 'dart:async';
import 'dart:io';
import 'package:func/func.dart';
import 'package:date/date.dart';
import 'package:path/path.dart';
import 'package:elec_server/src/utils/iso_timestamp.dart';
import 'lib_mis_reports.dart' as mis;

Map env = Platform.environment;
String baseDir = env['HOME'] + '/Downloads/Archive/IsoExpress/';
void setBaseDir(String dirName) => baseDir = dirName;
typedef Map Row(Map);

/// There is one report per day.  MIS reports often have more than one
/// report for the same day, as part of settlements.
abstract class IsoExpressReport {
  String reportName;
  Func1<Row,Row> converter;

  /// get the url of this report for this date
  String getUrl(Date asOfDate);

  /// get the filename this report will be downloaded to
  File getFilename(Date asOfDate);

  /// download one day
  Future<Null> downloadDay(Date day) {
    return _downloadUrl(getUrl(day), getFilename(day));
  }

  /// Download a list of days from the website.
  Future downloadDays(List<Date> days) async {
    var aux = days.map((day) => downloadDay(day));
    return Future.wait(aux);
  }
}

class DaBindingConstraintsReport extends IsoExpressReport {
  String reportName =
      'Day-Ahead Energy Market Hourly Final Binding Constraints Report';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/hourlydayaheadconstraints?start=' +
      yyyymmdd(asOfDate) +
      '&end=' +
      yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) => new File(baseDir +
      'GridReports/DaBindingConstraints/Raw/da_binding_constraints_final_' +
      yyyymmdd(asOfDate) +
      '.csv');

  Func1 converter = (Map row) {
    var localDate = (row['Local Date'] as String).substring(0,10);
    var hourEnding = row['Hour Ending'];
    row['hourBeginning'] = parseHourEndingStamp(localDate, hourEnding);
    row.remove('Local Date');
    row.remove('Hour Ending');
    row.remove('H');
    return row;
  };

}

class NcpcRapidResponsePricingReport extends IsoExpressReport {
  String reportName = 'NCPC Rapid Response Pricing Opportunity Cost';
  String getUrl(Date asOfDate) =>
      'https://www.iso-ne.com/transform/csv/ncpc/daily?ncpcType=rrp&start=' +
      yyyymmdd(asOfDate);
  File getFilename(Date asOfDate) => new File(baseDir +
      'NCPC/RapidResponsePricingOpportunityCost/Raw/' +
      'ncpc_rrp_' +
      yyyymmdd(asOfDate) +
      '.csv');
}

/// Download this url to a file.
Future _downloadUrl(String url, File fileout) async {
  if (fileout.existsSync()) {
    return new Future.value(
        print('File ${fileout.path} was already downloaded.  Skipping.'));
  } else {
    if (!new Directory(dirname(fileout.path)).existsSync()) {
      new Directory(dirname(fileout.path)).createSync(recursive: true);
      print('Created directory ${dirname(fileout.path)}');
    }
    HttpClient client = new HttpClient();
    HttpClientRequest request = await client.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    await response.pipe(fileout.openWrite());
  }
}

/// Format a date to the yyyymmdd format, e.g. 20170115.
String yyyymmdd(Date date) => date.toString().replaceAll('-', '');
