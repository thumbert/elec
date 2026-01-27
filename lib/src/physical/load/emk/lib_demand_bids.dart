import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:timeseries/timeseries.dart';
import 'package:timezone/timezone.dart';
import 'package:xml/xml.dart' as xml;

/// See https://www.iso-ne.com/static-assets/documents/100030/emarket-data-exchange-specification-version-13.1.pdf
/// Section 6.1.1.2

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

abstract class DemandBid {
  xml.XmlBuilder buildOne(xml.XmlBuilder builder);
}

class DemandBidFixed extends DemandBid {
  DemandBidFixed(
      {required this.ptid, required this.date, required this.quantity}) {
    if (date.location != IsoNewEngland.location) {
      throw ArgumentError(
          'Date needs to have the IsoNewEngland timezone location.');
    }
    // validate schedule
    for (var it in quantity) {
      if (it.interval is! Hour) {
        throw ArgumentError('Quantity schedule must be hourly.');
      }
      if (it.interval.start.location != IsoNewEngland.location) {
        throw ArgumentError(
            'Quantity schedule intervals must have the IsoNewEngland timezone location.');
      }
      if (Date.containing(it.interval.start) != date) {
        throw ArgumentError(
            'Quantity schedule must be for the same date as the bid.');
      }
      if (!zoneNames.containsKey(ptid)) {
        throw ArgumentError('PTID $ptid not recognized in zone names map.');
      }
      if (it.value < 0) {
        throw ArgumentError('Quantity values must be non-negative.');
      }
    }
  }

  final int ptid;
  final Date date;
  TimeSeries<num> quantity;

  @override
  xml.XmlBuilder buildOne(xml.XmlBuilder builder) {
    builder.element('mes:DemandBid', nest: () {
      builder.attribute('bidType', 'Fixed');
      builder.attribute('day', date.toIso8601String());
      builder.attribute('ID', ptid.toString());
      builder.element('mes:NodeName', nest: zoneNames[ptid]!);
      builder.element('mes:HourlyProfile', nest: () {
        for (var i = 0; i < quantity.length; i++) {
          builder.element('mes:HourlyBid', nest: () {
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
      {required this.ptid, required this.date, required this.schedule}) {
    if (date.location != IsoNewEngland.location) {
      throw ArgumentError(
          'Date needs to have the IsoNewEngland timezone location.');
    }
    // validate schedule
    for (var it in schedule) {
      if (it.interval is! Hour) {
        throw ArgumentError('Schedule must be hourly.');
      }
      if (it.interval.start.location != IsoNewEngland.location) {
        throw ArgumentError(
            'Schedule intervals must have the IsoNewEngland timezone location.');
      }
      if (Date.containing(it.interval.start) != date) {
        throw ArgumentError('Schedule must be for the same date as the bid.');
      }
      if (!zoneNames.containsKey(ptid)) {
        throw ArgumentError('PTID $ptid not recognized in zone names map.');
      }
      if (it.value.isEmpty) {
        throw ArgumentError('Price-quantity schedule cannot be empty.');
      }
      // check that prices are increasing from one pq to the next
      num? lastPrice;
      for (var pq in it.value) {
        if (lastPrice != null && pq.price <= lastPrice) {
          throw ArgumentError(
              'Prices in price-quantity pairs must be strictly increasing.');
        }
        if (pq.quantity < 0) {
          throw ArgumentError('Quantity values must be non-negative.');
        }
        lastPrice = pq.price;
      }
    }
  }

  final int ptid;
  final Date date;
  TimeSeries<List<PriceQuantityPair>> schedule;

  @override
  xml.XmlBuilder buildOne(xml.XmlBuilder builder) {
    builder.element('mes:DemandBid', nest: () {
      builder.attribute('bidType', 'PriceSensitive');
      builder.attribute('day', date.toIso8601String());
      builder.attribute('ID', ptid.toString());
      builder.element('mes:NodeName', nest: zoneNames[ptid]!);
      builder.element('mes:HourlyProfile', nest: () {
        for (var i = 0; i < schedule.length; i++) {
          builder.element('mes:HourlyBid', nest: () {
            builder.attribute('time', emktDateTime(schedule[i].interval.start));
            for (var j = 0; j < schedule[i].value.length; j++) {
              builder.element('mes:PricePoint', nest: () {
                builder.attribute(
                    'MW', schedule[i].value[j].quantity.toStringAsFixed(1));
                builder.attribute(
                    'price', schedule[i].value[j].price.toStringAsFixed(2));
              });
            }
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
  // remove the microseconds
  var y = x.substring(0, 19) + x.substring(23);
  // add a column between the timezone hour and minute offset
  return '${y.substring(0, 22)}:${y.substring(22)}';
}


final zoneNames = <int, String>{
  4001: '.Z.MAINE',
  4002: '.Z.NEWHAMPSHIRE',
  4004: '.Z.CONNECTICUT',
  4005: '.Z.RHODEISLAND',
  4006: '.Z.SEMASS',
  4007: '.Z.WCMASS',
  4008: '.Z.NEMASSBOST',
};
