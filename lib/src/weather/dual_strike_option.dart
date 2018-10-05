library weather.dual_strike_option;


class DualStrikeOption {
  Function unitPayoff;
  num quantity;
  num maxPayout;

  DualStrikeOption(this.unitPayoff,
      {this.quantity: 1, this.maxPayout: double.infinity}) {}

  /// Calculate the daily payout given a [temperature] and [price]
  num value(num temperature, num price) {
    num res = quantity * unitPayoff(temperature, price);
    return res.clamp(0, maxPayout);
  }
}

Function cold1Payoff(num temperatureStrike, num priceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature <= temperatureStrike && price >= priceStrike)
      payoff = (price - priceStrike);
    return payoff;
  };
}

Function warm1Payoff(num temperatureStrike, num priceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature >= temperatureStrike && price <= priceStrike)
      payoff = priceStrike - price;
    return payoff;
  };
}

/// For below temperatures and above prices payoff set as product of deviations.
Function cold2Payoff(num temperatureStrike, num priceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature <= temperatureStrike && price >= priceStrike)
      payoff = (price - priceStrike) * (temperatureStrike - temperature);
    return payoff;
  };
}

/// For above temperatures and below prices payoff set as product of deviations.
Function warm2Payoff(num temperatureStrike, num priceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature >= temperatureStrike && price <= priceStrike)
      payoff = (priceStrike - price) * (temperature - temperatureStrike);
    return payoff;
  };
}

/// A dual strike option payoff that pays when
/// (T < T_min & P > P_max) or
/// (T > T_max & P < P_min)
/// Payoff is the price deviation from strike.
Function minMaxTempPrice1Payoff(num minTemperatureStrike, maxTemperatureStrike,
    num minPriceStrike, num maxPriceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature <= minTemperatureStrike && price >= maxPriceStrike)
      payoff = (price - maxPriceStrike);
    if (temperature >= maxTemperatureStrike && price <= minPriceStrike)
      payoff = (minPriceStrike - price);
    return payoff;
  };
}


/// A dual strike option payoff that pays when
/// (T < T_min & P > P_max) or
/// (T > T_max & P < P_min)
/// Payoff is the product of price and temperature deviations from strike.  
Function minMaxTempPrice2Payoff(num minTemperatureStrike, maxTemperatureStrike,
    num minPriceStrike, num maxPriceStrike) {
  return (num temperature, num price) {
    num payoff = 0;
    if (temperature <= minTemperatureStrike && price >= maxPriceStrike)
      payoff = (price - maxPriceStrike) * (minTemperatureStrike - temperature);
    if (temperature >= maxTemperatureStrike && price <= minPriceStrike)
      payoff = (minPriceStrike - price) * (temperature - maxTemperatureStrike);
    return payoff;
  };
}
