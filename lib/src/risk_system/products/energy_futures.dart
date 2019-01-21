part of elec.risk_system;


class EnergyFutures extends Object with BaseTrade {
  EnergyHub hub;
  Bucket bucket;
  num fixPrice;
  num mw;

  EnergyFutures(Date tradeDate, Interval term, BuySell buySell,
      this.mw, this.hub, this.bucket, this.fixPrice) {
    this.tradeDate = tradeDate;
    this.tradeTerm = term;
    this.buySell = buySell;
  }

  EnergyFutures.fromMap(Map<String,dynamic> x) {
    hub = EnergyHub.fromMap(x);
    tradeDate = Date.parse(x['tradeDate']);
    tradeTerm = parseTerm(x['strip']);
    buySell = BuySell.parse(x['buy/sell']);
    bucket = Bucket.parse(x['bucket']);
    fixPrice = x['fixPrice'];
    mw = x['mw'];
  }

  TimeSeries<num> position(Date asOfDate, TimeAggregation timeAggregation) {
    var out = TimeSeries<num>();
    if (asOfDate.start.isAfter(tradeTerm.end)) return out;
    var _hours = tradeTerm
        .withStart(asOfDate.start)
        .splitLeft((dt) => Hour.beginning(dt))
        .where((hour) => bucket.containsHour(hour)).cast<Hour>();
    var _hourlyQty = TimeSeries.fill(_hours, buySell.sign * mw);
    switch (timeAggregation) {
      case TimeAggregation.hourly : {
        out = _hourlyQty;
        break;
      }
      case TimeAggregation.daily : {
        out = toDaily(_hourlyQty, sum);
        break;
      }
      case TimeAggregation.monthly : {
        out = toMonthly(_hourlyQty, sum);
        break;
      }
    }
    return out;
  }

  Map<String,dynamic> toMap() {
    var out = <String,dynamic>{
      'tradeDate': tradeTerm.toString(),
      'strip': tradeTerm.toString(),
      'startDate': startDate.toString(),
      'endDate': endDate.toString(),
      'buy/sell': buySell.toString(),
      'mw': mw,
      'commodity': 'energy',
      'product': 'energy futures',
      'hub': hub.toString(),
      'bucket': bucket.name,
      'fixPrice': fixPrice,
    };
    return out;
  }

}

