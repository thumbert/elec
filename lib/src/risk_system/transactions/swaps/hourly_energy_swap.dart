library risk_system.transactions.swaps.hourly_energy_swap;

import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:elec/src/risk_system/locations/electricity_index.dart';
import 'package:timeseries/timeseries.dart';

class HourlyEnergySwap {
  ElectricityIndex energyIndex;
  /// Hourly quantity timeseries. Gaps in the timeseries are allowed and
  /// should not be filled with zeros.
  TimeSeries<num> quantity;
  /// Hourly fixedPrice timeseries. Gaps in the timeseries are allowed.
  TimeSeries<num> fixedPrice;

  Date? tradeDate;
  Date? startDate;
  Date? endDate;
  late BuySell buySell;

  /// Hourly timeseries.  Can be a combination of realized and forward prices.
  late TimeSeries<num> floatingPrice;

  /// A general class for valuing fixed quantity shape energy swaps.
  /// For example, an FTR can be modeled and valued this way.  Or a fixed
  /// shape energy transaction.
  HourlyEnergySwap(this.energyIndex, this.quantity, this.fixedPrice) {
    if (quantity.length != fixedPrice.length) {
      throw ArgumentError('length of quantity != length of fixedPrice');
    }
    if (quantity.first.interval != fixedPrice.first.interval) {
      throw ArgumentError('quantity and fixedPrice timeseries are not aligned');
    }
    if (quantity.first.interval is! Hour) {
      throw ArgumentError('quantity needs to be an hourly timeseries');
    }
    if (fixedPrice.first.interval is! Hour) {
      throw ArgumentError('fixedPrice needs to be an hourly timeseries');
    }
  }

  /// Calculate the realized value for an [interval].
  TimeSeries<num> realizedValue(Interval interval) {
    var qty = TimeSeries.fromIterable(quantity.window(interval));
    var pq = qty.merge(fixedPrice, f: (x,dynamic y) {
      return <String,num?>{
        'quantity': x,
        'fixedPrice': y,
      };
    });
    return pq.merge(floatingPrice, f: (x,dynamic y) {
      return buySell.sign * x!['quantity']! * (y - x['fixedPrice']);
    });
  }


}