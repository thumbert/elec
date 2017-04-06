library ftr.auction;

import 'package:timezone/timezone.dart';
import 'package:date/date.dart';
import 'package:elec/elec.dart';

class Auction {
  String _name;
  Date start;
  /// number of months for this auction
  int noMonths;
  int round;
  Iso iso;
  int _noHours;



  Auction(this.iso, this.start, {this.noMonths: 1, this.round}) {
//    if (round != null && round < 1)
//      throw 'Invalid auction round: $round';
    if (noMonths < 1)
      throw 'Auction has $noMonths months?!';

  }

  /// Construct an Auction from a name.
  Auction.fromName(String name) {
    /// TODO: do it
  }

  String _makeName() {
    StringBuffer res = new StringBuffer();
    res.write(new Month(start.year, start.month).toString());
    if (noMonths > 1)
      res.write('-${noMonths}M');
    if (round != null)
      res.write('-R$round');

    return res.toString();
  }

  String get name {
    if (_name == null) _name = _makeName();
    return _name;
  }

  /// Return the first hour of the Auction
//  Hour firstHour() => new Hour.beginning(new TZDateTime(Iso.location, start.year, start.month));
//
//  /// Return the last hour of the Auction
//  Hour lastHour() {
//    var aux = new Month(start.year, start.month).add(noMonths);
//    TZDateTime end = new TZDateTime(Iso.location, aux.year, aux.month);
//    return new Hour.ending(end);
//  }

  /// Calculate the number of hours in this auction
//  int get noHours {
//    if (_noHours == null)
//      _noHours = new TimeIterable(firstHour(), lastHour()).length;
//    return _noHours;
//  }

}