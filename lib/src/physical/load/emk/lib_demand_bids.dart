import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:xml/xml.dart' as xml;

/// See https://www.iso-ne.com/static-assets/documents/100030/emarket-data-exchange-specification-version-13.1.pdf
/// Section 6.1.1.2

enum DemandBidType {
  fixed,
  priceSensitive;
}

String toXml(List<DemandBid> bids, {required String subaccountName}) {
  var builder = xml.XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');
  builder.element('soapenv:Envelope', nest: () {
    builder.attribute(
        'xmlns:mes', 'http://www.markets.iso-ne.com/MUI/eMkt/Messages');
    builder.attribute(
        'xmlns:soapenv', 'http://schemas.xmlsoap.org/soap/envelope/');
    builder.element('soapenv:Header');
    builder.element('soapenv:Body', nest: () {
      builder.element('mes:SubmitDemandBid', nest: () {
        builder.element('mes:SubAccount', nest: subaccountName);
        for (var bid in bids) {
          bid.buildOne(builder);
        }
      });
    });
  });
  var out = builder.buildDocument();
  return out.toXmlString(pretty: true);
}

final zoneNames = <int, String>{
  4001: '.Z.MAINE',
  4002: '.Z.NEWHAMPSHIRE',
  4004: '.Z.CONNECTICUT',
  4005: '.Z.RHODEISLAND',
  4006: '.Z.SEMASS',
  4008: '.Z.WCMASS',
  4010: '.Z.NEMASSBOST',
};

abstract class DemandBid {
  xml.XmlBuilder buildOne(xml.XmlBuilder builder);
}

class DemandBidFixed extends DemandBid {
  DemandBidFixed(
      {required this.ptid, required this.date, required this.quantity});

  final int ptid;
  final Date date;
  TimeSeries<num> quantity;

  @override
  xml.XmlBuilder buildOne(xml.XmlBuilder builder) {
    builder.element('DemandBid', nest: () {
      builder.attribute('bidType', 'Fixed');
      builder.attribute('day', date.toIso8601String());
      builder.attribute('ID', ptid.toString());
      builder.element('NodeName', nest: zoneNames[ptid]!);
      builder.element('HourlyProfile', nest: () {
        for (var i = 0; i < quantity.length; i++) {
          builder.element('HourlyBid', nest: () {
            builder.attribute('time', emktDateTime(quantity[i].interval.start));
            builder.element('mes:FixedMW',
                nest: quantity[i].value.toStringAsFixed(1));
          });
        }
      });
    });
    return builder;
  }
}

class DemandBidPriceSensitive extends DemandBid {
  DemandBidPriceSensitive(
      {required this.ptid, required this.date, required this.schedule});

  final int ptid;
  final Date date;
  TimeSeries<PriceQuantityPair> schedule;

  @override
  xml.XmlBuilder buildOne(xml.XmlBuilder builder) {
    builder.element('DemandBid', nest: () {
      builder.attribute('bidType', 'PriceSensitive');
      builder.attribute('day', date.toIso8601String());
      builder.attribute('ID', ptid.toString());
      builder.element('NodeName', nest: zoneNames[ptid]!);
      builder.element('HourlyProfile', nest: () {
        var hours = date.hours();
        for (var i = 0; i < 24; i++) {
          builder.element('HourlyBid', nest: () {
            // var time = date.add(Duration(hours: i));
            // builder.attribute('time', emktDateTime(time));
            // builder.element('PricePoint', nest: () {
            //   builder.attribute('MW', quantity[i].toStringAsFixed(1));
            //   builder.attribute('price', price[i].toStringAsFixed(1));
            // });
          });
        }
      });
    });
    return builder;
  }
}

/// 2012-01-22T04:00:00-05:00"
String emktDateTime(TZDateTime dt) {
  var x = dt.toIso8601String();

  /// remove the microseconds
  var y = x.substring(0, 19) + x.substring(23);

  /// add a column between the timezone hour and minute offset
  return '${y.substring(0, 22)}:${y.substring(22)}';
}
