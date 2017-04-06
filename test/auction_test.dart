library auction_test;

import 'package:date/date.dart';
import 'package:elec/elec.dart';


testAuction() {
  Auction auction = new Auction(new Nepool(), new Date(2015,1,1));
  print(auction.name);
//  print(auction.firstHour());


}


main() {
  testAuction();
}