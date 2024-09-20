# Changelog

## TODO
- 

## Release 2024-09-20
- More battery work, incorporate RT market

## Release 2024-09-18
- Battery work

## Release 2024-08-16
- Add function to interpolate a daily gas price series to an hourly series.

## Release 2024-08-02
- Bump dependencies

## Release 2024-07-05
- Move DayFilter class to time/day_filter.dart

## Release 2024-06-14
- Add lib_gen_stack.dart

## Release 2024-03-18
- Add BidAsk enum in risk_system.

## Release 2024-03-15
- Fix name of the 7xHE10-17, 7xHE18-22 buckets

## Release 2024-03-13
- Rename lastBusinessDayPrior() to lastBusinessDayBefore()
- Added solar buckets 5xHE10-17, 5xHE18-22, 7xHE10-17, 7xHE18-22, 
  to match the Nodal Solar Peak power contracts

## Release 2024-03-05
- Add Cal 1x option expiration date, in lastTradingDayForCalendar1xOptions()
- Refactor lastBusinessDayPrior() to take a date not a month argument.  

## Release 2024-03-04
- Add an IceCalendar for US energy.
- Add lastTradingDayForMonthlyElecOptions().  Long overdue, tested until Dec29.  

## Release 2024-01-06
- Clean up some more stuff in the calendar and holidays.  Use more static variables. 

## Release 2023-11-12
- Bump up dependencies

## Release 2023-10-31
- Add ISONE zonePtidToName constant map

## Release 2023-10-02
- Move IESO to UTC-0500 as America/Cancun was respecting DST in 2003, etc.

## Release 2023-09-29
- Move IESO to America/Cancun timezone.  Oof.
- Add IESO load zones

## Release 2023-09-27
- Expose a finance library

## Release 2023-07-17
- Export more files
- Remove the ISONE load zones from iso/load_zone.dart

## Release 2023-07-10
- Implement calendar methods firstBusinessDayFrom and lastBusinessDayBefore.
- Clean up more lints.  Less than 100 left!

## Release 2023-07-08
- Minor lint cleanups.  Still so many more to go!

## 2.1.0, release 2023-07-07
- Made NercCalendar isHoliday about 30% faster.  Removed the use of a cache (no speed 
  improvement).
- Using calendar.isHoliday3 in bucket definitions made bucket speedTest 50% faster, 
  went from 125ms to 65ms.

## Release 2023-05-31
- Bump lower version of sdk to 3.0.2
- Bump up packages

## Release 2023-05-29
- Bump sdk upper limit to 4.0.0

## Release 2023-03-29
- Remove iso argument from DaLmp client constructor

## Release 2023-03-08
- Add more buckets

## Release 2023-03-04
- Export functionality in the `time.dart` library
- Add a static Holiday parse() method to help with deserialization.  Add static holidays.

## Release 2023-01-12
- Really minor cleanups

## Release 2022-11-11
- Fixed a bug in ElectionDay calendar, was incorrectly calculating a date on 1-Nov 
which is not allowed
- Set up the Ercot ISO.  Added Ercot specific buckets.  

## Release 2022-10-31
- Add a name to the holiday type enum
- Bump SDK requirement to 2.17

## 2.0.1, released 2021-11-27
- Performance improvements when calculating if a date is a holiday.  This had
  cascading beneficial effects in a lot of bucket operations. 
- Performance improvements for PriceCurve.  When calculating the value for a 
  given term and bucket no longer force the calculation to hourly curve. 
  Do that as a last resort only because it's so expensive.  Implement special 
  treatment for cases when buckets are already in the PriceCurve, etc.
  These two changes have lead to a 10x speedup in some tests. 

## 2.0.0, released 2021-05-20
- Move to null safety (first pass).

## 1.1.0, released 2021-05-16
- Last release before null safety

## 1.0.0, released 2020-07-16
- Breaking change.  Remove location from Bucket definition. 

## 0.5.0, released 2020-07-05
- Snapshot of work

## 0.0.1, released 2015-09-27
- Initial version, created by Stagehand
