library time.bucket.bucket_composition_rules;

import 'package:elec/elec.dart';

var bucketCompositionRules = <Set<Bucket>, Bucket>{
  {
    IsoNewEngland.bucket2x16H,
    IsoNewEngland.bucket7x8,
    IsoNewEngland.bucket5x16
  }: IsoNewEngland.bucket7x24,


  {IsoNewEngland.bucket2x16H, IsoNewEngland.bucket7x8}:
      IsoNewEngland.bucketOffpeak,


  {IsoNewEngland.bucketOffpeak, IsoNewEngland.bucketPeak}:
      IsoNewEngland.bucket7x24,
};
