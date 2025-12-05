import 'package:dama/stat/descriptive/summary.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/time.dart';
import 'package:timeseries/timeseries.dart';

class EnergyFutures extends Object with BaseTrade {
  late final EnergyHub hub;
  late final Bucket bucket;
  late final num fixedPrice;
  late final num mw;

  EnergyFutures(Date tradeDate, Interval term, BuySell buySell,
      this.mw, this.hub, this.bucket, this.fixedPrice) {
    this.tradeDate = tradeDate;
    tradeTerm = term;
    this.buySell = buySell;
  }

  EnergyFutures.fromMap(Map<String,dynamic> x) {
    hub = EnergyHub.fromMap(x);
    tradeDate = Date.parse(x['tradeDate']);
    tradeTerm = parseTerm(x['strip']);
    buySell = BuySell.parse(x['buy/sell']);
    bucket = Bucket.parse(x['bucket']);
    fixedPrice = x['fixedPrice'];
    mw = x['mw'];
  }

  TimeSeries<num> position(Date asOfDate, TimeAggregation timeAggregation) {
    var out = TimeSeries<num>();
    if (asOfDate.start.isAfter(tradeTerm!.end)) return out;
    var hours = tradeTerm!
        .withStart(asOfDate.start)
        .splitLeft((dt) => Hour.beginning(dt))
        .where((hour) => bucket.containsHour(hour)).cast<Hour>();
    var hourlyQty = TimeSeries.fill(hours, buySell.sign * mw);
    switch (timeAggregation) {
      case TimeAggregation.hour : {
        out = hourlyQty;
        break;
      }
      case TimeAggregation.day : {
        out = toDaily(hourlyQty, sum);
        break;
      }
      case TimeAggregation.month : {
        out = toMonthly(hourlyQty, sum);
        break;
      }
    }
    return out;
  }

  Map<String,dynamic> toMap() {
    var out = <String,dynamic> {
      'tradeDate': tradeDate.toString(),
      'strip': tradeTerm.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'buy/sell': buySell.toString(),
      'mw': mw,
      'commodity': 'energy',
      'product': 'energy futures',
      'hub': hub.toString(),
      'bucket': bucket.name,
      'fixPrice': fixedPrice,
    };
    return out;
  }

}

