import 'dart:convert';

import 'package:flutter_boilerplate/config/constants.dart';
import 'package:flutter_boilerplate/models/models.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  Future<void> pushForNewReply(User newReply, int storyId) async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    final Map<String, int> payloadJson = <String, int>{
      'commentId': int.parse(newReply.id),
      'storyId': storyId,
    };
    final String payload = jsonEncode(payloadJson);

    return flutterLocalNotificationsPlugin.show(
      int.parse(newReply.id),
      'You have a new reply! ${Constants.happyFace}',
      '${newReply.id}: ${newReply.description}',
      const NotificationDetails(
        iOS: DarwinNotificationDetails(
          presentBadge: false,
          threadIdentifier: 'hacki',
        ),
      ),
      payload: payload,
    );
  }
}
