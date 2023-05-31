part of elec.risk_system;

mixin MarksCurve {
  late Set<Bucket> buckets;
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId);
}

class MarksCurveEmpty extends Object with MarksCurve {
  Map<String, dynamic> toJson() => <String, dynamic>{};

  @override
  Map<String, dynamic> toMongoDocument(Date fromDate, String curveId) {
    throw UnimplementedError();
  }
}
