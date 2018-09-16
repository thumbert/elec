library iso.load_zone;

class LoadZone {
  final String name;
  final int ptid;
  LoadZone(this.name, this.ptid);
  String toString() => name;
  bool operator ==(Object other) {
    if (other is! LoadZone) return false;
    LoadZone loadZone = other;
    return loadZone.ptid == ptid;
  }
  int get hashCode => ptid;
}

final maine = new LoadZone('MAINE', 4001);
final newHampshire = new LoadZone('NH', 4002);
final vermont = new LoadZone('VT', 4003);
final connecticut = new LoadZone('CT', 4004);
final rhodeIsland = new LoadZone('RI', 4005);
final sema = new LoadZone('SEMA', 4006);
final wcma = new LoadZone('WCMA', 4007);
final nema = new LoadZone('NEMA', 4008);
