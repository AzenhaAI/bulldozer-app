import 'package:bulldozer_app/search_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('token prefix and one-typo matching', () {
    expect(searchScore('adul mortality', 'Adult Mortality WHO'), greaterThan(0));
    expect(searchScore('adult mortalty', 'Adult Mortality WHO'), 1);
    expect(searchScore('gdp ppp', 'GDP per Capita (PPP) IMF'), 2);
    expect(searchScore('portgal', 'Portugal Europe'), 1);
    expect(searchScore('adult mortality', 'Adult Mortality'), 4);
    expect(searchScore('xyzzy', 'Adult Mortality'), 0);
    expect(searchScore('mortality zebra', 'Adult Mortality'), 0);
  });

  test('ranking puts exact phrase first', () {
    final r = searchRank('life exp', [
      'Healthy Life Expectancy',
      'Life Expectancy',
      'Wife experience',
    ], (s) => s);
    expect(r.first, 'Life Expectancy');
  });
}
