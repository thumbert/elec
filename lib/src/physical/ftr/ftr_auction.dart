library physical.ftr.ftr_auction;

import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

/// A class representing an FTR/TCC Auction
mixin FtrAuction implements Comparable<FtrAuction> {
  late Iso iso;
  late Date start;

  /// number of months for this auction
  late int monthCount;
  Location location = getLocation('America/New_York');

  late Interval interval;
  late String name;

  /// Construct an Auction from an auction name.
  ///
  static FtrAuction parse(String name, {required Iso iso}) {
    if (iso == Iso.newEngland) {
      return _parseIsone(name);
    } else if (iso == Iso.newYork) {
      return _parseNyiso(name);
    } else {
      throw ArgumentError('Iso $iso not supported');
    }
  }

  /// Valid auction names are:
  /// 'F18-1Y-R1', 'F18-1Y-R2', etc. for annual auctions,
  /// 'G18', etc. for monthly auctions.
  /// Rounds were added to the annual auctions starting in 2013.
  static FtrAuction _parseIsone(String name) {
    var month = parseMYY(name.substring(0, 3),
        location: Iso.newEngland.preferredTimeZoneLocation);
    if (name.length == 3) {
      /// it's a monthly auction
      ///
      return MonthlyFtrAuction(iso: Iso.newEngland, startMonth: month);
    } else if (name.contains('-bopp')) {
      /// it's a monthly bopp auction
      ///
      var boppMonth = parseMYY(name.substring(8),
          location: Iso.newYork.preferredTimeZoneLocation);
      return MonthlyBoppFtrAuction(
          iso: Iso.newEngland, startMonth: month, boppMonth: boppMonth);
    } else if (name.contains(RegExp('-1Y-?'))) {
      /// it's an annual auction
      int round = 0;
      if (month.year >= 2013) {
        round = int.parse(name.substring(8)); // only from 2013
      }
      return AnnualFtrAuction(
          iso: Iso.newEngland, startMonth: month, round: round);
    } else {
      throw StateError('Don\'t know how to parse $name for IsoNewEngland');
    }
  }

  /// Valid auction names are:
  /// 'G22', 'H22-boppG22', 'J22-boppG22',
  /// 'X21-6M-R4Autumn21', 'X21-6M-R5Autumn21', ...
  /// 'X21-1Y-R1Autumn21', 'X21-1Y-R2Autumn21', ...
  /// 'K21-2Y-R1Spring21', ...
  static FtrAuction _parseNyiso(String name) {
    var month = parseMYY(name.substring(0, 3),
        location: Iso.newYork.preferredTimeZoneLocation);
    if (name.length == 3) {
      /// it's a monthly auction
      ///
      return MonthlyFtrAuction(iso: Iso.newYork, startMonth: month);
    } else if (name.contains('-bopp')) {
      /// it's a bopp auction
      ///
      var boppMonth = parseMYY(name.substring(8),
          location: Iso.newYork.preferredTimeZoneLocation);
      return MonthlyBoppFtrAuction(
          iso: Iso.newYork, startMonth: month, boppMonth: boppMonth);
    } else {
      /// is a 6M, 1Y or 2Y auction
      ///
      var tokens = name.split('-');
      if (tokens.length != 3) {
        throw ArgumentError('Wrong auction name $name');
      }
      var round = int.parse(tokens[2].substring(1, 2));
      if (name.contains('-1Y-')) {
        /// it's an annual auction
        ///
        return AnnualFtrAuction(
            iso: Iso.newYork, startMonth: month, round: round);
      } else if (name.contains('-6M-')) {
        /// it's a six month auction
        ///
        return SixMonthFtrAuction(
            iso: Iso.newYork, startMonth: month, round: round);
      } else if (name.contains('-2Y-')) {
        /// it's a 2 year auction
        ///
        return TwoYearFtrAuction(iso: Iso.newYork, startMonth: month);
      } else {
        throw StateError('Don\'t know how to parse $name for Nyiso');
      }
    }
  }

  /// the last day of the auction period
  Date get end => Date.containing(interval.end).previous;

  /// A compare functions for sorting FTR Auctions.
  /// First you sort the annual auctions, then you sort by rounds, then the
  /// monthlies by start date.  MonthlyBopp come before Monthly auctions.
  @override
  int compareTo(FtrAuction other) {
    // compare start dates
    var aux = start.compareTo(other.start);
    // first compare auction length
    if (aux == 0) {
      aux = -monthCount.compareTo(other.monthCount);
    }
    // for the same start date and auction length,
    // compare rounds for multi month auctions
    if (aux == 0) {
      if (monthCount > 1) {
        late int round;
        late int otherRound;
        round = (this as AuctionWithRound).round;
        otherRound = (other as AuctionWithRound).round;
        aux = round.compareTo(otherRound);
      } else {
        // month count == 1, so it's a monthly or MonthlyBopp auctions
        // with same start date. Monthly bopp gets ordered by boppMonth,
        // monthly comes after monthlyBopp
        if (this is MonthlyBoppFtrAuction) {
          var a1 = this as MonthlyBoppFtrAuction;
          if (other is MonthlyBoppFtrAuction) {
            aux = a1.boppMonth.compareTo(other.boppMonth);
          } else {
            // other is a Monthly auction
            aux = -1;
          }
        } else {
          // this is a MonthlyAuction, and other is a MonthlyBoppAuction with
          // same start
          aux = 1;
        }
      }
    }
    return aux;
  }

  @override
  String toString() => name;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! FtrAuction) return false;
    FtrAuction auction = other;
    return auction.name == name;
  }
}

mixin AuctionWithRound {
  late int round;
}

class TwoYearFtrAuction extends Object with FtrAuction, AuctionWithRound {
  late String _season;

  TwoYearFtrAuction({
    required Iso iso,
    required Month startMonth,
    round = 1,
  }) {
    start = startMonth.startDate;
    monthCount = 24;
    interval = Interval(start.start, startMonth.add(monthCount).start);
    if (startMonth.month != 5) {
      throw ArgumentError('Two year TCC auctions only start in May.');
    }
    var yy = startMonth.year - 2000;
    _season = 'Spring$yy';
    name = '${formatMYY(startMonth)}-2Y-R$round$_season';
  }

  String get season => _season;
}

class AnnualFtrAuction extends Object with FtrAuction, AuctionWithRound {
  String _season = '';

  AnnualFtrAuction({
    required Iso iso,
    required Month startMonth,
    required int round,
  }) {
    start = startMonth.startDate;
    monthCount = 12;
    interval = Interval(start.start, startMonth.add(monthCount).start);
    this.round = round;

    if (iso == Iso.newYork) {
      if (startMonth.month != 5 && startMonth.month != 11) {
        throw ArgumentError('Annual TCC auctions start in May or Nov only.');
      }
      var yy = startMonth.year - 2000;
      // set the season
      if (startMonth.month == 11) {
        _season = 'Autumn$yy';
      } else {
        if (round == 8) {
          _season = 'Autumn${yy - 1}'; // for example K21-1Y-R8Autumn20
        } else {
          _season = 'Spring$yy';
        }
      }
      name = '${formatMYY(startMonth)}-1Y-R$round$_season';
      //
      //
    } else if (iso == Iso.newEngland) {
      if (round == 0) {
        name = '${formatMYY(startMonth)}-1Y';
      } else {
        name = '${formatMYY(startMonth)}-1Y-R$round';
      }
      //
      //
    } else {
      throw ArgumentError('Iso $iso not yet supported.');
    }
  }

  /// Empty for ISONE.
  String get season => _season;
}

class SixMonthFtrAuction extends Object with FtrAuction, AuctionWithRound {
  late String _season;

  SixMonthFtrAuction({
    required Iso iso,
    required Month startMonth,
    required int round,
  }) {
    // TODO: only for Nyiso for now, need to extend to other Iso
    start = startMonth.startDate;
    monthCount = 6;
    interval = Interval(start.start, startMonth.add(monthCount).start);
    this.round = round;
    if (startMonth.month != 5 && startMonth.month != 11) {
      throw ArgumentError('Six month TCC auctions start in May or Nov only.');
    }
    var yy = startMonth.year - 2000;
    // set the season
    if (startMonth.month == 11) {
      _season = 'Autumn$yy';
    } else {
      _season = 'Spring$yy';
    }
    name = '${formatMYY(startMonth)}-6M-R$round$_season';
    // Only in Autumn you have 6M-R4AutumnYY, in the Spring 6M-R5SpringYY
    if (round < 4 || (round == 4 && !_season.startsWith('Autumn'))) {
      throw StateError('Invalid round $round for auction $name');
    }
  }

  String get season => _season;
}

class MonthlyFtrAuction extends Object with FtrAuction {
  MonthlyFtrAuction({
    required Iso iso,
    required Month startMonth,
  }) {
    start = startMonth.startDate;
    monthCount = 1;
    interval = Interval(start.start, startMonth.end);
    name = formatMYY(startMonth);
  }
}

class MonthlyBoppFtrAuction extends Object with FtrAuction {
  final Month boppMonth;

  MonthlyBoppFtrAuction({
    required Iso iso,
    required Month startMonth,
    required this.boppMonth,
  }) {
    start = startMonth.startDate;
    monthCount = 1;
    interval = Interval(start.start, startMonth.end);
    name = '${formatMYY(startMonth)}-bopp${formatMYY(boppMonth)}';
  }
}
