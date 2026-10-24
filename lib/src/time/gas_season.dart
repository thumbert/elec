/// Returns the gas season string for the given month.
/// Example: Nov26-Mar27, Apr27-Oct27, etc.
/// 
/// 
String gasSeason(int year, int month) {
  var y = year - 2000;
  if (month >= 11) {
    return 'Nov$y-Mar${y + 1}';
  } else if (month >= 4) {
    return 'Apr$y-Oct$y';
  } else {
    return 'Nov${y - 1}-Mar$y';
  }
}

