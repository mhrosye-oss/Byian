import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/gamification_provider.dart';
import '../../domain/models/gamification_models.dart';
import '../../widgets/placeholder.dart';
import '../widgets/task_card.dart';
import '../../../adhkar/screens/new_adhkar_screen.dart';
import '../../../adhkar/screens/duas_screen.dart';
import '../../../mushaf/mushaf_page_screen.dart';

class JourneyScreen extends ConsumerStatefulWidget {const JourneyScreen({super.key});@override ConsumerState<JourneyScreen> createState()=>_JourneyScreenState();}
class _JourneyScreenState extends ConsumerState<JourneyScreen>{@override void initState(){super.initState();Future.microtask(()=>ref.read(gamificationProvider.notifier).loadAll());}
@override Widget build(BuildContext context){final s=ref.watch(gamificationProvider);return Scaffold(appBar:AppBar(title:const Text('رحلتك إلى الأفضل')),body:s.loading&&s.tasks==null?const Center(child:CircularProgressIndicator()):s.error!=null&&s.tasks==null?Center(child:Column(mainAxisSize:MainAxisSize.min,children:[Text(s.error!),TextButton(onPressed:()=>ref.read(gamificationProvider.notifier).loadAll(),child:const Text('إعادة المحاولة'))])):RefreshIndicator(onRefresh:()=>ref.read(gamificationProvider.notifier).loadAll(),child:ListView(padding:const EdgeInsets.all(16),children:[if(s.profile!=null)_summary(s.profile!),...(s.tasks?.tasks??const <GamificationTask>[]).map((t)=>Padding(padding:const EdgeInsets.only(bottom:12),child:TaskCard(task:t,large:true,icon:_icon(t.pillar),onTap:()=>_open(context,t.pillar)))),const SizedBox(height:12),Text('المهام المكتملة اليوم: ${s.tasks?.completed??0} / ${s.tasks?.total??0}'),if(s.streak!=null)Text('سلسلة الاستمرارية: ${s.streak!.current}')])));}
Widget _summary(GamificationProfile p)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('المستوى ${p.level?.number??'—'} • ${p.level?.title??''}'),Text('${p.totalXp} XP'),LinearProgressIndicator(value:((p.level?.progressPercentage??0)/100).clamp(0,1)),Text('المهام: ${p.tasksCompleted} / ${p.tasksTotal}')])));
IconData _icon(String p)=>p.contains('quran')?Icons.menu_book_rounded:p.contains('adhkar')?Icons.spa_rounded:p.contains('dua')?Icons.pan_tool_rounded:Icons.share_rounded;
void _open(BuildContext context,String pillar){final Widget page=pillar.contains('quran')?const MushafPageScreen(startPage:1):pillar.contains('adhkar')?const NewAdhkarScreen():pillar.contains('dua')?const DuasScreen():const DuasScreen();Navigator.push(context,MaterialPageRoute<void>(builder:(_)=>page));}}
