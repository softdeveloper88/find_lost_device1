import 'dart:io';import 'package:device_info/device_info.dart';import 'package:find_lost_device1/screens/erase_data_screen.dart';import 'package:find_lost_device1/screens/find_location.dart';import 'package:find_lost_device1/screens/flash_light_screen.dart';import 'package:find_lost_device1/screens/lock_screen.dart';import 'package:find_lost_device1/screens/ring_tone_screen.dart';import 'package:find_lost_device1/screens/vibrate_screen.dart';import 'package:firebase_auth/firebase_auth.dart';import 'package:firebase_database/firebase_database.dart';import 'package:firebase_messaging/firebase_messaging.dart';import 'package:flutter/material.dart';import 'package:flutter/services.dart';import 'package:google_sign_in/google_sign_in.dart';import 'package:progress_dialog/progress_dialog.dart';class GoogleSignScreen extends StatefulWidget {  String screen;   GoogleSignScreen({this.screen});  @override  _GoogleSignScreenState createState() => _GoogleSignScreenState();}class _GoogleSignScreenState extends State<GoogleSignScreen> {  ProgressDialog pr;  final fb = FirebaseDatabase.instance;  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();  Map<String, dynamic> _deviceData = <String, dynamic>{};  @override  void initState() {    initPlatformState();    // TODO: implement initState    super.initState();  }  Future<void> initPlatformState() async {    Map<String, dynamic> deviceData = <String, dynamic>{};    try {      if (Platform.isAndroid) {        deviceData = _readAndroidBuildData(await deviceInfoPlugin.androidInfo);      } else if (Platform.isIOS) {        deviceData = _readIosDeviceInfo(await deviceInfoPlugin.iosInfo);      }    } on PlatformException {      deviceData = <String, dynamic>{        'Error:': 'Failed to get platform version.'      };    }    if (!mounted) return;    setState(() {      _deviceData = deviceData;    });  }  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {    return <String, dynamic>{      'version.securityPatch': build.version.securityPatch,      'version.sdkInt': build.version.sdkInt,      'version.release': build.version.release,      'version.previewSdkInt': build.version.previewSdkInt,      'version.incremental': build.version.incremental,      'version.codename': build.version.codename,      'version.baseOS': build.version.baseOS,      'board': build.board,      'bootloader': build.bootloader,      'brand': build.brand,      'device': build.device,      'display': build.display,      'fingerprint': build.fingerprint,      'hardware': build.hardware,      'host': build.host,      'id': build.id,      'manufacturer': build.manufacturer,      'model': build.model,      'product': build.product,      'supported32BitAbis': build.supported32BitAbis,      'supported64BitAbis': build.supported64BitAbis,      'supportedAbis': build.supportedAbis,      'tags': build.tags,      'type': build.type,      'isPhysicalDevice': build.isPhysicalDevice,      'identifier': build.androidId,      'systemFeatures': build.systemFeatures,    };  }  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {    return <String, dynamic>{      'name': data.name,      'systemName': data.systemName,      'systemVersion': data.systemVersion,      'model': data.model,      'localizedModel': data.localizedModel,      'identifier ': data.identifierForVendor,      'isPhysicalDevice': data.isPhysicalDevice,      'utsname.sysname:': data.utsname.sysname,      'utsname.nodename:': data.utsname.nodename,      'utsname.release:': data.utsname.release,      'utsname.version:': data.utsname.version,      'utsname.machine:': data.utsname.machine,    };  }  @override  Widget build(BuildContext context) {    pr=ProgressDialog(context,isDismissible: false);    return Scaffold(        appBar: AppBar(          title: Text("Find Lost Phone"),        ),        body: Container(            child: Column(children: <Widget>[          Center(              child: ElevatedButton(            onPressed: () {              // if (_auth.currentUser != null) {              //   print("User Name: ${_auth.currentUser.displayName}");              //   print("User Email ${_auth.currentUser.email}");              //   print("User Profile ${_auth.currentUser.photoURL}");              //   print("User Profile ${_auth.currentUser.uid}");              //              //   // await FirebaseMessaging.instance.getToken().then((token) {              //   //   fb.reference().child(_deviceData['identifier']).set({              //   //     'name': _auth.currentUser.displayName,              //   //     'email': _auth.currentUser.email == null ? '' : _auth.currentUser.email,              //   //     'deviceModel': _deviceData['model'],              //   //     'manufactureName': _deviceData['manufacturer'],              //   //     'deviceToken': token,              //   //     'lat': 0.01,              //   //     'lng': 0.01              //   //   });              //   // });              //   Navigator.pushReplacement(context, newRoute)(context, route)(              //     context,              //     new MaterialPageRoute(              //         builder: (ctxt) => new UserInformation(              //             email: _auth.currentUser.email,              //             displayName: _auth.currentUser.displayName,              //             photoURL: _auth.currentUser.photoURL,              //             uid: _auth.currentUser.uid)),              //   );              // } else {                signInWithGoogle();              // }            },            child: Text("Google Sign"),          )),          SizedBox(            height: 4,          ),        ])        )    );  }  final FirebaseAuth _auth = FirebaseAuth.instance;  final GoogleSignIn _googleSignIn = GoogleSignIn();  Future signInWithGoogle() async {    GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();    GoogleSignInAuthentication googleSignInAuthentication =    await googleSignInAccount.authentication;    AuthCredential credential = GoogleAuthProvider.credential(      accessToken: googleSignInAuthentication.accessToken,      idToken: googleSignInAuthentication.idToken,    );    var authResult = await _auth.signInWithCredential(credential);    final _user = authResult;    var currentUser = _auth.currentUser;    assert(_user.user.uid == currentUser.uid);    print("User Name: ${_user.user.displayName}");    print("User Email ${_user.user.email}");    print("User Profile ${_user.user.photoURL}");    print("User Profile ${_user.user.uid}");    await FirebaseMessaging.instance.getToken().then((token) {      pr.show();      fb.reference().child(_deviceData['identifier']).set({        'name': _user.user.displayName,        'email': _user.user.email == null ? '' : _user.user.email,        'deviceModel': _deviceData['model'],        'manufactureName': _deviceData['manufacturer'],        'deviceToken': token,        'lat': 0.01,        'lng': 0.01      });    });    if(widget.screen=="lockScreen") {      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new LockScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=='flashScreen'){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new FlashLight(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=='location'){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new FindLocationScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=="Ring"){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new RingToneScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=="Vibrate"){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new VibrateScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=="LastTry"){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new VibrateScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }else if(widget.screen=="EraseData"){      pr.hide();      Navigator.pushReplacement(        context,        new MaterialPageRoute(            builder: (ctxt) =>            new EraseDataScreen(                email: _user.user.email,                displayName: _user.user.displayName,                photoURL: _user.user.photoURL,                uid: _user.user.uid)),      );    }  }}