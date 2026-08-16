String shortDate(DateTime? value) {
  if (value == null) return 'Unknown';
  final DateTime local = value.toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
