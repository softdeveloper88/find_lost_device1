import 'dart:async';
import 'dart:convert';
import 'dart:ui';

// import 'package:background_location/background_location.dart';
import 'package:find_lost_device1/screens/dashboard.dart';
import 'package:find_lost_device1/screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flashlight/flashlight.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_value/shared_value.dart';
import 'package:vibration/vibration.dart';

//initializeService
// Future<dynamic> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   await Firebase.initializeApp();
//   WidgetsFlutterBinding.ensureInitialized();
//   getCurrentLocation();
//   // responseLockApp();
//   // states.currentState.responseLockApp();
//   print('Handling a background message ${message.data['title']}');
//
// }
//
// Future<void> responseLockApp() async {
//   bool res;
//   try {
//     const platform1 = const MethodChannel('flutter.native/helper');
//
//     final bool result = await platform1.invokeMethod("lockScreen");
//     res = result;
//   } on PlatformException catch (e) {
//     var bools = "Failed to Invoke: '${e.message}'.";
//   }
//
// }
Future<dynamic> _throwGetMessage(RemoteMessage message) async {
  print("PUSH RECEIVED");
  // getCurrentLocation();
}
//
// void getCurrentLocation() {
//   BackgroundLocation.startLocationService();
//   BackgroundLocation().getCurrentLocation().then((location) async {
//     print('This is current Location ' + location.toMap().toString());
//     BackgroundLocation().getCurrentLocation().then((location) {
//       print('This is current Location ' + location.toMap().toString());
//     });
//     await BackgroundLocation.setAndroidNotification(
//       title: 'Background service is running',
//       message: 'Background location in progress',
//       icon: '@mipmap/ic_launcher',
//     );
//     await BackgroundLocation.setAndroidConfiguration(1000);
//     await BackgroundLocation.startLocationService(distanceFilter: 20);
//     BackgroundLocation.getLocationUpdates((location) {
//       var time =
//           DateTime.fromMillisecondsSinceEpoch(location.time.toInt()).toString();
//       print("Time:: $time");
//       print("Latitude:${location.latitude} Longitude: ${location.longitude}");
//
//       //   latitude = location.latitude.toString();
//       //   longitude = location.longitude.toString();
//       //   accuracy = location.accuracy.toString();
//       //   altitude = location.altitude.toString();
//       //   bearing = location.bearing.toString();
//       //   speed = location.speed.toString();
//       //   time = DateTime.fromMillisecondsSinceEpoch(
//       //       location.time!.toInt())
//       //       .toString();
//       // });
//       // print('''\n
//       //                   Latitude:  $latitude
//       //                   Longitude: $longitude
//       //                   Altitude: $altitude
//       //                   Accuracy: $accuracy
//       //                   Bearing:  $bearing
//       //                   Speed: $speed
//       //                   Time: $time
//       //                 ''');
//     });
//   });
// }

/// Create a [AndroidNotificationChannel] for heads up notifications
AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // getCurrentLocation();
  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();

  // // Set the background messaging handler early on, as a named top-level function
  // //  platform1 = const MethodChannel('flutter.native/helper');
  if (!kIsWeb) {
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    //App is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message, app is in the foreground!');
      print('Message data: ${message.data}');

      // if (message.notification != null) {
      //   print('Message also contained a notification: ${message.notification}');
      // }
    });

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    )
        .then((value) {
      print("value:print");
    });
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

Future<void> responseLockApp() async {
  const platform1 = const MethodChannel('flutter.native/helper');

  try {
    await platform1.invokeMethod("lockScreen");
  } on PlatformException catch (e) {
    var s = "Failed to Invoke: '${e.message}'.";
    print(s);
  }
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  AppLifecycleState _lastLifecyleState;

  FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      new FlutterLocalNotificationsPlugin();

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Firebase.initializeApp();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        print("hello Notification");
      }
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            message.data["title"],
            message.data["body"],
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                // TODO add a proper drawable resource to android, for now using
                //      one that already exists in example app.
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // print('A new onMessageOpenedApp event was published!');
      // if(message.data['title']=="Lock"){
      //   responseLockApp();
      // }else if(message.data['title']=="Location"){
      //   getCurrentLocation();
      // }else if(message.data['title']=="Flash"){
      //   Flashlight.lightOn();
      // }else if(message.data['title']=="EraseData"){
      //
      // }else if(message.data['title']=="Vibrate"){
      //   Vibration.vibrate(duration: 10000,
      //   );
      // }else{
      //   print("something when wrong");
      // }
    });
  }

  showNotification(Map<String, dynamic> msg) async {
    var android = new AndroidNotificationDetails(
      msg['title'],
      msg['body'],
      "channelDescription",
      importance: Importance.high,
      fullScreenIntent: true,
    );
    var iOS = new IOSNotificationDetails();
    var platform = new NotificationDetails(android: android, iOS: iOS);
    await flutterLocalNotificationsPlugin.show(
        0, msg['title'], msg['body'], platform);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("hellooooo");
    print(
        "LifecycleWatcherState#didChangeAppLifecycleState state=${state.toString()}");
    setState(() {
      _lastLifecyleState = state;
      print(_lastLifecyleState);
    });
  }

  Future<void> responseNoti() async {
    const platform1 = const MethodChannel('flutter.native/helper');

    try {
     await platform1.invokeMethod("initializeService");
    } on PlatformException catch (e) {
      print( "Failed to Invoke: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("PUSH RECEIVED build context");
      if (message.data['title'] == "Lock") {
        responseLockApp();
      } else if (message.data['title'] == "Location") {
        // getCurrentLocation();
      } else if (message.data['title'] == "Flash") {
        Flashlight.lightOn();
      } else if (message.data['title'] == "EraseData") {
      } else if (message.data['title'] == "Vibrate") {
        Vibration.vibrate(
          duration: 10000,
        );
      } else {
        print("something when wrong");
      }
      // responseLockApp();
      // getCurrentLocation();
      // bFirebaseMessaging.showPush(message);
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      if (message.data['title'] == "Lock") {
        responseLockApp();
      } else if (message.data['title'] == "Location") {
        // getCurrentLocation();
      } else if (message.data['title'] == "Flash") {
        Flashlight.lightOn();
      } else if (message.data['title'] == "EraseData") {
      } else if (message.data['title'] == "Vibrate") {
        Vibration.vibrate(
          duration: 10000,
        );
      } else {
        print("something when wrong");
      }
    });
    FirebaseMessaging.onBackgroundMessage(_throwGetMessage);
    return MaterialApp(
      title: 'Find Lost Phone',
      theme: ThemeData(
        backgroundColor: Colors.white,
        primarySwatch: Colors.blue,
      ),
      home: SplashScreens(),
    );
  }
// Crude counter to make messages unique
  int _messageCount = 0;
  /// The API endpoint here accepts a raw FCM payload for demonstration purposes.
  String constructFCMPayload(String token) {
    _messageCount++;
    return jsonEncode({
      'token': token,
      'data': {
        'via': 'FlutterFire Cloud Messaging!!!',
        'count': _messageCount.toString(),
      },
      'notification': {
        'title': 'Hello FlutterFire!',
        'body': 'This notification (#$_messageCount) was created via FCM!',
      },
    });
  }
}
