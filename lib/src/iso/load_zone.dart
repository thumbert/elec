library iso.load_zone;

class LoadZone {
  final String name;
  final int ptid;
  LoadZone(this.name, this.ptid);
  @override
  String toString() => name;
  @override
  bool operator ==(Object other) {
    if (other is! LoadZone) return false;
    LoadZone loadZone = other;
    return loadZone.ptid == ptid;
  }
  @override
  int get hashCode => ptid;
}

enum IesoLoadZone {
  ontario('Ontario'),  // the entire pool
  northwest('Northwest'),
  northeast('Northeast'),
  ottawa('Ottawa'),
  east('East'),
  toronto('Toronto'),
  essa('Essa'),
  bruce('Bruce'),
  southwest('Southwest'),
  niagara('Niagara'),
  west('West');

  const IesoLoadZone(this._value);
  final String _value;

  static IesoLoadZone parse(String value) {
    return switch (value) {
      'Ontario' => IesoLoadZone.ontario,
      'Northwest' => IesoLoadZone.northwest,
      'Northeast' => IesoLoadZone.northeast,
      'Ottawa' => IesoLoadZone.ottawa,
      'East' => IesoLoadZone.east,
      'Toronto' => IesoLoadZone.toronto,
      'Essa' => IesoLoadZone.essa,
      'Bruce' => IesoLoadZone.bruce,
      'Southwest' => IesoLoadZone.southwest,
      'Niagara' => IesoLoadZone.niagara,
      'West' => IesoLoadZone.west,
      _ => throw ArgumentError('Invalid value $value for IesoLoadZone'),
    };
  }

  @override
  String toString() => _value;
}