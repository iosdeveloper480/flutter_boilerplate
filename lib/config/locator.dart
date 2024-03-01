import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/config/custom_log_filter.dart';
import 'package:flutter_boilerplate/repositories/repositories.dart';
import 'package:flutter_boilerplate/services/services.dart';
import 'package:flutter_boilerplate/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';

/// Global [GetIt.instance].
final GetIt locator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final File logOutputFile = await LogUtil.initLogFile();

  locator
    ..registerSingleton<Logger>(
      Logger(
        filter: CustomLogFilter(),
        printer: LogUtil.logPrinter,
        output: LogUtil.logOutput(logOutputFile),
      ),
    )
    ..registerSingleton<AuthRepository>(AuthRepository())
    ..registerSingleton<LocalNotificationService>(LocalNotificationService())
    ..registerSingleton<RouteObserver<ModalRoute<dynamic>>>(
      RouteObserver<ModalRoute<dynamic>>(),
    );
}
