import 'dart:async';

import 'package:flutter_boilerplate/config/locator.dart';
import 'package:flutter_boilerplate/models/models.dart';
import 'package:flutter_boilerplate/repositories/repositories.dart';
import 'package:logger/logger.dart';

/// [AuthRepository] if for logging user in/out and performing actions
/// that require a logged in user such as [flag], [favorite], [upvote],
/// and [downvote].
///
/// For posting actions such as posting a comment, see [PostRepository].
class AuthRepository extends PostableRepository {
  AuthRepository({
    super.dio,
    PreferenceRepository? preferenceRepository,
    Logger? logger,
  })  : _preferenceRepository =
            preferenceRepository ?? locator.get<PreferenceRepository>(),
        _logger = logger ?? locator.get<Logger>();

  final PreferenceRepository _preferenceRepository;
  final Logger _logger;

  Future<bool> get loggedIn async => _preferenceRepository.loggedIn;

  Future<String?> get username async => _preferenceRepository.username;

  Future<String?> get password async => _preferenceRepository.password;

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final Uri uri = Uri.https(authority, 'login');

    final bool success = await performDefaultPost(uri);

    if (success) {
      try {
        await _preferenceRepository.setAuth(
          username: username,
          password: password,
        );
      } catch (_) {
        _logger.e(_);
        return false;
      }
    }

    return success;
  }

  Future<bool> hasLoggedIn() => _preferenceRepository.loggedIn;

  Future<void> logout() async {
    await _preferenceRepository.removeAuth();
  }

  Future<bool> flag({
    required int id,
    required bool flag,
  }) async {
    final Uri uri = Uri.https(authority, 'flag');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    return performDefaultPost(uri);
  }

  Future<bool> favorite({
    required int id,
    required bool favorite,
  }) async {
    final Uri uri = Uri.https(authority, 'fave');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    return performDefaultPost(uri);
  }

  Future<bool> upvote({
    required int id,
    required bool upvote,
  }) async {
    final Uri uri = Uri.https(authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    return performDefaultPost(uri);
  }

  Future<bool> downvote({
    required int id,
    required bool downvote,
  }) async {
    final Uri uri = Uri.https(authority, 'vote');
    final String? username = await _preferenceRepository.username;
    final String? password = await _preferenceRepository.password;

    return performDefaultPost(uri);
  }

  Future<User?> fetchUser({required String id}) async {}
}
