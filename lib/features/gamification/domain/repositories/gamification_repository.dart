import '../models/gamification_models.dart';

abstract interface class GamificationRepository {
  Future<GamificationProfile> getProfile();
  Future<Journey> getJourney();
  Future<GamificationTaskList> getTasks();
  Future<StreakSummary> getStreak();
  Future<AchievementList> getAchievements();
  Future<Leaderboard> getLeaderboard({int limit = 10});
  Future<ActivityResult> recordActivity(ActivityType type, String idempotencyKey, {Map<String, dynamic>? metadata});
}
