double? itqanJourneyProgressRatio(
  Map<String, dynamic>? journey,
  Map<String, dynamic>? tasks,
) {
  final nestedJourney = _asMap(journey?['journey']);
  final journeyData = nestedJourney ?? journey;
  final percentage = _number(journeyData?['completion_percentage']);
  if (percentage != null) return (percentage / 100).clamp(0.0, 1.0);

  final stageRatio = _ratio(
    journeyData?['completed_stages'],
    journeyData?['total_stages'],
  );
  if (stageRatio != null) return stageRatio;

  final counts = _asMap(tasks?['counts']);
  return _ratio(counts?['completed'], counts?['total']);
}

double? _ratio(Object? completedValue, Object? totalValue) {
  final completed = _number(completedValue);
  final total = _number(totalValue);
  if (completed == null || total == null || completed < 0 || total <= 0) {
    return null;
  }
  return (completed / total).clamp(0.0, 1.0);
}

num? _number(Object? value) =>
    value is num ? value : num.tryParse(value?.toString() ?? '');

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;
