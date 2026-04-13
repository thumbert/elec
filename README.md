# elec

Various utilities for electricity markets. 

## Usage

### Buckets

Standard time buckets for various ISOs are implemented in the `time` library. 
They are static objects:

```dart
final buckets = [
  Bucket.b5x16,
  Bucket.b2x16H,
  Bucket.b7x8,
];
assert(Bucket.b7x8 == Bucket.parse('7x8'));
```

You can easily check if an hour belongs in this bucket or not:
```dart
Bucket.b5x16.containsHour(Hour.containing(TZDateTime(IsoNewEngland.location, 2026, 1, 1))) == false;
```

Or calculate hours in a given interval:
```dart
final term = Term.parse('Q2,2026', IsoNewEngland.location);
Bucket.2x16H.countHours(term.toInterval())
```



### Working with forward marks

A useful abstraction is provided by the `PriceCurve` class which allows you to specify prices based on several time buckets, for example the standart `5x16, 2x16H, 7x8` buckets.  Daily and monthly marks granularity is supported. 

```dart
// define a price curve using the buckets 5x16, 2x16H, 7x8
final pc = PriceCurve.fromIterable([...]);
// or, final pc = PriceCurve.fromBuckets({Bucket.5x16: ..., Bucket.2x16H: ..., Bucket.7x8: ...}); 

// to calculate the value for another bucket, say 7x24 for a given interval
final value = pc.value(interval, Bucket.atc);

// to calculate the entire timeseries for an aggregated bucket (Offpeak or ATC) do
final ts7x24 = pc.points(Bucket.atc);
```




A simple usage example:

    import 'package:elec/elec.dart';

    main() {
      var awesome = new Awesome();
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
