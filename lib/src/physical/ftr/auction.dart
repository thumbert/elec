library ftr.auction;

import 'package:timezone/timezone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
//import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

enum FtrAuctionType {annual, monthly, bpp}

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
      var month = parseMonth(name, location: location) as Month;
      interval = month.toInterval();
      start = month.startDate;
      noMonths = 1;
      auctionType = FtrAuctionType.monthly;

    } else if (name.contains('-')) {
      /// it's an annual auction
      int year = 2000 + int.parse(name.substring(1,3));
      interval = new Interval(new TZDateTime(location, year),
          new TZDateTime(location, year+1));
      start = new Date(interval.start.year, interval.start.month, 1, location: location);
      auctionType = FtrAuctionType.annual;
      if (year > 2012)
        round = int.parse(name.substring(8));
      noMonths = 12;
    }
  }

  /// Construct a monthly auction
  FtrAuction.monthly(Month month) {
    interval = new Month(month.year, month.month, location: location);
    start = new Date(month.year, month.month, 1, location: location);
    noMonths = 1;
    name = formatMYY(month);
  }

  /// Construct an annual auction
  FtrAuction.annual(int year, int round) {
    interval = new Interval(new TZDateTime(location, year),
        new TZDateTime(location, year+1));
    start = new Date(year, 1, 1, location: location);
    noMonths = 12;
    this.round = round;
    if (year > 2012) {
      if (round != 1 && round != 2)
        throw new ArgumentError('Only round 1 or 2 are allowed.');
      name = 'F${year-2000}-1Y-R${round.toString()}';
    } else {
      name = 'F${year-2000}-1Y';
      this.round = 0;
    }
  }

  /// Get all the FTR auctions that start after a given date but before "today".
  /// This means that in Dec18, you won't get F19 auction because delivery
  /// period hasn't started yet.
  static List<FtrAuction> auctionsWithSettle(Date fromDate) {
    int year = fromDate.year;
    Date today = Date.today();
    var res = <FtrAuction>[];
    for (int i=year; i<=today.year; i++) {
      res.add(new FtrAuction.annual(i, 1));
      res.add(new FtrAuction.annual(i, 2));
      for (int m=1; m<=12; m++) {
        var auction = new FtrAuction.monthly(new Month(i, m));
        if (auction.start.isAfter(fromDate) && auction.start.isBefore(today))
          res.add(auction);
      }
    }
    return res;
  }

  /// the last day of the auction period
  Date get end => new Date.fromTZDateTime(interval.end).previous;

  /// A compare functions for sorting FTR Auctions.
  /// First you sort the annual auctions, then you sort by rounds, then the
  /// monthlies by start date.
  int compareTo(FtrAuction other) {
    var aux = -this.noMonths.compareTo(other.noMonths);
    if (aux == 0)
      aux = this.round.compareTo(other.round);
    if (aux == 0)
      aux = this.start.compareTo(other.start);
    return aux;
  }

  String toString() => name;

  /// Get the number of hours in this bucket; e.g. how many peak hours are
  /// in this auction term?
  int hours(Bucket bucket) {
//    if (_hours.containsKey(new Tuple2(this, bucket)))
//      return _hours[new Tuple2(this, bucket)];
//    var hrs = interval.splitLeft((dt) => new Hour.beginning(dt));
//    int count = hrs.where((hour) => bucket.containsHour(hour)).length;
//    _hours[new Tuple2(this, bucket)] = count;
    return 0;
  }

  int get hashCode => name.hashCode;

  bool operator ==(dynamic other) {
    if (other is! FtrAuction) return false;
    FtrAuction auction = other;
    return auction.name == name;
  }

}

