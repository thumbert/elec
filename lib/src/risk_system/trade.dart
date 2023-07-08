part of elec.risk_system;


mixin BaseTrade {
  Date? tradeDate;
  Interval? tradeTerm;
  late BuySell buySell;

  Date get startDate => Date.containing(tradeTerm!.start);
  Date get endDate => Date.containing(tradeTerm!.end).subtract(1);
}


class Trade {
  Date? tradeDate;
  Date? startDate;
  Date? endDate;
  BuySell? buySell;

//  List<TradeLeg> legs;



}