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

final maine = LoadZone('MAINE', 4001);
final newHampshire = LoadZone('NH', 4002);
final vermont = LoadZone('VT', 4003);
final connecticut = LoadZone('CT', 4004);
final rhodeIsland = LoadZone('RI', 4005);
final sema = LoadZone('SEMA', 4006);
final wcma = LoadZone('WCMA', 4007);
final nema = LoadZone('NEMA', 4008);
