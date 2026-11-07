import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareJourneyScreen extends ConsumerStatefulWidget { const ShareJourneyScreen({super.key}); @override ConsumerState<ShareJourneyScreen> createState()=>_ShareJourneyScreenState(); }
class _ShareJourneyScreenState extends ConsumerState<ShareJourneyScreen> {
 final _message=TextEditingController(); bool _sending=false;
 @override void dispose(){_message.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('مشاركة الخير')),body:ListView(padding:const EdgeInsets.all(20),children:[const Text('اكتب فائدة أو ذكراً أو دعاءً موثوقاً لمشاركته.'),const SizedBox(height:12),TextField(controller:_message,minLines:4,maxLines:8,textDirection:TextDirection.rtl,decoration:const InputDecoration(border:OutlineInputBorder(),hintText:'أدخل المحتوى الذي تريد مشاركته')),const SizedBox(height:12),FilledButton.icon(onPressed:_sending?null:_share,icon:const Icon(Icons.share),label:Text(_sending?'جارٍ فتح المشاركة':'مشاركة الخير'))]));
 Future<void> _share()async{final text=_message.text.trim();if(text.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل محتوى المشاركة أولاً')));return;}setState(()=>_sending=true);try{final uri=Uri(scheme:'mailto',queryParameters:{'body':text});final opened=await launchUrl(uri,mode:LaunchMode.externalApplication);if(!opened)throw StateError('تعذر فتح وسيلة مشاركة');if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('فُتحت وسيلة المشاركة. لم يُسجّل إنجاز لأن الإرسال الفعلي غير قابل للتحقق عبر هذه الواجهة.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذرت المشاركة: $e')));}finally{if(mounted)setState(()=>_sending=false);}}
}
