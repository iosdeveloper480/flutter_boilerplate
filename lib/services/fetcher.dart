import 'dart:io';

import 'package:path_provider_android/path_provider_android.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:shared_preferences_android/shared_preferences_android.dart';
import 'package:shared_preferences_foundation/shared_preferences_foundation.dart';
import 'package:workmanager/workmanager.dart';

void fetcherCallbackDispatcher() {
  Workmanager()
      .executeTask((String task, Map<String, dynamic>? inputData) async {
    if (Platform.isAndroid) {
      PathProviderAndroid.registerWith();
      SharedPreferencesAndroid.registerWith();
    } else if (Platform.isIOS) {
      PathProviderFoundation.registerWith();
      SharedPreferencesFoundation.registerWith();
    }

    await Fetcher.fetchReplies();

    return Future<bool>.value(true);
  });
}

abstract class Fetcher {
  static const int _subscriptionUpperLimit = 15;

  static Future<void> fetchReplies() async {}
}
