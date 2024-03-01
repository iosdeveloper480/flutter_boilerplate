import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_boilerplate/config/locator.dart';
import 'package:flutter_boilerplate/models/models.dart';
import 'package:flutter_boilerplate/repositories/repositories.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    AuthRepository? authRepository,
  })  : _authRepository = authRepository ?? locator.get<AuthRepository>(),
        super(const AuthState.init()) {
    on<AuthInitialize>(onInitialize);
    on<AuthLogin>(onLogin);
    on<AuthLogout>(onLogout);
    on<AuthToggleAgreeToEULA>(onToggleAgreeToEULA);
    on<AuthFlag>(onFlag);
    add(AuthInitialize());
  }

  final AuthRepository _authRepository;

  Future<void> onInitialize(
    AuthInitialize event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.loggedIn.then((bool loggedIn) async {
      if (loggedIn) {
        final String? username = await _authRepository.username;
        User? user = await _authRepository.fetchUser(id: username!);

        /// According to Hacker News' API documentation,
        /// if user has no public activity (posting a comment or story),
        /// then it will not be available from the API.
        user ??= User.emptyWithId(username);

        emit(
          state.copyWith(
            isLoggedIn: true,
            user: user,
            status: Status.success,
          ),
        );
      } else {
        emit(
          state.copyWith(
            isLoggedIn: false,
            status: Status.success,
          ),
        );
      }
    });
  }

  Future<void> onToggleAgreeToEULA(
    AuthToggleAgreeToEULA event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(agreedToEULA: !state.agreedToEULA));
  }

  Future<void> onFlag(AuthFlag event, Emitter<AuthState> emit) async {
    if (state.isLoggedIn) {
      final bool flagged = false;
      await _authRepository.flag(id: 0, flag: !flagged);
    }
  }

  Future<void> onLogin(AuthLogin event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: Status.inProgress));

    final bool successful = await _authRepository.login(
      username: event.username,
      password: event.password,
    );

    if (successful) {
      final User? user = await _authRepository.fetchUser(id: event.username);
      emit(
        state.copyWith(
          user: user ?? User.emptyWithId(event.username),
          isLoggedIn: true,
          status: Status.success,
        ),
      );
    } else {
      emit(state.copyWith(status: Status.failure));
    }
  }

  Future<void> onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(
        user: const User.empty(),
        isLoggedIn: false,
        agreedToEULA: false,
      ),
    );

    await _authRepository.logout();
  }
}
