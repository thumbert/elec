library risk_system.marks.electricity_marks;

import 'package:elec/src/iso/iso.dart';
import 'package:elec/elec.dart';
import 'package:elec/src/time/bucket/bucket.dart';


class BucketPrice {
  Bucket bucket;
  num price;
  BucketPrice(this.bucket, this.price);
}



class ElectricityMarks {
  num price5x16;
  num price2x16H;
  num price7x8;

  static final _bucketNames = {'5x16', '2x16H', '7x8'};

  ElectricityMarks(this.price5x16, this.price2x16H, this.price7x8);

  num value(Bucket bucket) {
    if (bucket == IsoNewEngland.bucket5x16) return price5x16;
    else if (bucket == IsoNewEngland.bucket2x16H) return price2x16H;
    else if (bucket == IsoNewEngland.bucket7x8) return price7x8;
    else
      throw ArgumentError('Invalid bucket $bucket');
  }

  ElectricityMarks.fromMap(Map<String,num> x) {
    if (!x.keys.toSet().containsAll(_bucketNames))
      throw ArgumentError('Invalid map input $x');
    price5x16 = x['5x16'];
    price2x16H = x['2x16H'];
    price7x8 = x['7x8'];
  }

  Map<String,num> toMap() {
    return {
      '5x16': price5x16,
      '2x16H': price2x16H,
      '7x8': price7x8,
    };
  }

  String toString() => toMap().toString();
}

