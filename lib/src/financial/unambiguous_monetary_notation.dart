/// See https://docs.formance.com/stack/unambiguous-monetary-notation#specification
/// 
/// UMN	Human Readable	ISO-4217 code
// [USD/2 30]	$0.30	USD
// [JPY 100]	¥100	JPY
// [BTC/8 100000000]	1 BTC	BTC
// [GBP/2 100]	£1.00	GBP
// [EUR/2 100]	€1.00	EUR
// [INR/2 100]	₹1.00	INR
// [CNY/2 100]	¥1.00	CNY
// [CAD/2 100]	CA$1.00	CAD

// While USD/2 is a reasonable notation for most USD-handling use-cases, 
// nothing prevents you from using USD/4 or USD/6 if you need to represent 
// smaller amounts and subdivisions of USD in your system. The same applies to 
// other currencies, e.g. JPY/2 or JPY/4 for Japanese Yen and while such a coin 
// is not in circulation, it is still a valid notation when these amounts are 
// used in a context where they will end up being floored or ceiled to the 
// nearest whole unit later down the line.

