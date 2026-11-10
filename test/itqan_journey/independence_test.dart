import 'package:flutter_test/flutter_test.dart';
import 'package:itqan/features/itqan_journey/application/itqan_journey_provider.dart';
import 'package:itqan/features/itqan_journey/data/journey_content_repository.dart';

void main(){test('new journey content parser repository is feature-local',(){final repository=JourneyContentRepository();expect(repository,isA<JourneyContentRepository>());});test('new journey state starts without locally fabricated balances',(){const state=ItqanJourneyState();expect(state.profile,isNull);expect(state.tasks,isNull);expect(state.lastActivity,isNull);});}
