import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/circle_api_client.dart';
import '../domain/circle_models.dart';

final circleApiClientProvider = Provider<CircleApiClient>(
  (ref) => CircleApiClient.instance,
);

final currentCircleUserProvider = StateProvider<AppUser?>((ref) => null);

final myCirclesProvider = FutureProvider.autoDispose<List<Circle>>((ref) async {
  return ref.watch(circleApiClientProvider).getCircles();
});

final myCircleTasksProvider =
    FutureProvider.autoDispose<List<CircleTask>>((ref) async {
  return ref.watch(circleApiClientProvider).getMyTasks();
});
