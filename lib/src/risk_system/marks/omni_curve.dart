library risk_system.marks.omni_curve;

import 'package:date/date.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/risk_system/marks/monthly_curve.dart';

/// An omnipotent curve providing a complete hourly covering of an interval.
/// No missing values allowed for any hour in the domain where the curve is
/// defined.
class OmniCurve {

  /// The domain of this OmniCurve.  No missing values allowed for any hour
  /// in this interval.
  Interval domain;

  /// Return the value of the curve for this hour, or [null] if the hour is not
  /// contained in the domain of the OmniCurve.
  num Function(Hour) _f;

  /// Construct an OmniCurve from a list of [MonthlyCurve]s.
  OmniCurve.fromMonthlyCurves(List<MonthlyCurve> curves) {
    domain = curves.first.domain;
    //var buckets = curves.map((curve) => curve.bucket).toList();
    _f = (Hour hour) {
      if (!domain.containsInterval(hour)) return null;
      for (var curve in curves) {
        if (curve.bucket.containsHour(hour)) {
          var month = Month.fromTZDateTime(hour.start);
          return curve.valueAt(month);
        }
      }
      throw ArgumentError('Incomplete set of curves!');
    };
  }

  /// Return the value of the schedule associated with this hour.
  num operator [](Hour hour) => _f(hour);

  /// Return the value of the schedule associated with this hour.
  num value(Hour hour) => _f(hour);
}