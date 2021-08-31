import 'dart:async';import 'package:flutter/material.dart';import 'package:flutter/services.dart';import 'package:fluttertoast/fluttertoast.dart';import 'package:shared_preferences/shared_preferences.dart';class DontTouchScreen extends StatefulWidget {  @override  _DontTouchScreenState createState() => _DontTouchScreenState();}class _DontTouchScreenState extends State<DontTouchScreen> {  Color _backgroundColor = Colors.indigo;  static bool start = false;  SharedPreferences prefs;  static const platform1 = const MethodChannel('flutter.native/helper');  Future<void> responseSensor(bool start) async {    try {      if (start) {        await platform1.invokeMethod("sensorDetectionActive");      } else {        await platform1.invokeMethod("sensorDetectionDeactive");      }    } on PlatformException catch (e) {      print("Failed to Invoke: '${e.message}'.");    }    setState(() {      // _responseFromNativeCode1=res;    });  }  Future<void> prefrenses() async {    prefs = await SharedPreferences.getInstance();    start = prefs.getBool("start") ?? false;    print(start);    setState(() {});  }  Timer _timer;  int _start = 5;  void startTimer() {    const oneSec = const Duration(seconds: 1);    _timer = new Timer.periodic(      oneSec,          (Timer timer) {        if (_start == 0) {          setState(() {            responseSensor(true);            prefs.setBool("start", start);            timer.cancel();          });        } else {          setState(() {            Fluttertoast.showToast(                msg: "Sensor Service Start after::${_start}",                toastLength: Toast.LENGTH_SHORT,                gravity: ToastGravity.CENTER,                timeInSecForIosWeb: 1,                backgroundColor: Colors.red,                textColor: Colors.white,                fontSize: 16.0);             _start--;          });        }      },    );  }  @override  void initState() {    // openSensor();    prefrenses();    // TODO: implement initState    super.initState();  }  @override  void dispose() {    _timer.cancel();    // TODO: implement dispose    super.dispose();  }  @override  Widget build(BuildContext context) {    print("d $start");    return Scaffold(      backgroundColor: _backgroundColor,      body: Column(        // mainAxisAlignment: MainAxisAlignment.center,        crossAxisAlignment: CrossAxisAlignment.stretch,        children: <Widget>[          Container(            margin: EdgeInsets.only(                top: (MediaQuery.of(context).size.height) / 2 - 60),            child: Text(              "Don't touch phone",              textAlign: TextAlign.center,              style: TextStyle(                fontSize: 24,                color: Colors.white,              ),            ),          ),          GestureDetector(            onTap: () {              if (start) {                setState(() {                  start = false;                  prefs.setBool("start", start);                  responseSensor(false);                  _timer.cancel();                });              } else {                setState(() {                  startTimer();                  start = true;                });              }            },            child: Container(              margin: EdgeInsets.only(                  top: (MediaQuery.of(context).size.height / 8)),              padding: EdgeInsets.all(10),              child: Center(                child: Container(                  padding: EdgeInsets.all(15),                  decoration: BoxDecoration(                    borderRadius: BorderRadius.circular(30),                    color: Colors.amber[700],                  ),                  child: Text(                    start ? "Stop" : "Start",                    style: TextStyle(fontSize: 20),                  ),                ),              ),            ),          ),        ],      ),    );  }// void openSensor() {//   accelerometerEvents.listen((AccelerometerEvent event) {//     print(event.x);//     print(event.y);//     print(event.z);//     setState(() {//       if(start) {//         if (event.y < -3 || event.y > 3 || event.x < -6 || event.x > 6) {//           _backgroundColor = Colors.red;//           Navigator.pushReplacement(//             context,//             new MaterialPageRoute(builder: (ctxt) => new BillStartScreen()),//           );//           start=false;//         } else//           _backgroundColor = Colors.indigo;//       }//     });//  });// }}