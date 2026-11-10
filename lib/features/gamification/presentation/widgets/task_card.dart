import 'package:flutter/material.dart';
import '../../domain/models/gamification_models.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({super.key,required this.task,required this.icon,required this.onTap,this.large=false});
  final GamificationTask task; final IconData icon; final VoidCallback onTap; final bool large;
  @override Widget build(BuildContext context){final theme=Theme.of(context);final ratio=task.target<=0?0.0:(task.progress/task.target).clamp(0.0,1.0);return Card(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)),child:InkWell(borderRadius:BorderRadius.circular(18),onTap:onTap,child:Padding(padding:EdgeInsets.all(large?18:12),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:theme.colorScheme.primary),const SizedBox(width:8),Expanded(child:Text(task.title,style:theme.textTheme.titleMedium,maxLines:1,overflow:TextOverflow.ellipsis)),if(task.completed)Icon(Icons.check_circle,color:theme.colorScheme.tertiary)]),const SizedBox(height:8),Text(task.description,style:theme.textTheme.bodySmall),if(task.target>0)...[const SizedBox(height:10),LinearProgressIndicator(value:ratio),const SizedBox(height:4),Text('${task.progress} / ${task.target}',style:theme.textTheme.labelSmall)],const SizedBox(height:8),Wrap(spacing:8,children:[Text(_status(task.status),style:theme.textTheme.labelMedium),Text('✦ ${task.xpReward} XP',style:theme.textTheme.labelMedium),Text('◉ ${task.coinReward}',style:theme.textTheme.labelMedium)])]))));}
  String _status(String status)=>switch(status){'completed'=>'مكتملة','in_progress'=>'قيد التنفيذ',_=>'لم تبدأ'};
}
