library ftr.auction;

import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

enum FtrAuctionType { annual, monthly, bpp }

/// A class representing an FTR Auction for ISONE.
class FtrAuction implements Comparable<FtrAuction> {
  Interval interval;
  Date start;

  /// number of months for this auction
  int noMonths;
  int round;
  Location location = getLocation('America/New_York');
  String name;
  FtrAuctionType auctionType;

  /// Construct an Auction from an auction name.  Valid auction names are
  /// 'F18-1Y-R1', 'F18-1Y-R2', etc. for annual auctions,
  /// 'G18', etc. for monthly auctions.
  /// Rounds were added to the annual auctions starting in 2013.
  FtrAuction.parse(this.name) {
    round = 0;
    if (name.length == 3) {
      /// it's a monthly auction
      var month = parseMonth(name, location: location);
      interval = month.toInterval();
      start = month.startDate;
      noMonths = 1;
      auctionType = FtrAuctionType.monthly;
    } else if (name.contains('-')) {
      /// it's an annual auction
      var year = 2000 + int.parse(name.substring(1, 3));
      interval =
          Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
      start = Date(interval.start.year, interval.start.month, 1,
          location: location);
      auctionType = FtrAuctionType.annual;
      if (year > 2012) {
        round = int.parse(name.substring(8));
      }
      noMonths = 12;
    }
  }

  /// Construct a monthly auction
  FtrAuction.monthly(Month month) {
    interval = Month(month.year, month.month, location: location);
    start = Date(month.year, month.month, 1, location: location);
    noMonths = 1;
    name = formatMYY(month);
  }

  /// Construct an annual auction
  FtrAuction.annual(int year, int round) {
    interval =
        Interval(TZDateTime(location, year), TZDateTime(location, year + 1));
    start = Date(year, 1, 1, location: location);
    noMonths = 12;
    this.round = round;
    if (year > 2012) {
      if (round != 1 && round != 2) {
        throw ArgumentError('Only round 1 or 2 are allowed.');
      }
      name = 'F${year - 2000}-1Y-R${round.toString()}';
    } else {
      name = 'F${year - 2000}-1Y';
      this.round = 0;
    }
  }

  /// Get all the FTR auctions that start after a given date but before "today".
  /// This means that in Dec18, you won't get F19 auction because delivery
  /// period hasn't started yet.
  static List<FtrAuction> auctionsWithSettle(Date fromDate) {
    var year = fromDate.year;
    var today = Date.today();
    var res = <FtrAuction>[];
    for (var i = year; i <= today.year; i++) {
      res.add(FtrAuction.annual(i, 1));
      res.add(FtrAuction.annual(i, 2));
      for (var m = 1; m <= 12; m++) {
        var auction = FtrAuction.monthly(Month(i, m));
        if (auction.start.isAfter(fromDate) && auction.start.isBefore(today)) {
          res.add(auction);
        }
      }
    }
    return res;
  }

  /// the last day of the auction period
  Date get end => Date.fromTZDateTime(interval.end).previous;

  /// A compare functions for sorting FTR Auctions.
  /// First you sort the annual auctions, then you sort by rounds, then the
  /// monthlies by start date.
  @override
  int compareTo(FtrAuction other) {
    var aux = -noMonths.compareTo(other.noMonths);
    if (aux == 0) aux = round.compareTo(other.round);
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
