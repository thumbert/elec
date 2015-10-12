library analysis.ftr.binding_constraints_effect;

/// Investigate the effects of binding constraints on a given path
/// Rank constraints on their influence on the path.
///

import 'dart:async';
import 'package:elec/elec.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone/standalone.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/ftr/path.dart';

calculateBindingConstraintsEffect() async {
  TZDateTime start = new TZDateTime(Nepool.location, 2015, 1, 1);
  TZDateTime end = new TZDateTime(Nepool.location, 2015, 5, 1);

  Path path = nepoolPath(555, 4002, Nepool.bucket5x16);

  List<Map> sp = await path.getSettlePrice(start, end);


}

main() async {
  config = new TestConfig();
  await Future
      .wait([config.nepool_dam_lmp_hourly.db.open(), initializeTimeZone()]);

  await calculateBindingConstraintsEffect();

  await config.nepool_dam_lmp_hourly.db.close();
}
