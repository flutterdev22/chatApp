// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

dynamic serverKey = "AAAAf-CHyW8:APA91bHUSMNDVOEMXpiI6HHrNMbv0wiemMDEJ2Mwz_lUNbwtNJIe08d4pnv72SZsdUOw9Do9n39NTgbOKgH7IZlED9tve94NEAKTszsic0b3tKyYkV69PKN57jPW9K-TypN4Z0x6mIFB";

class FCMServices {
  static fcmGetTokenandSubscribe(topic) {
    FirebaseMessaging.instance.getToken().then((value) {
      FirebaseMessaging.instance.subscribeToTopic("$topic");
    });
  }

  static Future<http.Response> sendFCM(topic, id, title, description) {
    return http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': "key=$serverKey",
      },
      body: jsonEncode({
        "to": "/topics/$topic",
        "notification": {
          "title": title,
          "body": description,
        },
        "mutable_content": true,
        "content_available": true,
        "priority": "high",
        "data": {
          "android_channel_id": "News Blog",
          "id": id,
          "userName": "newsBlog",
        }
      }),
    );
  }
}