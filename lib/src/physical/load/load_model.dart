//
// import 'package:timezone/timezone.dart';
// import 'package:date/date.dart';
// import 'package:timeseries/timeseries.dart';
//
//
// class LoadModel {
//
//   /// The historical data broken by day (for convenience.)
//   late Map<Date,TimeSeries<Map<String,dynamic>>> xDay;
//
//   /// How many days you look back and forward around the day of the
//   /// year for the forecast day to select similar days.  A value of 30, means
//   /// you are looking at 30 days before and 30 days after the same day of the
//   /// year in all historical years for which you have data.
//   int dayBand;
//
//   /// Fully parametric model with good support to holiday schedules/special days.
//   /// [x] is An hourly timeseries with historical data for the independent variables
//   /// and the dependent variable. Needs at least a key "y" for the dependent variable.
//   LoadModel(TimeSeries<Map<String,dynamic>> x, {this.dayBand: 30}) {
//     xDay = _splitDay(x) as Map<Date, TimeSeries<Map<String, dynamic>>>;
//   }
//
//   /// Forecast load according with this model.   [xf] needs to have the
//   /// same independent variables as [x].  If not specified, the model will
//   /// back-cast.
//   /// <p> The forecast is done one day at a time and then the days are joined
//   /// together.
//   // TimeSeries forecast({TimeSeries? xf}) {
//   //
//   // }
//
//   /// Forecast one day.  Find days in the historical data with temperature
//   // TimeSeries _forecastDay(TimeSeries xf) {
//   //
//   // }
//
//
//
//   /// Subset relevant historical data for the "similar days" to [day].
//   ///
//   List<Date> similarDays(Date day) {
//     List daysInBand = _subsetDayBand(day, xDay.keys, dayBand).toList();
//     return daysInBand as List<Date>;
//   }
//
//
// //  DayType getDayType(Date day) {
// //
// //  }
//
// }
//
//
//
//
// /// Return the subset of days that fall in a given band around a fixed day.
// /// So if fixedDay = 1/1/2018,  return days from Dec and Jan of previous years.
// Iterable<Date> _subsetDayBand(Date fixedDay, Iterable<Date> days, int band) {
//   int fixedMonth = fixedDay.month;
//   int fixedDayOfMonth = fixedDay.day;
//   Date dayToCompare;
//
//   return days.where((day) {
//     dayToCompare = new Date(day.year, fixedMonth, fixedDayOfMonth);
//     int dist = dayToCompare.value - day.value;
//     if (dist.abs() <= band) return true;
//     /// you may have the wrong dayToCompare, so move up an year
//     dayToCompare = new Date(day.year+1, fixedMonth, fixedDayOfMonth);
//     dist = dayToCompare.value - day.value;
//     if (dist.abs() <= band) return true;
//     /// you may have the wrong dayToCompare, so move down an year
//     dayToCompare = new Date(day.year-1, fixedMonth, fixedDayOfMonth);
//     dist = dayToCompare.value - day.value;
//     if (dist.abs() <= band) return true;
//
//     return false;
//   });
// }
//
//
// /// Split an hourly timeseries by day
// Map<Date,TimeSeries> _splitDay(TimeSeries x) {
//   Map<Interval, List> grp = {};
//   int N = x.length;
//   for (int i = 0; i < N; i++) {
//     Date group = new Date.containing(x[i].interval.start);
//     grp.putIfAbsent(group, () => []).add(x[i].value);
//   }
//   return new Map.fromIterables(grp.keys as Iterable<Date>, grp.values as Iterable<TimeSeries<dynamic>>);
// }
//
//
