import '../../domain/models/gamification_models.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../api/gamification_api.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  GamificationRepositoryImpl(this.api); final GamificationApi api;
  @override Future<GamificationProfile> getProfile() async => GamificationProfile.fromJson(Map<String,dynamic>.from((await api.get('gamification/profile'))['data'] as Map));
  @override Future<Journey> getJourney() async => Journey.fromJson(Map<String,dynamic>.from((await api.get('gamification/journey'))['data'] as Map));
  @override Future<GamificationTaskList> getTasks() async => GamificationTaskList.fromJson(Map<String,dynamic>.from((await api.get('gamification/tasks'))['data'] as Map));
  @override Future<StreakSummary> getStreak() async => StreakSummary.fromJson(Map<String,dynamic>.from((await api.get('gamification/streak'))['data'] as Map));
  @override Future<AchievementList> getAchievements() async => AchievementList.fromJson(Map<String,dynamic>.from((await api.get('gamification/achievements'))['data'] as Map));
  @override Future<Leaderboard> getLeaderboard({int limit=10}) async {if(limit<1||limit>50) throw ArgumentError.value(limit,'limit','Must be between 1 and 50');return Leaderboard.fromJson(Map<String,dynamic>.from((await api.get('gamification/leaderboard?limit=$limit'))['data'] as Map));}
  @override Future<ActivityResult> recordActivity(ActivityType type,String idempotencyKey,{Map<String,dynamic>? metadata}) async {final body=<String,dynamic>{'activity_type':type.apiValue,'idempotency_key':idempotencyKey};if(metadata!=null)body['metadata']=metadata;final response=await api.post('gamification/activities',body);return ActivityResult.fromJson(response);}
}
