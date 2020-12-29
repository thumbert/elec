part of elec.risk_system;

abstract class MarksCurve {}

class MarksCurveEmpty extends MarksCurve {
  Map<String, dynamic> toJson() => <String, dynamic>{};
}
