import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_boilerplate/blocs/auth/auth_bloc.dart';
import 'package:flutter_boilerplate/extensions/extensions.dart';
import 'package:flutter_boilerplate/styles/styles.dart';
import 'package:go_router/go_router.dart';

@optionalTypeArgs
mixin ItemActionMixin<T extends StatefulWidget> on State<T> {
  void showSnackBar({
    required String content,
    VoidCallback? action,
    String? label,
  }) {
    context.showSnackBar(
      content: content,
      action: action,
      label: label,
    );
  }

  void showErrorSnackBar([String? message]) =>
      context.showErrorSnackBar(message);

  Future<void>? goToItemScreen({
    bool forceNewScreen = false,
  }) {
    return Future<void>.value();
  }

  void onMoreTapped(Rect? rect) {}

  void onFavTapped() {}

  Future<void> onShareTapped(Rect? rect) async {}

  void onFlagTapped() {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Flag this comment?'),
          content: Text(
            'Flag this comment posted by item.by?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        context.read<AuthBloc>().add(AuthFlag());
        showSnackBar(content: 'Comment flagged!');
      }
    });
  }

  void onBlockTapped({required bool isBlocked}) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('${isBlocked ? 'Unblock' : 'Block'} this user?'),
          content: Text(
            'Do you want to ${isBlocked ? 'unblock' : 'block'} item.by'
            ' and ${isBlocked ? 'display' : 'hide'} '
            'comments posted by this user?',
            style: const TextStyle(
              color: Palette.grey,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text(
                'Yes',
              ),
            ),
          ],
        );
      },
    ).then((bool? yesTapped) {
      if (yesTapped ?? false) {
        // if (isBlocked) {
        //   context.read<BlocklistCubit>().removeFromBlocklist(item.by);
        // } else {
        //   context.read<BlocklistCubit>().addToBlocklist(item.by);
        // }
        showSnackBar(content: 'User ${isBlocked ? 'unblocked' : 'blocked'}!');
      }
    });
  }

  // void onLoginTapped() {
  //   showDialog<void>(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (BuildContext context) {
  //       return const LoginDialog();
  //     },
  //   );
  // }
}
