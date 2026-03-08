/// Formats dates and times for display in the shell without external packages.
abstract final class DateTimeFormatter {
  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Formats a [DateTime] into a short human-readable string.
  static String short(DateTime? value) {
    if (value == null) {
      return 'TBD';
    }

    final String weekday = _weekdays[value.weekday - 1];
    final String month = _months[value.month - 1];
    final int hour = value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final String minute = value.minute.toString().padLeft(2, '0');
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';

    return '$weekday, $month ${value.day} · $hour:$minute $suffix';
  }
}
