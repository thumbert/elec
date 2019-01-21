part of elec.risk_system;


mixin BaseTrade {
  Date tradeDate;
  Interval tradeTerm;
  BuySell buySell;

  Date get startDate => Date.fromTZDateTime(tradeTerm.start);
  Date get endDate => Date.fromTZDateTime(tradeTerm.end).subtract(1);
}


class Trade {
  Date tradeDate;
  Date startDate;
  Date endDate;
  BuySell buySell;

//  List<TradeLeg> legs;



}