enum ActivityType {
  quran('quran.reading'),
  adhkar('adhkar'),
  dua('dua'),
  share('share');

  const ActivityType(this.apiValue);
  final String apiValue;
}

class LevelInfo {
  const LevelInfo({required this.number, required this.title, this.currentThreshold = 0, this.nextThreshold = 0, this.progressPercentage = 0, this.xpToNextLevel = 0, this.isMaxLevel = false});
  final int number;
  final String title;
  final int currentThreshold;
  final int nextThreshold;
  final double progressPercentage;
  final int xpToNextLevel;
  final bool isMaxLevel;
  factory LevelInfo.fromJson(Map<String, dynamic> j) => LevelInfo(number: _int(j['number']), title: '${j['title'] ?? ''}', currentThreshold: _int(j['current_threshold']), nextThreshold: _int(j['next_threshold']), progressPercentage: _num(j['progress_percentage']), xpToNextLevel: _int(j['xp_to_next_level']), isMaxLevel: j['is_max_level'] == true);
}

class GamificationProfile {
  const GamificationProfile({required this.name, this.userId, this.phone, this.memberSince, this.totalXp = 0, this.totalCoins = 0, this.level, this.achievementsEarned = 0, this.achievementsTotal = 0, this.tasksCompleted = 0, this.tasksTotal = 0, this.currentStreak = 0, this.longestStreak = 0, this.activeToday = false, this.pillars = const {}});
  final String name;
  final int? userId;
  final String? phone;
  final String? memberSince;
  final int totalXp;
  final int totalCoins;
  final LevelInfo? level;
  final int achievementsEarned;
  final int achievementsTotal;
  final int tasksCompleted;
  final int tasksTotal;
  final int currentStreak;
  final int longestStreak;
  final bool activeToday;
  final Map<String, dynamic> pillars;
  factory GamificationProfile.fromJson(Map<String, dynamic> j) {
    final u = _map(j['user']); final s = _map(j['stats']); final lvl = _map(s['level']);
    final a = _map(s['achievements']); final t = _map(s['tasks']); final st = _map(s['streak']);
    return GamificationProfile(name: '${u['name'] ?? ''}', userId: _nullableInt(u['id']), phone: u['phone']?.toString(), memberSince: u['member_since']?.toString(), totalXp: _int(s['total_xp']), totalCoins: _int(s['total_coins']), level: lvl.isEmpty ? null : LevelInfo.fromJson(lvl), achievementsEarned: _int(a['earned']), achievementsTotal: _int(a['total']), tasksCompleted: _int(t['completed_total']), tasksTotal: _int(t['total_available']), currentStreak: _int(st['current']), longestStreak: _int(st['longest']), activeToday: st['active_today'] == true, pillars: _map(s['pillars']));
  }
}

class GamificationTask {
  const GamificationTask({required this.id, required this.key, required this.title, required this.description, required this.pillar, required this.cadence, required this.target, required this.progress, required this.status, required this.completed, required this.xpReward, required this.coinReward, required this.periodKey});
  final dynamic id; final String key, title, description, pillar, cadence, status, periodKey;
  final int target, progress, xpReward, coinReward; final bool completed;
  factory GamificationTask.fromJson(Map<String, dynamic> j) => GamificationTask(id: j['id'], key: '${j['task_key'] ?? ''}', title: '${j['title'] ?? ''}', description: '${j['description'] ?? ''}', pillar: '${j['pillar'] ?? ''}', cadence: '${j['cadence'] ?? ''}', target: _int(j['target']), progress: _int(j['progress']), status: '${j['status'] ?? ''}', completed: j['completed'] == true, xpReward: _int(j['xp_reward']), coinReward: _int(j['coin_reward']), periodKey: '${j['period_key'] ?? ''}');
}

class GamificationTaskList {
  const GamificationTaskList(this.tasks, this.total, this.completed);
  final List<GamificationTask> tasks; final int total, completed;
  factory GamificationTaskList.fromJson(Map<String, dynamic> j) => GamificationTaskList(((j['tasks'] as List?) ?? const []).map((e) => GamificationTask.fromJson(_map(e))).toList(), _int(_map(j['counts'])['total']), _int(_map(j['counts'])['completed']));
}

class Achievement {
  const Achievement({required this.id, required this.key, required this.title, required this.description, required this.pillar, required this.rarity, required this.icon, required this.isEarned, this.earnedAt});
  final dynamic id; final String key, title, description, pillar, rarity, icon; final bool isEarned; final String? earnedAt;
  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(id: j['id'], key: '${j['key'] ?? ''}', title: '${j['title'] ?? ''}', description: '${j['description'] ?? ''}', pillar: '${j['pillar'] ?? ''}', rarity: '${j['rarity'] ?? ''}', icon: '${j['icon'] ?? ''}', isEarned: j['is_earned'] == true, earnedAt: j['earned_at']?.toString());
}
class AchievementList { const AchievementList(this.total, this.earned, this.items); final int total, earned; final List<Achievement> items; factory AchievementList.fromJson(Map<String,dynamic> j) => AchievementList(_int(j['total']), _int(j['earned']), ((j['achievements'] as List?) ?? const []).map((e)=>Achievement.fromJson(_map(e))).toList()); }

class Journey { const Journey({required this.data}); final Map<String,dynamic> data; factory Journey.fromJson(Map<String,dynamic> j) => Journey(data: j); int get totalStages => _int(_map(data['journey'])['total_stages']); int get completedStages => _int(_map(data['journey'])['completed_stages']); }
class StreakSummary { const StreakSummary(this.data); final Map<String,dynamic> data; factory StreakSummary.fromJson(Map<String,dynamic> j) => StreakSummary(j); int get current => _int(data['current_streak']); int get longest => _int(data['longest_streak']); }
class LeaderboardEntry { const LeaderboardEntry({required this.rank, required this.userId, required this.name, required this.level, required this.levelTitle, required this.score}); final int rank,userId,level,score; final String name,levelTitle; factory LeaderboardEntry.fromJson(Map<String,dynamic> j)=>LeaderboardEntry(rank:_int(j['rank']),userId:_int(j['user_id']),name:'${j['name']??''}',level:_int(j['level']),levelTitle:'${j['level_title']??''}',score:_int(j['score'])); }
class LeaderboardMe { const LeaderboardMe({this.rank, required this.userId, required this.name, required this.level, required this.levelTitle, required this.score, required this.inTop}); final int? rank; final int userId,level,score; final String name,levelTitle; final bool inTop; factory LeaderboardMe.fromJson(Map<String,dynamic> j)=>LeaderboardMe(rank:_nullableInt(j['rank']),userId:_int(j['user_id']),name:'${j['name']??''}',level:_int(j['level']),levelTitle:'${j['level_title']??''}',score:_int(j['score']),inTop:j['in_top']==true); }
class Leaderboard { const Leaderboard({required this.period,required this.scoreType,required this.top,required this.me}); final String period,scoreType; final List<LeaderboardEntry> top; final LeaderboardMe me; factory Leaderboard.fromJson(Map<String,dynamic> j)=>Leaderboard(period:'${j['period']??''}',scoreType:'${j['score_type']??''}',top:((j['top'] as List?)??const[]).map((e)=>LeaderboardEntry.fromJson(_map(e))).toList(),me:LeaderboardMe.fromJson(_map(j['me']))); }
class ActivityResult { const ActivityResult({required this.duplicate,required this.activityId,required this.verificationStatus,required this.xpEarned,required this.coinsEarned,required this.xpBalance,required this.coinBalance,required this.taskProgress,required this.taskRewards,required this.newAchievements,required this.raw}); final bool duplicate; final dynamic activityId; final String verificationStatus; final int xpEarned,coinsEarned,xpBalance,coinBalance; final List<dynamic> taskProgress,taskRewards,newAchievements; final Map<String,dynamic> raw; factory ActivityResult.fromJson(Map<String,dynamic> j){final d=_map(j['data']);return ActivityResult(duplicate:j['duplicate']==true,activityId:d['activity_id'],verificationStatus:'${d['verification_status']??''}',xpEarned:_int(d['xp_earned']),coinsEarned:_int(d['coins_earned']),xpBalance:_int(d['xp_balance']),coinBalance:_int(d['coin_balance']),taskProgress:(d['task_progress'] as List?)??const[],taskRewards:(d['task_rewards'] as List?)??const[],newAchievements:(d['new_achievements'] as List?)??const[],raw:d);}}

Map<String,dynamic> _map(dynamic value) => value is Map ? Map<String,dynamic>.from(value) : <String,dynamic>{};
int _int(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
double _num(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
