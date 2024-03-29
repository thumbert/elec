
part of '../../risk_system.dart';

class Quantity {
  num value;
  Unit unit;

  Quantity(this.value, this.unit);

  @override
  String toString() => '$value ${unit.name}';

  @override
  bool operator ==(Object other) {
    if (other is! Quantity) return false;
    Quantity q = other;
    return q.value == value && q.unit == unit;
  }

  @override
  int get hashCode => hash2(value, unit);

  Map<String,dynamic> toMap() => <String,dynamic>{
    'value': value,
    'unit': unit.name,
  };


}