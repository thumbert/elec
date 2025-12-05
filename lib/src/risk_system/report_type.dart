enum ReportType {
  finalized,
  preliminary;

  ReportType parse(String x) {
    return switch (x.toLowerCase()) {
      'final' || 'finalized' => ReportType.finalized,
      'prelim' || 'preliminary' => ReportType.preliminary,
      _ => throw ArgumentError('Can\'t parse $x as a ReportType')
    };
  }

  @override
  String toString() {
    return switch (this) {
      ReportType.finalized => 'final',
      ReportType.preliminary => 'prelim',
    };
  }
}
