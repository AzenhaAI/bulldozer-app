import 'package:flutter_test/flutter_test.dart';
import 'package:bulldozer_app/api.dart';

CountryItem _it(int rank, int total, [int? ties]) => CountryItem.fromJson(
    {'slug': 's', 'rank': rank, 'total': total, if (ties != null) 'ties': ties, 'better': 'low'});

void main() {
  test('places from the bottom count ties in the country\'s favour', () {
    expect(_it(150, 179).fromBottom, 30); // 29 strictly lower
    expect(_it(105, 166, 62).fromBottom, 1); // FAO 2.5% floor: tied lowest
    expect(_it(109, 193, 85).fromBottom, 1); // Freedom House "Free": tied lowest code
    expect(_it(1, 214, 121).fromTop, 1);
  });
}
