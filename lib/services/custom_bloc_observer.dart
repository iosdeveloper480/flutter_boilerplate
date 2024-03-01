import 'package:bloc/bloc.dart';
import 'package:flutter_boilerplate/config/locator.dart';
import 'package:logger/logger.dart';

class CustomBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
  }

  @override
  void onEvent(
    Bloc<dynamic, dynamic> bloc,
    Object? event,
  ) {
    super.onEvent(bloc, event);
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
  }

  @override
  void onError(
    BlocBase<dynamic> bloc,
    Object error,
    StackTrace stackTrace,
  ) {
    locator.get<Logger>().e(error);
    locator.get<Logger>().e(stackTrace);

    super.onError(bloc, error, stackTrace);
  }
}
