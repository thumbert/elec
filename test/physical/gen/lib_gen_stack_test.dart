library test.physical.gen.lib_gen_stack_test;

import 'dart:io';

import 'package:date/date.dart';
import 'package:duckdb_dart/duckdb_dart.dart';
import 'package:elec/src/iso/iso.dart';
import 'package:elec/src/physical/gen/lib_gen_stack.dart';
import 'package:elec_server/utils.dart';
import 'package:test/test.dart';
import 'package:timezone/data/latest.dart';
import 'package:timezone/standalone.dart';

void tests() {
  group('ISONE energy offers', () {
    late Connection con;
    late Stack stack;
    setUp(() {
      con = Connection(
          '${Platform.environment['HOME']}/Downloads/Archive/IsoExpress/energy_offers.duckdb',
          Config(accessMode: AccessMode.readOnly));
      stack = getStack(
          con, Hour.beginning(TZDateTime(IsoNewEngland.location, 2023)));
    });
    tearDown(() => con.close());

    test('calculate clearing price', () {
      var cp = stack.clearingPrice(20000);
      expect(cp, 93.76000213623047);
    });

    test('remove units from stack', () {
      var newStack = stack.removeUnits({72020, 11009});
      expect(stack.maskedAssetId.contains(72020), true);
      expect(stack.maskedAssetId.contains(11009), true);
      expect(newStack.maskedAssetId.contains(72020), false);
      expect(newStack.maskedAssetId.contains(11009), false);
    });

    test('calculate effect of units out', () {
      final stack = getStack(
          con, Hour.beginning(TZDateTime(IsoNewEngland.location, 2023)));
      var loadLevels = List.generate(15, (i) => 1000 * i + 10000);
      var priceChanges =
          stack.priceImpactOfUnitsRemoved({72020, 11009}, loadLevels);
      print(priceChanges);
      // for a load of 24,000 MW, price change is
      expect(priceChanges.last, 74.61000061035156);
    });

    test('get stack for 2023-01-01 00:00:00', () {
      final stack = getStack(
          con, Hour.beginning(TZDateTime(IsoNewEngland.location, 2023)));
      final trace = stack.toTrace();

      // print(stack);
      final layout = {
        'height': 650,
        'width': 800,
        'title': {
          'text': 'Energy offer stack',
        },
        'xaxis': {
          'title': 'Quantity, MW',
          'range': [0, stack.cumQuantity.last + 100],
        },
        'yaxis': {
          'title': 'Price, \$/MWh',
        },
      };
      Plotly.now([trace], layout,
          file: File('${Platform.environment['HOME']}/Downloads/stack.html'));
    });
  });
}

void main() async {
  initializeTimeZones();
  tests();
}
