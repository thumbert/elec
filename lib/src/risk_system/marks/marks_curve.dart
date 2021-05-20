part of elec.risk_system;

abstract class MarksCurve {
  late Set<Bucket> buckets;
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId);
}

class MarksCurveEmpty extends MarksCurve {
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId) {
    throw UnimplementedError();
  }
}
