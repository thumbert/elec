class CallPut {
  final String _name;
  const CallPut._internal(this._name);

  factory CallPut.parse(String x) {
    var y = x.toLowerCase();
    if (y != 'put' && y != 'call') {
      throw ArgumentError('Can\'t parse $x for CallPut.');
    }
    return y == 'call' ? call : put;
  }

  static const call = CallPut._internal('Call');
  static const put = CallPut._internal('Put');

  @override
  String toString() => _name;
}
