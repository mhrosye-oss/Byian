import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api/gamification_api.dart';
import '../data/repositories/gamification_repository_impl.dart';
import '../domain/models/gamification_models.dart';
import '../domain/repositories/gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) => GamificationRepositoryImpl(GamificationApi()));
final gamificationProvider = StateNotifierProvider<GamificationNotifier,GamificationState>((ref) => GamificationNotifier(ref.read(gamificationRepositoryProvider)));

class GamificationState {
  const GamificationState({this.loading=false,this.error,this.profile,this.journey,this.tasks,this.streak,this.achievements,this.leaderboard,this.lastActivity});
  final bool loading; final String? error; final GamificationProfile? profile; final Journey? journey; final GamificationTaskList? tasks; final StreakSummary? streak; final AchievementList? achievements; final Leaderboard? leaderboard; final ActivityResult? lastActivity;
  GamificationState copyWith({bool? loading,String? error,bool clearError=false,GamificationProfile? profile,Journey? journey,GamificationTaskList? tasks,StreakSummary? streak,AchievementList? achievements,Leaderboard? leaderboard,ActivityResult? lastActivity})=>GamificationState(loading:loading??this.loading,error:clearError?null:(error??this.error),profile:profile??this.profile,journey:journey??this.journey,tasks:tasks??this.tasks,streak:streak??this.streak,achievements:achievements??this.achievements,leaderboard:leaderboard??this.leaderboard,lastActivity:lastActivity??this.lastActivity);
}

class GamificationNotifier extends StateNotifier<GamificationState> {
  GamificationNotifier(this.repository):super(const GamificationState()); final GamificationRepository repository;
  Future<void> loadAll() async {state=state.copyWith(loading:true,clearError:true);try{final results=await Future.wait<Object>([repository.getJourney(),repository.getTasks(),repository.getStreak(),repository.getProfile(),repository.getAchievements()]);state=state.copyWith(loading:false,journey:results[0] as Journey,tasks:results[1] as GamificationTaskList,streak:results[2] as StreakSummary,profile:results[3] as GamificationProfile,achievements:results[4] as AchievementList,clearError:true);}catch(e){state=state.copyWith(loading:false,error:'$e');}}
  Future<void> refreshProfile() async {try{state=state.copyWith(profile:await repository.getProfile(),clearError:true);}catch(e){state=state.copyWith(error:'$e');}}
  Future<void> refreshJourney() async {try{state=state.copyWith(journey:await repository.getJourney(),clearError:true);}catch(e){state=state.copyWith(error:'$e');}}
  Future<void> refreshLeaderboard() async {try{state=state.copyWith(leaderboard:await repository.getLeaderboard(),clearError:true);}catch(e){state=state.copyWith(error:'$e');}}
  Future<ActivityResult> recordActivity(ActivityType type,{Map<String,dynamic>? metadata}) async {final result=await repository.recordActivity(type,_uuidV4(),metadata:metadata);state=state.copyWith(lastActivity:result,clearError:true);await loadAll();return result;}
  String _uuidV4(){final r=Random.secure();final b=List<int>.generate(16,(_)=>r.nextInt(256));b[6]=(b[6]&0x0f)|0x40;b[8]=(b[8]&0x3f)|0x80;String h(int i)=>b[i].toRadixString(16).padLeft(2,'0');return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';}
}
