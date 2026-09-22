import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:share_plus/share_plus.dart';

const apiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://YOUR_BACKEND_DOMAIN');
const products = <String>{'credits_100','credits_500','credits_1500'};

Future<String> deviceId() async {
  final p = await SharedPreferences.getInstance();
  var id = p.getString('device_id');
  if (id == null) { id = 'ag_${DateTime.now().microsecondsSinceEpoch}'; await p.setString('device_id', id); }
  return id;
}

Future<Map<String,dynamic>> api(String path,{String method='GET',Map<String,dynamic>? body}) async {
  final id=await deviceId(); final uri=Uri.parse('$apiBase$path');
  final headers={'Content-Type':'application/json','x-device-id':id};
  final r=method=='POST' ? await http.post(uri,headers:headers,body:jsonEncode(body??{})) : await http.get(uri,headers:headers);
  if(r.statusCode>=400) throw Exception(r.body);
  return jsonDecode(r.body) as Map<String,dynamic>;
}

void main()=>runApp(const AGApp());
class AGApp extends StatelessWidget{const AGApp({super.key}); @override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,title:'AG Klicking AI',theme:ThemeData(useMaterial3:true,colorSchemeSeed:Colors.blue),home:const Home());}

class Home extends StatefulWidget{const Home({super.key}); @override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int credits=0; bool loading=true;
 @override void initState(){super.initState();_load();}
 Future<void> _load()async{try{final x=await api('/api/user/init',method:'POST');if(mounted)setState(()=>credits=x['user']['credits']??0);}catch(_){ }finally{if(mounted)setState(()=>loading=false);}}
 void refresh()=>_load();
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('AG Klicking AI',style:TextStyle(fontWeight:FontWeight.bold)),actions:[Padding(padding:const EdgeInsets.only(right:16),child:Center(child:Text('Credits: ${loading?'…':credits}',style:const TextStyle(fontWeight:FontWeight.bold))))]),body:ListView(padding:const EdgeInsets.all(18),children:[
  Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(borderRadius:BorderRadius.circular(26),gradient:const LinearGradient(colors:[Color(0xff0D47A1),Color(0xff42A5F5)])),child:const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Create with AI',style:TextStyle(color:Colors.white,fontSize:29,fontWeight:FontWeight.bold)),SizedBox(height:8),Text('Image • Video • Voice • Story',style:TextStyle(color:Colors.white70,fontSize:16))])),
  const SizedBox(height:16), _tile(c,'AI Image',Icons.image,'image'),_tile(c,'AI Video',Icons.movie,'video'),_tile(c,'AI Voice',Icons.record_voice_over,'voice'),_tile(c,'Story to Video',Icons.auto_stories,'story'),
  Card(child:ListTile(leading:const Icon(Icons.workspace_premium),title:const Text('Buy Credits',style:TextStyle(fontWeight:FontWeight.bold)),subtitle:const Text('100 / 500 / 1500 credits'),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const Shop())).then((_){refresh();}))),
  Card(child:ListTile(leading:const Icon(Icons.collections),title:const Text('My Creations',style:TextStyle(fontWeight:FontWeight.bold)),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>const History())))),
  const SizedBox(height:12),const Text('Free trial: 3 credits for new users.',textAlign:TextAlign.center,style:TextStyle(color:Colors.grey)),
 ]);}
 Widget _tile(BuildContext c,String t,IconData i,String type)=>Card(child:ListTile(leading:Icon(i,size:30),title:Text(t,style:const TextStyle(fontWeight:FontWeight.bold)),trailing:const Icon(Icons.chevron_right),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>Generator(title:t,type:type))).then((_){refresh();})));
}

class Generator extends StatefulWidget{final String title,type;const Generator({super.key,required this.title,required this.type});@override State<Generator> createState()=>_GeneratorState();}
class _GeneratorState extends State<Generator>{final ctl=TextEditingController();String ratio='16:9';bool busy=false;String out='';
 Future<void> run()async{final text=ctl.text.trim();if(text.isEmpty)return;setState(()=>busy=true);try{String path;Map<String,dynamic> body;if(widget.type=='image'){path='/api/image';body={'prompt':text,'ratio':ratio};}else if(widget.type=='video'){path='/api/video';body={'prompt':text,'ratio':ratio,'duration':8};}else if(widget.type=='voice'){path='/api/voice';body={'text':text};}else{path='/api/story-to-video/plan';body={'story':text,'sceneCount':6};}final r=await http.post(Uri.parse('$apiBase$path'),headers:{'Content-Type':'application/json','x-device-id':await deviceId()},body:jsonEncode(body));if(r.statusCode>=400)throw Exception(r.body);final decoded=jsonDecode(r.body); final u=decoded is Map ? decoded['output_url'] : null; setState(()=>out='Request submitted successfully.\n\n${u!=null?'Output: '+u+'\n\nYou can share this link on WhatsApp or open it on your PC/Laptop.\n\n':''}${r.body}');}catch(e){setState(()=>out='Error: $e');}finally{if(mounted)setState(()=>busy=false);}}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:Text(widget.title)),body:ListView(padding:const EdgeInsets.all(18),children:[TextField(controller:ctl,maxLines:7,decoration:InputDecoration(hintText:widget.type=='voice'?'अपना voice text लिखें...':'अपना prompt/story लिखें...',border:OutlineInputBorder(borderRadius:BorderRadius.circular(18)))),if(widget.type!='voice')...[
 const SizedBox(height:14),DropdownButtonFormField<String>(value:ratio,items:['16:9','9:16','1:1'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(x)=>setState(()=>ratio=x!),decoration:const InputDecoration(labelText:'Aspect Ratio',border:OutlineInputBorder())),],const SizedBox(height:14),FilledButton.icon(onPressed:busy?null:run,icon:const Icon(Icons.auto_awesome),label:Text(busy?'Generating...':'Generate')),if(out.isNotEmpty)...[Padding(padding:const EdgeInsets.only(top:20),child:SelectableText(out)), if(out.contains('https://')) Padding(padding:const EdgeInsets.only(top:10),child:FilledButton.icon(onPressed:()async{final match=RegExp(r'https?://\S+').firstMatch(out);if(match!=null)await Share.share('AG Klicking AI Result\n${match.group(0)}');},icon:const Icon(Icons.share),label:const Text('WhatsApp / Share')))]]));}
}

class Shop extends StatefulWidget{const Shop({super.key});@override State<Shop> createState()=>_ShopState();}
class _ShopState extends State<Shop>{final iap=InAppPurchase.instance;late StreamSubscription<List<PurchaseDetails>> sub;List<ProductDetails> items=[];String msg='Loading products...';
 @override void initState(){super.initState();sub=iap.purchaseStream.listen(_purchases);_loadProducts();}
 Future<void> _loadProducts()async{final ok=await iap.isAvailable();if(!ok){setState(()=>msg='Google Play Billing is unavailable.');return;}final r=await iap.queryProductDetails(products);setState((){items=r.productDetails;msg=r.notFoundIDs.isEmpty?'Choose a credit pack':'Create the products in Play Console with these IDs: credits_100, credits_500, credits_1500';});}
 void _buy(ProductDetails p)=>iap.buyConsumable(purchaseParam:PurchaseParam(productDetails:p),autoConsume:true);
 Future<void> _purchases(List<PurchaseDetails> ps)async{for(final p in ps){if(p.status==PurchaseStatus.purchased){try{final result=await api('/api/billing/verify',method:'POST',body:{'productId':p.productID,'purchaseToken':p.verificationData.serverVerificationData});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Credits added. Balance: ${result['user']['credits']}')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Verification failed: $e')));}}else if(p.status==PurchaseStatus.error&&mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(p.error?.message??'Purchase failed')));}if(p.pendingCompletePurchase)await iap.completePurchase(p);}}
 @override void dispose(){sub.cancel();super.dispose();}
 @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('Buy Credits')),body:ListView(padding:const EdgeInsets.all(18),children:[Text(msg),const SizedBox(height:16),...items.map((p)=>Card(child:ListTile(title:Text(p.title),subtitle:Text(p.description),trailing:FilledButton(onPressed:()=>_buy(p),child:Text(p.price))))) ]));}

class History extends StatelessWidget{const History({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(title:const Text('My Creations')),body:FutureBuilder<Map<String,dynamic>>(future:api('/api/creations'),builder:(c,s){if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());if(s.hasError)return Center(child:Text('Unable to load history'));final a=(s.data!['items'] as List?)??[];if(a.isEmpty)return const Center(child:Text('No creations yet.'));return ListView.builder(itemCount:a.length,itemBuilder:(_,i){final x=a[i] as Map<String,dynamic>; final url=x['output_url']?.toString(); return Card(child:ListTile(title:Text('${x['type']}'),subtitle:Text('${x['status']} • ${x['created_at']}'),isThreeLine:url!=null, onTap:url==null?null:()=>showModalBottomSheet(context:context,builder:(_)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(Icons.share),title:const Text('WhatsApp / Share'),onTap:()async{Navigator.pop(context);await Share.share('AG Klicking AI\n${x['title']??'My creation'}\n$url');}),ListTile(leading:const Icon(Icons.download),title:const Text('Open / Download'),onTap:()async{Navigator.pop(context);await Share.share('Download: $url');})]))));}); }));}}
