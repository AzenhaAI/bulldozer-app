import 'package:bulldozer_app/api.dart';
import 'package:bulldozer_app/ask_page.dart';
import 'package:bulldozer_app/csv_export.dart';
import 'package:flutter_test/flutter_test.dart';

Dataset _ds(List<(String, double)> rows) => Dataset.fromJson({
      'slug': 'owid-electricity',
      'title': 'Access to Electricity',
      'unit': '%',
      'source': 'Our World in Data',
      'license': 'CC BY 4.0',
      'url': 'https://ourworldindata.org/energy-access',
      'data': [
        for (final (iso, v) in rows)
          {'entity': iso, 'iso': iso, 'period': '2024', 'value': v}
      ],
    });

void main() {
  test('a value shared at the top is a tie at the maximum', () {
    final ds = _ds([('PRT', 100), ('ESP', 100), ('FRA', 100), ('NGA', 60)]);
    final t = standoutTie(ds, '2024', 100, 'high', 'PRT')!;
    expect(t.others, 2);
    expect(t.extreme, isTrue);
    final u = standoutTie(ds, '2024', 60, 'low', 'NGA')!;
    expect(u.others, 0);
  });

  test('CSV header names source, licence, unit and the dataset page', () {
    final h = CsvExport.csvHeader('owid-electricity', 'Access to Electricity',
        _ds([('PRT', 100)]));
    final lines = h.trim().split('\n');
    expect(lines.every((l) => l.startsWith('# ')), isTrue);
    expect(h, contains('# Source: Our World in Data'));
    expect(h, contains('# Licence: CC BY 4.0'));
    expect(h, contains('# Unit: %'));
    expect(h, contains('/dataset/owid-electricity/'));
  });
}
