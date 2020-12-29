part of elec.risk_system;

abstract class MarksCurve {
  Set<Bucket> buckets;
}

class MarksCurveEmpty extends MarksCurve {
  Map<String, dynamic> toJson() => <String, dynamic>{};
}
