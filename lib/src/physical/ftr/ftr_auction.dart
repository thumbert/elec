library physical.ftr.ftr_auction;

import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

/// A class representing an FTR/TCC Auction
class FtrAuction implements Comparable<FtrAuction> {
  late Interval interval;
  late Date start;

  late Iso iso;

  /// number of months for this auction
  late int monthCount;
  int? round;

  /// for bopp auctions, the month when the auction is held (not the
  /// delivery month).  E.g. for 'J22-boppF22', it is F22.
  Month? boppMonth;

  /// NYISO TCC 6M, 1Y, 2Y auctions have a season,
  /// for example Autumn21, Spring20.  Otherwise, it's null
  String? season;

  Location location = getLocation('America/New_York');
  late String name;

  FtrAuction({
    required this.iso,
    required Month startMonth,
    this.monthCount = 1,
    this.round,
    this.boppMonth,
    this.season,
  });

  /// Construct an Auction from an auction name.
  FtrAuction.parse(this.name, {Iso? iso}) {
    name = name.toUpperCase();
    if (iso == null) {
      this.iso = Iso.newEngland;
    } else {
      this.iso = iso;
    }

    if (iso == Iso.newEngland) {
      _parseIsone(name);
    } else if (iso == Iso.newYork) {
      _parseNyiso(name);
    } else {
      throw ArgumentError('Iso $iso not supported');
    }
  }

  /// Valid auction names are:
  /// 'F18-1Y-R1', 'F18-1Y-R2', etc. for annual auctions,
  /// 'G18', etc. for monthly auctions.
  /// Rounds were added to the annual auctions starting in 2013.
  void _parseIsone(String name) {
    round = 0;
    if (name.length == 3) {
      /// it's a monthly auction
      var month = parseMonth(name, location: location);
      interval = month.toInterval();
      start = month.startDate;
      monthCount = 1;
    } else if (name.contains('-')) {
      /// it's an annual auction
      var year = 2000 + int.parse(name.substring(1, 3));
      interval =
          Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
      start = Date(interval.start.year, interval.start.month, 1,
          location: location);
      if (year > 2012) {
        round = int.parse(name.substring(8));
      }
      monthCount = 12;
    }
    // if (name.length == 3) {
    //   /// it's a monthly auction
    //   var month = parseMonth(name, location: location);
    //   return MonthlyFtrAuction(month);
    // } else if (name.contains('-1Y-')) {
    //   /// it's an annual auction
    //   var year = 2000 + int.parse(name.substring(1, 3));
    //   var round = 0;
    //   if (year > 2012) round = int.parse(name.substring(8));
    //   return FtrAuction.annual(year, round);
    // } else if (name.contains('-bopp')) {
    //   /// it's a bopp auction
    //   var month = parseMonth(name.substring(0, 3), location: location);
    //   var name2 = name.substring(8);
    //   var boppMonth = parseMonth(name2, location: location);
    //   if (!boppMonth.isBefore(month)) {
    //     throw ArgumentError('Bopp month must be before auction month: $name');
    //   }
    //   return MonthlyBoppFtrAuction(month, boppMonth);
    // }
  }

  /// Valid auction names are:
  /// 'G22', 'H22-boppG22', 'J22-boppG22',
  /// 'X21-6M-R4', 'X21-6M-R5', ...
  /// 'X21-1Y-R1', 'X21-1Y-R2', ...
  /// 'K21-2Y-R1', ...
  void _parseNyiso(String name) {
    if (name.length == 3) {
      /// it's a monthly auction
      var month = parseMonth(name, location: location);
      interval = month.toInterval();
      start = month.startDate;
      monthCount = 1;
    } else if (name.contains('-bopp')) {
      /// it's a bopp auction
      var month = parseMYY(name.substring(0, 3), location: location);
      interval = month.toInterval();
      start = month.startDate;
      boppMonth = parseMYY(name.substring(8), location: location);
      monthCount = 1;
    } else if (name.contains('-1Y-')) {
      /// it's an annual auction
      var monthStart = parseMYY(name.substring(0, 3), location: location);
      var monthEnd = monthStart.add(12);
      interval = Interval(monthStart.start, monthEnd.end);
      start = Date(interval.start.year, interval.start.month, 1,
          location: location);
      round = int.parse(name.substring(8, 9));
      monthCount = 12;
      season = name.substring(9);
    } else if (name.contains('-6M-')) {
      var monthStart = parseMYY(name.substring(0, 3), location: location);
      var monthEnd = monthStart.add(6);
      interval = Interval(monthStart.start, monthEnd.end);
      start = Date(interval.start.year, interval.start.month, 1,
          location: location);
      round = int.parse(name.substring(8, 9));
      monthCount = 6;
      season = name.substring(9);
    } else if (name.contains('-2Y-')) {
      var monthStart = parseMYY(name.substring(0, 3), location: location);
      var monthEnd = monthStart.add(24);
      interval = Interval(monthStart.start, monthEnd.end);
      start = Date(interval.start.year, interval.start.month, 1,
          location: location);
      round = int.parse(name.substring(8, 9));
      monthCount = 24;
      season = name.substring(9);
      if (!season!.startsWith('Spring')) {
        throw ArgumentError('The only 2Y auction is in the Spring!');
      }
    } else {
      throw StateError('Don\'t know how to parse $name');
    }
  }

  // /// Construct a monthly auction
  // FtrAuction.monthly(Month month) {
  //   interval = Month(month.year, month.month, location: location);
  //   start = Date(month.year, month.month, 1, location: location);
  //   monthCount = 1;
  //   name = formatMYY(month);
  // }
  //
  // /// Construct an annual auction
  // FtrAuction.annual(int year, this.round) {
  //   interval =
  //       Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
  //   start = Date(year, 1, 1, location: location);
  //   monthCount = 12;
  //   if (year > 2012) {
  //     if (round != 1 && round != 2) {
  //       throw ArgumentError('Only round 1 or 2 are allowed.');
  //     }
  //     name = 'F${year - 2000}-1Y-R${round.toString()}';
  //   } else {
  //     name = 'F${year - 2000}-1Y';
  //     round = 0;
  //   }
  // }

  // /// Get all the FTR auctions that start after a given date but before "today".
  // /// This means that in Dec18, you won't get F19 auction because delivery
  // /// period hasn't started yet.
  // static List<FtrAuction> auctionsWithSettle(Date fromDate) {
  //   var year = fromDate.year;
  //   var today = Date.today(location: fromDate.location);
  //   var res = <FtrAuction>[];
  //   for (var i = year; i <= today.year; i++) {
  //     res.add(FtrAuction.annual(i, 1));
  //     res.add(FtrAuction.annual(i, 2));
  //     for (var m = 1; m <= 12; m++) {
  //       var auction =
  //           FtrAuction.monthly(Month(i, m, location: fromDate.location));
  //       if (auction.start.isAfter(fromDate) && auction.start.isBefore(today)) {
  //         res.add(auction);
  //       }
  //     }
  //   }
  //   return res;
  // }

  /// the last day of the auction period
  Date get end => Date.fromTZDateTime(interval.end).previous;

  /// A compare functions for sorting FTR Auctions.
  /// First you sort the annual auctions, then you sort by rounds, then the
  /// monthlies by start date.
  @override
  int compareTo(FtrAuction other) {
    var aux = -monthCount.compareTo(other.monthCount);
    if (aux == 0 && round != null && other.round != null) {
      aux = round!.compareTo(other.round!);
    }
    if (aux == 0) aux = start.compareTo(other.start);
    return aux;
  }

  @override
  String toString() => name;

  /// Get the number of hours in this bucket; e.g. how many peak hours are
  /// in this auction term?
  int hours(Bucket bucket) {
//    if (_hours.containsKey(  Tuple2(this, bucket)))
//      return _hours[  Tuple2(this, bucket)];
//    var hrs = interval.splitLeft((dt) =>   Hour.beginning(dt));
//    int count = hrs.where((hour) => bucket.containsHour(hour)).length;
//    _hours[  Tuple2(this, bucket)] = count;
    return 0;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(dynamic other) {
    if (other is! FtrAuction) return false;
    FtrAuction auction = other;
    return auction.name == name;
  }
}

/// For Nyiso
class TwoYearFtrAuction extends FtrAuction {
  TwoYearFtrAuction({
    required Iso iso,
    required Month startMonth,
    int? round,
  }) : super(iso: iso, startMonth: startMonth, monthCount: 24, round: round);
}

class AnnualFtrAuction extends FtrAuction {
  AnnualFtrAuction({
    required Iso iso,
    required Month startMonth,
    int? round,
  }) : super(iso: iso, startMonth: startMonth, monthCount: 12, round: round);
}

/// For Nyiso
class SixMonthFtrAuction extends FtrAuction {
  SixMonthFtrAuction({
    required Iso iso,
    required Month startMonth,
    required int round,
  }) : super(iso: iso, startMonth: startMonth, monthCount: 6, round: round);
}

class MonthlyFtrAuction extends FtrAuction {
  MonthlyFtrAuction({
    required Iso iso,
    required Month startMonth,
  }) : super(iso: iso, startMonth: startMonth, monthCount: 1);
}

class MonthlyBoppFtrAuction extends FtrAuction {
  MonthlyBoppFtrAuction({
    required Iso iso,
    required Month startMonth,
    required Month boppMonth,
  }) : super(
            iso: iso,
            startMonth: startMonth,
            monthCount: 1,
            boppMonth: boppMonth);
}
