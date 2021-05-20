part of elec.risk_system;

class Mw {
  num value;
  Mw(this.value);
  String toString() => '$value MW';
  bool operator ==(dynamic other) {
    if (other is! Mw) return false;
    Mw x = other;
    return x.value == value;
  }
  int get hashCode => value as int;
}

class Mwh {
  num value;
  Mwh(this.value);
  String toString() => '$value MWh';
  bool operator ==(dynamic other) {
    if (other is! Mwh) return false;
    Mwh x = other;
    return x.value == value;
  }
  int get hashCode => value as int;
}