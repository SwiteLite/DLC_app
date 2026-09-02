import 'package:flutter_test/flutter_test.dart';

import 'package:food_connect/date_parser.dart';

void main() {
  group('DateParser', () {
    test('extrait une date jj/mm/aaaa', () {
      final dates = DateParser.extractDates('DLC 31/12/2026');
      expect(dates, isNotEmpty);
      expect(dates.first.date, DateTime(2026, 12, 31));
    });

    test('extrait une date yyyy-mm-dd', () {
      final dates = DateParser.extractDates('2026-05-15');
      expect(dates, isNotEmpty);
      expect(dates.first.date, DateTime(2026, 5, 15));
    });

    test('retourne une liste vide sans date', () {
      expect(DateParser.extractDates('sans date ici'), isEmpty);
    });
  });
}
