import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/circle_api_service.dart';
import '../domain/circle_models.dart';

final circleApiServiceProvider =
    Provider<CircleApiService>((ref) => CircleApiService());

final myCirclesProvider = FutureProvider<List<Circle>>((ref) async {
  final items = await ref.read(circleApiServiceProvider).getMyCircles();
  return items.map(Circle.fromJson).toList(growable: false);
});

final circleTypesProvider = FutureProvider<List<CircleType>>((ref) async {
  final items = await ref.read(circleApiServiceProvider).getTypes();
  return items.map(CircleType.fromJson).toList(growable: false);
});
