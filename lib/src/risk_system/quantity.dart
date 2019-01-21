
part of elec.risk_system;

class Quantity {
  num value;
  Unit unit;

  Quantity(this.value, this.unit);

  String toString() => '$value ${unit.name}';

  bool operator ==(dynamic other) {
    if (other is! Quantity) return false;
    Quantity q = other;
    return q.value == value && q.unit == unit;
  }

  int get hashCode => hash2(value, unit);

  Map<String,dynamic> toMap() => <String,dynamic>{
    'value': value,
    'unit': unit.name,
  };


}