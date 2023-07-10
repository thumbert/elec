library financial.black_scholes.black_scholes;

import 'dart:math';
import 'package:dama/analysis/solver/bisection_solver.dart';
import 'package:date/date.dart';
import 'package:elec/risk_system.dart';
import 'package:dama/special/erf.dart';

class BlackScholes {
  // instrument info
  final CallPut type;
  final Date expirationDate;
  final num strike;

  // market info
  late Date _asOfDate;
  num riskFreeRate;
  num underlyingPrice;
  late num _volatility;
  late num _tExp;

  /// Implement the Black-Scholes model for European option on a stock.
  BlackScholes({
    required this.type,
    required this.strike,
    required this.expirationDate,
    required Date asOfDate,
    required this.underlyingPrice,
    required num volatility,
    required this.riskFreeRate,
  }) {
    this.volatility = volatility;
    this.asOfDate = asOfDate;
    _tExp = _timeToExpiration(asOfDate, expirationDate);
  }

  Date get asOfDate => _asOfDate;
  set asOfDate(Date value) {
    _asOfDate = value;
    _tExp = _timeToExpiration(asOfDate, expirationDate);
  }

  num get timeToExpiration => _tExp;

  num get volatility => _volatility;
  set volatility(num value) {
    if (value <= 0) {
      throw ArgumentError('Volatility parameter needs to be positive');
    }
    _volatility = value;
  }

  /// Calculate the value of this option.  Values for the [asOfDate], [underlyingPrice],
  /// [_volatility], and [riskFreeRate] can be set directly in the object.
  ///
  num value() {
    num res;
    switch (type) {
      case CallPut.call:
        if (_tExp == 0) {
          res = max(underlyingPrice - strike, 0);
        } else {
          res = underlyingPrice *
                  _nd1(_tExp, _volatility, underlyingPrice, strike,
                      riskFreeRate) -
              strike *
                  _nd2(_tExp, _volatility, underlyingPrice, strike,
                      riskFreeRate) *
                  exp(-riskFreeRate * _tExp);
        }
        break;
      case CallPut.put:
        if (_tExp == 0) {
          res = max(strike - underlyingPrice, 0);
        } else {
          res = strike *
                  (1 -
                      _nd2(_tExp, _volatility, underlyingPrice, strike,
                          riskFreeRate)) *
                  exp(-riskFreeRate * _tExp) -
              underlyingPrice *
                  (1 -
                      _nd1(_tExp, _volatility, underlyingPrice, strike,
                          riskFreeRate));
        }
        break;
      default: throw StateError('Option type $type not supported');
    }
    return res;
  }

  /// Calculate the delta of the option (sensitivity with respect to underlying
  /// price.)
  ///
  num delta() {
    num res;
    switch (type) {
      case CallPut.call:
        res = _nd1(_tExp, _volatility, underlyingPrice, strike, riskFreeRate);
        break;
      case CallPut.put:
        res =
            _nd1(_tExp, _volatility, underlyingPrice, strike, riskFreeRate) - 1;
        break;
      default: throw StateError('Option type $type not supported');
    }
    return res;
  }

  /// Calculate the gamma of the option (second derivative with respect to
  /// the underlying price.)
  double gamma() {
    var aux = _volatility * underlyingPrice * sqrt(_tExp);
    return _dNd1(_tExp, _volatility, underlyingPrice, strike, riskFreeRate) /
        aux;
  }

  /// Calculate the theta of the option (sensitivity with respect to time.)
  /// for 1 day change in time to expiration
  double theta() {
    late double res;
    var t1 = -_volatility *
        underlyingPrice *
        _dNd1(_tExp, _volatility, underlyingPrice, strike, riskFreeRate) /
        (2 * sqrt(_tExp));
    switch (type) {
      case CallPut.call:
        res = t1 -
            riskFreeRate *
                strike *
                exp(-riskFreeRate * _tExp) *
                _nd2(_tExp, _volatility, underlyingPrice, strike, riskFreeRate);
        break;
      case CallPut.put:
        num t2 = riskFreeRate *
            strike *
            exp(-riskFreeRate * _tExp) *
            Phi(_d2(_tExp, _volatility, underlyingPrice, strike, riskFreeRate));
        res = t1 + t2;
        break;
    }
    return res / 365.25;
  }

  /// Calculate the vega of the option (sensitivity with respect to volatility.)
  /// for 1% move in the volatility
  double vega() {
    return 0.01 *
        underlyingPrice *
        sqrt(_tExp) *
        _dNd1(_tExp, _volatility, underlyingPrice, strike, riskFreeRate);
  }

  /// Calculate the sensitivity of the option with respect to interest rate
  /// for 1 basis point move in the risk free rate.
  double rho() {
    late double res;
    switch (type) {
      case CallPut.call:
        res = 0.0001 *
            strike *
            _tExp *
            exp(-riskFreeRate * _tExp) *
            _nd2(_tExp, _volatility, underlyingPrice, strike, riskFreeRate);
        break;
      case CallPut.put:
        res = -0.0001 *
            strike *
            _tExp *
            exp(-riskFreeRate * _tExp) *
            Phi(-_d2(
                _tExp, _volatility, underlyingPrice, strike, riskFreeRate));
        break;
    }
    return res;
  }

  /// Calculate the implied volatility of this option given an option price
  num impliedVolatility(num price) {
    f(num v) {
      var opt = BlackScholes(
          type: type, strike: strike, expirationDate: expirationDate,
          asOfDate: _asOfDate, volatility: v, riskFreeRate: riskFreeRate, underlyingPrice: underlyingPrice);
      return opt.value() - price;
    }
    return bisectionSolver(f, 0.00001, 1000);
  }

  BlackScholes copyWith(
      {CallPut? type,
      num? strike,
      Date? expirationDate,
      Date? asOfDate,
      num? underlyingPrice,
      num? volatility,
      num? riskFreeRate}) {
    return BlackScholes(
      type: type ?? this.type,
      strike: strike ?? this.strike,
      expirationDate: expirationDate ?? this.expirationDate,
      asOfDate: asOfDate ?? this.asOfDate,
      underlyingPrice: underlyingPrice ?? this.underlyingPrice,
      volatility: volatility ?? this.volatility,
      riskFreeRate: riskFreeRate ?? this.riskFreeRate,
    );
  }
}

double _d1(num _tExp, num volatility, num underlyingPrice, num strike,
    num interestRate) {
  double d1;
  if (_tExp == 0.0 || volatility == 0) {
    d1 = double.infinity;
  } else {
    d1 = (log(underlyingPrice / strike) +
            (interestRate + 0.5 * volatility * volatility) * _tExp) /
        (volatility * sqrt(_tExp));
  }
  return d1;
}

double _nd1(num _tExp, num volatility, num underlyingPrice, num strike,
        num interestRate) =>
    Phi(_d1(_tExp, volatility, underlyingPrice, strike, interestRate));

double _d2(num _tExp, num volatility, num underlyingPrice, num strike,
    num interestRate) {
  double d2;
  if (_tExp == 0 || volatility == 0) {
    d2 = double.infinity;
  } else {
    d2 = (log(underlyingPrice / strike) +
            (interestRate - 0.5 * volatility * volatility) * _tExp) /
        (volatility * sqrt(_tExp));
  }
  return d2;
}

double _nd2(num _tExp, num volatility, num underlyingPrice, num strike,
        num interestRate) =>
    Phi(_d2(_tExp, volatility, underlyingPrice, strike, interestRate));

double _dNd1(num _tExp, num volatility, num underlyingPrice, num strike,
    num interestRate) {
  num d1 = _d1(_tExp, volatility, underlyingPrice, strike, interestRate);
  return exp(-0.5 * d1 * d1) / sqrt(2 * pi);
}

num _timeToExpiration(Date asOfDate, Date expirationDate) {
  return max(0, expirationDate.end.difference(asOfDate.end).inDays / 365.25);
}
