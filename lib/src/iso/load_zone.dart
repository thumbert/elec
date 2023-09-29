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

