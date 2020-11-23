library elec.virtuals.lib_virtuals;

import 'package:timezone/timezone.dart';
import 'package:xml/xml.dart' as xml;
import 'package:date/date.dart';
import 'package:timeseries/timeseries.dart';
import 'package:elec/src/physical/price_quantity_pair.dart';

enum VirtualType { increment, decrement }

class Virtual {
  VirtualType virtualType;

  /// An hourly quantity schedule;
  TimeSeries<PriceQuantityPair> schedule;

  /// the location of the virtual
  int ptid;
  Date date;

  Virtual(this.schedule, this.ptid, this.virtualType) {
    isScheduleValid();
  }

  /// Check that the schedule is valid.  It should be one day only.
  bool isScheduleValid() {
    var res = true;
    for (var it in schedule) {
      if (it.interval is! Hour) {
        throw ArgumentError('Not an hourly schedule!');
      }
    }
    date = Date.fromTZDateTime(schedule.first.interval.start);
    var end = Date.fromTZDateTime(schedule.last.interval.start);
    if (date != end) {
      throw ArgumentError(
          'Virtual schedule extends more than one calendar day.');
    }

    return res;
  }
}

/// Make the xml file
String toXml(List<Virtual> virtuals, {String subaccountName: 'VIRT'}) {
  var builder = new xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="utf-8"');
  builder.element('soapenv:Envelope', nest: () {
    builder.attribute(
        'xmlns:mes', 'http://www.markets.iso-ne.com/MUI/eMkt/Messages');
    builder.attribute(
        'xmlns:soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
    builder.element('soapenv:Header');
    builder.element('soapenv:Body', nest: () {
      builder.element('mes:SubmitDemandBid', nest: () {
        builder.element('mes:SubAccount', nest: subaccountName);
        for (var virtual in virtuals) {
          _buildOneVirtual(builder, virtual);
        }
      });
    });
  });
  var out = builder.build();
  return out.toXmlString(pretty: true);
}

_buildOneVirtual(xml.XmlBuilder builder, Virtual virtual) {
  builder.element('mes:DemandBid', nest: () {
    String type = virtual.virtualType == VirtualType.decrement
        ? 'Decrement'
        : 'Increment';
    builder.attribute('ID', virtual.ptid.toString());
    builder.attribute('bidType', type);
    builder.attribute('day', virtual.date.toString());
    builder.element('mes:HourlyProfile', nest: () {
      for (var it in virtual.schedule) {
        builder.element('mes:HourlyBid', nest: () {
          builder.attribute('time', emktDateTime(it.interval.start));
          builder.element('mes:PricePoint', nest: () {
            builder.attribute('MW', it.value.quantity.toStringAsFixed(1));
            builder.attribute('price', it.value.price.toStringAsFixed(1));
          });
        });
      }
    });
  });
}

/// 2012-01-22T04:00:00-05:00"
String emktDateTime(TZDateTime dt) {
  var x = dt.toIso8601String();

  /// remove the microseconds
  var y = x.substring(0, 19) + x.substring(23);

  /// add a column between the timezone hour and minute offset
  return y.substring(0, 22) + ':' + y.substring(22);
}
