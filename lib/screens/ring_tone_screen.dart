import 'dart:convert';import 'package:find_lost_device1/model/device_model.dart';import 'package:firebase_database/firebase_database.dart';import 'package:flutter/material.dart';import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';import 'package:http/http.dart' as http;class RingToneScreen extends StatefulWidget {  String email, displayName, photoURL, uid;  RingToneScreen({this.email, this.displayName, this.photoURL, this.uid});  @override  _RingToneScreenState createState() => _RingToneScreenState();}class _RingToneScreenState extends State<RingToneScreen> {  List<DeviceModel> deviceModel = [];  @override  Widget build(BuildContext context) {    return Scaffold(        appBar: AppBar(title: Text("Ring Tone Screen")),        body: Container(            width: double.infinity,            height: MediaQuery.of(context).size.height,            alignment: Alignment.center,            padding: EdgeInsets.all(40),            //set width and height of outermost wrapper to 100%;            child: Column(              children: [                Center(                    child: Column(children: <Widget>[                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('playAlarm'),                      onPressed: () {                        FlutterRingtonePlayer.playAlarm();                      },                    ),                  ),                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('playAlarm asAlarm: false'),                      onPressed: () {                        FlutterRingtonePlayer.playAlarm(asAlarm: false);                      },                    ),                  ),                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('playNotification'),                      onPressed: () {                        FlutterRingtonePlayer.playNotification();                      },                    ),                  ),                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('playRingtone'),                      onPressed: () {                        FlutterRingtonePlayer.playRingtone();                      },                    ),                  ),                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('play'),                      onPressed: () {                        FlutterRingtonePlayer.play(                          android: AndroidSounds.notification,                          ios: IosSounds.glass,                          looping: true,                          volume: 1.0,                        );                      },                    ),                  ),                  Padding(                    padding: EdgeInsets.all(8),                    child: ElevatedButton(                      child: const Text('stop'),                      onPressed: () {                        FlutterRingtonePlayer.stop();                      },                    ),                  ),                ])),                Expanded(                    child: Center(                  child: FutureBuilder(                      future: FirebaseDatabase.instance.reference().once(),                      builder: (BuildContext context,                          AsyncSnapshot<DataSnapshot> snapshot) {                        if (snapshot.hasData) {                          deviceModel.clear();                          Map<dynamic, dynamic> values = snapshot.data.value;                          values.forEach((key, values) {                            if(values['email'] == widget.email) {                            deviceModel.add(DeviceModel(                                key,                                values['deviceModel'],                                values['email'],                                values['name'],                                values['manufactureName'],                                values['deviceToken'],                                values['lat'],                                values['lng']));                            }                          });                          return ListView.builder(                              itemCount: deviceModel.length,                              itemBuilder: (context, index) {                                return Card(                                  color: Colors.red,                                  //elevation: 2.0,                                  child: GestureDetector(                                    onTap: () {                                      print("click");                                      sendFcmMessage(                                          "Ring",                                          "Ringing My Phone",                                          deviceModel[index].deviceToken);                                    },                                    child: new ListTile(                                      title: new Text(                                          "Device Mode:${deviceModel[index].deviceModel}"),                                    ),                                  ),                                );                              });                        } else if (snapshot.hasError) {                          return Icon(Icons.error_outline);                        } else {                          return CircularProgressIndicator();                        }                      }),                ))              ],            )));  }  Future<bool> sendFcmMessage(      String title, String message, String token) async {    try {      var url = 'https://fcm.googleapis.com/fcm/send';      var header = {        "Content-Type": "application/json",        "Authorization":            "Bearer	AAAAzpd-_iA:APA91bGqz8ppYKEP2Ff6GRn6Ksh3X-QwAGPx-c7vQTr_tpEa-y6C2VjJKAOc3duHuOrfDyJV2EE5kxVFlQLjnXYA0aFV700SjSBPb0bgC4rCxJzUI9ieeoXu4x2CvReJGfo5-wNOtTsl",      };      // var request = {      //   "notification": {      //     "title": title,      //     "text": message,      //     "sound": "default",      //     "color": "#990000",      //   },      //   "priority": "high",      //   "to": "/topics/all",      // };      // var request = {      //   'notification': {'title': title, 'body': message},      //   'data': {      //     'click_action': 'FLUTTER_NOTIFICATION_CLICK',      //     'type': 'COMMENT'      //   },      //   'to': token      // };      var request = {        "registration_ids":[          token        ],        "data":{          "body":message,          "title":title        }      };      var response = await http.post(Uri.parse(url),          headers: header, body: json.encode(request));      print(response.body);      return true;    } catch (e) {      print(e);      return false;    }  }}