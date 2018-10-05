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

