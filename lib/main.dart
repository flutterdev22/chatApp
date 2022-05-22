
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:test_app/chat/chat_welcome_screen.dart';
import 'package:test_app/services/fcm_services.dart';
import 'package:test_app/services/local_notifications.dart';

import 'globals.dart';

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Globals.init();
  await LocalNotificationsService.instance.initialize();
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  FCMServices.fcmGetTokenandSubscribe('chat');
  fcmListen();

  runApp(const MyApp());
}

Future<void> _messageHandler(RemoteMessage event) async {
  await Firebase.initializeApp();

  if (event.data['id'] == FirebaseAuth.instance.currentUser?.uid) {
    LocalNotificationsService.instance.showNotification(
        title: '${event.notification?.title}',
        body: '${event.notification?.body}');

    FirebaseMessaging.onMessageOpenedApp.listen((message) {});
  }

  print("Handling a background message: ${event.messageId}");
}

fcmListen() async {
  // var sfID = await AuthServices.getTraderID();
  FirebaseMessaging.onMessage.listen((RemoteMessage event) {
    // log('event: $event');
    if (event.data['id'] == FirebaseAuth.instance.currentUser?.uid ||
        event.data['id'].toString() == "all") {
      LocalNotificationsService.instance.showNotification(
          title: '${event.notification?.title}',
          body: '${event.notification?.body}');

      FirebaseMessaging.onMessageOpenedApp.listen((message) {});
    } else {}
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ScreenUtilInit(
      designSize: const Size(345, 810),
        builder: (context){
        return MaterialApp(
          theme: ThemeData(
            //NEW ADDITION
            pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                }
            ),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.transparent),
          ),
          debugShowCheckedModeBanner: false,
          home:const ChatWelcomeScreen(),
        );
        }
    );
  }
}

