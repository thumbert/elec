library ftr.auction;

import 'package:timezone/standalone.dart';
import 'package:elec_server/src/utils/timezone_utils.dart';
//import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

enum FtrAuctionType {annual, monthly, bpp}

/// A class representing an FTR Auction for ISONE.
class FtrAuction {
  Interval interval;
  Date start;
  /// number of months for this auction
  int noMonths;
  int round;
  Location location = getLocation('US/Eastern');
  String name;
  RegExp _regExpAnnual = new RegExp(r'F(\d{2})-1Y-R(\d{1})');
  FtrAuctionType auctionType;

  /// Construct an Auction from an auction name.  Valid auction names are
  /// 'F18-1Y-R1', 'F18-1Y-R2', etc. for annual auctions,
  /// 'G18', etc. for monthly auctions.
  FtrAuction.parse(this.name) {
    if (name.length == 3) {
      /// it's a monthly auction
      var month = parseMonth(name, location: location) as Month;
      interval = month.toInterval();
      start = month.startDate;
      noMonths = 1;
      auctionType = FtrAuctionType.monthly;

    } else if (name.contains('-')) {
      /// it's an annual auction
      var matches = _regExpAnnual.allMatches(name);
      var match = matches.elementAt(0);
      int year = 2000 + int.parse(match.group(1));
      round = int.parse(match.group(2));
      interval = new Interval(new TZDateTime(location, year),
          new TZDateTime(location, year+1));
      start = new Date(interval.start.year, interval.start.month, 1, location: location);
      auctionType = FtrAuctionType.annual;
    }
  }

  String toString() => name;

  String _makeName() {
    StringBuffer res = new StringBuffer();
    res.write(new Month(start.year, start.month).toString());
    if (noMonths > 1)
      res.write('-${noMonths}M');
    if (round != null)
      res.write('-R$round');

    return res.toString();
  }
}
