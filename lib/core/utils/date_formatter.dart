abstract final class DateFormatter {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// "Just now", "5m ago", "3h ago", "2d ago", or a full date after a week.
  static String relative(DateTime? date, {DateTime? now}) {
    if (date == null) return '';
    final current = now ?? DateTime.now();
    final diff = current.difference(date);

    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return full(date);
  }

  /// e.g. "13 Oct 2026".
  static String full(DateTime date) {
    final local = date.toLocal();
    return '${local.day} ${_months[local.month - 1]} ${local.year}';
  }

  /// e.g. "13 Oct 2026, 09:05".
  static String fullWithTime(DateTime date) {
    final local = date.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${full(local)}, $hh:$mm';
  }
}
