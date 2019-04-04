library time.bucket.hourly_shape;




class HourlyShape {

  Map<String,dynamic> _data;

  HourlyShape.fromMap(Map<String,dynamic> x) {
    if (x.length != 12) _isInvalid(x);

  }

  List<num> weights(int month, String bucketName) {
    return [0];
  }

  Map<String,dynamic> toMap() {

  }

  _isInvalid(Map<String,dynamic> x) {
    throw ArgumentError('Invalid shape map $x');
  }


}