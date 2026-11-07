import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/itqan_journey_provider.dart';
import '../../data/journey_content_repository.dart';

class DuaJourneyScreen extends ConsumerStatefulWidget { const DuaJourneyScreen({super.key}); @override ConsumerState<DuaJourneyScreen> createState()=>_DuaJourneyScreenState(); }
class _DuaJourneyScreenState extends ConsumerState<DuaJourneyScreen> {
 final _repo=JourneyContentRepository(); List<Map<String,dynamic>> _duas=[]; bool _loading=true; final Set<int> _done={}; final Set<int> _favorites={}; final Set<int> _submitting={};
 @override void initState(){super.initState();_load();}
 Future<void> _load() async {try{_duas=await _repo.loadDuas();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر تحميل الأدعية: $e')));}finally{if(mounted)setState(()=>_loading=false);}}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('أدعية الرحلة')),body:_loading?const Center(child:CircularProgressIndicator()):ListView.builder(padding:const EdgeInsets.all(16),itemCount:_duas.length,itemBuilder:(context,i){final d=_duas[i];return Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${d['category']??''} • ${d['title']??''}',style:Theme.of(context).textTheme.titleMedium)),IconButton(onPressed:()=>setState(()=>_favorites.contains(i)?_favorites.remove(i):_favorites.add(i)),icon:Icon(_favorites.contains(i)?Icons.favorite:Icons.favorite_border))]),const Divider(),Text('${d['text']??''}',textDirection:TextDirection.rtl,style:Theme.of(context).textTheme.headlineSmall),Text('${d['reference']??''}'),FilledButton(onPressed:_done.contains(i)||_submitting.contains(i)?null:()=>_complete(i),child:Text(_done.contains(i)?'تمت القراءة':'تمت القراءة'))])));}));
 Future<void> _complete(int i)async{setState(()=>_submitting.add(i));try{final r=await ref.read(itqanJourneyProvider.notifier).recordActivity('dua');if(mounted){setState(()=>_done.add(i));ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('قبل الخادم القراءة • ${r['data']?['xp_earned']??0} XP')));}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('لم يقبل الخادم النشاط: $e')));}finally{if(mounted)setState(()=>_submitting.remove(i));}}
}
