class ParsedDate {
  final DateTime date;
  final String matchedText;

  const ParsedDate({
    required this.date,
    required this.matchedText,
  });
}

class DateParser {
  static final List<_DatePattern> _patterns = [
    // 31/12/2026, 31-12-2026, 31.12.2026
    _DatePattern(
      RegExp(r'\b(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{4})\b'),
      (m) => _build(day: m[1]!, month: m[2]!, year: m[3]!),
    ),
    // 31/12/26, 31-12-26, 31.12.26
    _DatePattern(
      RegExp(r'\b(\d{1,2})[\/.\-](\d{1,2})[\/.\-](\d{2})\b'),
      (m) => _build(day: m[1]!, month: m[2]!, year: _expandYear(m[3]!)),
    ),
    // 2026-12-31 / 2026/12/31
    _DatePattern(
      RegExp(r'\b(\d{4})[\/.\-](\d{1,2})[\/.\-](\d{1,2})\b'),
      (m) => _build(day: m[3]!, month: m[2]!, year: m[1]!),
    ),
    // 31122026
    _DatePattern(
      RegExp(r'\b(\d{2})(\d{2})(\d{4})\b'),
      (m) => _build(day: m[1]!, month: m[2]!, year: m[3]!),
    ),
    // 311226
    _DatePattern(
      RegExp(r'\b(\d{2})(\d{2})(\d{2})\b'),
      (m) => _build(day: m[1]!, month: m[2]!, year: _expandYear(m[3]!)),
    ),
    // 12/2026 or 12.26 (month/year) -> last day of month
    _DatePattern(
      RegExp(r'\b(\d{1,2})[\/.\-](\d{4})\b'),
      (m) => _buildMonthYear(month: m[1]!, year: m[2]!),
    ),
    _DatePattern(
      RegExp(r'\b(\d{1,2})[\/.\-](\d{2})\b'),
      (m) {
        final month = int.tryParse(m[1]!);
        // Avoid matching day/month leftovers; only accept plausible months
        if (month == null || month < 1 || month > 12) return null;
        return _buildMonthYear(month: m[1]!, year: _expandYear(m[2]!));
      },
    ),
  ];

  static List<ParsedDate> extractDates(String rawText) {
    final normalized = rawText
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1')
        .replaceAll('I', '1')
        .replaceAll(RegExp(r'\s+'), ' ');

    final found = <String, ParsedDate>{};

    for (final pattern in _patterns) {
      for (final match in pattern.regex.allMatches(normalized)) {
        final groups = List<String?>.generate(
          match.groupCount + 1,
          (i) => match.group(i),
        );
        final date = pattern.builder(groups);
        if (date == null) continue;
        if (!_isPlausible(date)) continue;

        final key = date.toIso8601String().substring(0, 10);
        found.putIfAbsent(
          key,
          () => ParsedDate(date: date, matchedText: match.group(0) ?? ''),
        );
      }
    }

    final dates = found.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return dates;
  }

  static DateTime? bestCandidate(String rawText) {
    final dates = extractDates(rawText);
    if (dates.isEmpty) return null;

    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    // Prefer the nearest future (or today) date — typical for DLC
    final futureOrToday = dates.where((d) => !d.date.isBefore(todayOnly));
    if (futureOrToday.isNotEmpty) {
      return futureOrToday.first.date;
    }

    // Otherwise the most recent past date (still useful if OCR catches an expired product)
    return dates.last.date;
  }

  static String _expandYear(String twoDigits) {
    final value = int.parse(twoDigits);
    final century = DateTime.now().year ~/ 100;
    return '${century * 100 + value}';
  }

  static DateTime? _build({
    required String day,
    required String month,
    required String year,
  }) {
    final d = int.tryParse(day);
    final m = int.tryParse(month);
    final y = int.tryParse(year);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    try {
      final date = DateTime(y, m, d);
      if (date.year != y || date.month != m || date.day != d) return null;
      return date;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _buildMonthYear({
    required String month,
    required String year,
  }) {
    final m = int.tryParse(month);
    final y = int.tryParse(year);
    if (m == null || y == null || m < 1 || m > 12) return null;
    final lastDay = DateTime(y, m + 1, 0).day;
    return DateTime(y, m, lastDay);
  }

  static bool _isPlausible(DateTime date) {
    final now = DateTime.now();
    // Ignore absurd OCR noise far in the past/future
    return date.year >= now.year - 2 && date.year <= now.year + 10;
  }
}

class _DatePattern {
  final RegExp regex;
  final DateTime? Function(List<String?> match) builder;

  const _DatePattern(this.regex, this.builder);
}
