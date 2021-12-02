part of elec.risk_system;

class Mw {
  num value;
  Mw(this.value);
  @override
  String toString() => '$value MW';
  @override
  bool operator ==(dynamic other) {
    if (other is! Mw) return false;
    Mw x = other;
    return x.value == value;
  }
  @override
  int get hashCode => value as int;
}

class Mwh {
  num value;
  Mwh(this.value);
  @override
  String toString() => '$value MWh';
  @override
  bool operator ==(dynamic other) {
    if (other is! Mwh) return false;
    Mwh x = other;
    return x.value == value;
  }
  @override
  int get hashCode => value as int;
}