import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';

part 'bloc_action.dart';
part 'bloc_actions_listener.dart';
part 'bloc_ui_action_callback.dart';

/// A mixin on [BlocBase] that allows to perform UI actions and get results back
/// right within a bloc.
///
/// Can be used on both [Bloc]s and [Cubit]s.
///
/// ---
///
/// ### TL;DR
///
/// 1. Add the mixin to your [Bloc] or [Cubit]
///
///    ```dart
///    class LoginCubit extends Cubit<LoginCubitState> with UiActionableBlocMixin<LoginCubitState, LoginAction> {
///
///    ...
///    ```
/// 2. Add an action listener to the UI
///
///    ```dart
///    /// Somewhere in the UI, under the BlocProvider of LoginCubit.
///    @override
///    Widget build(BuildContext context) {
///       return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>(
///         listener: (context, state, action) {
///           // Handle the action!
///           // Present a bottom sheet, navigate to another screen etc.
///         },
///         child: ...,
///       );
///    }
///    ```
/// 3. Use [emitUiAction] to... emit an action:
///
///    ```dart
///    Future<void> onLoginButtonTapped() async {
///      try {
///        final user = await _loginUseCase();
///
///        // This will trigger
///        await emitUiAction(LoginAction.navigateHome());
///      } catch (e, s) {
///        // Handle error
///      }
///    }
///    ```
/// 4. If you need to return a result back back to the [emitUiAction], do this
///    ```dart
///    /// Bloc
///    Future<void> onLoginButtonTapped() async {
///      try {
///        final user = await _loginUseCase();
///
///        // Or whatever you need from the UI:
///        final loginConfirmed = await emitUiAction<bool>(LoginAction.confirmLogin(user));
///
///        // Do something with the result!
///      } catch (e, s) {
///        // Handle error
///      }
///    }
///
///    /// Somewhere in the UI, under the BlocProvider of LoginCubit.
///    @override
///    Widget build(BuildContext context) {
///       return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>(
///         listener: (context, state, action, actionCompleter) {
///           final loginConfirmation = await LoginConfirmationBottomSheet.show(
///             context,
///             forUser: action.user,
///           );
///
///           // This will complete the emitUiAction future.
///           actionCompleter(loginConfirmation);
///         },
///         child: ...,
///       );
///    }
///    ```
mixin UiActionableBlocMixin<TState, TAction> on BlocBase<TState> {
  final StreamController<_BlocAction<TAction>> _controller =
      StreamController<_BlocAction<TAction>>.broadcast();

  Stream<_BlocAction<TAction>> get _actionStream => _controller.stream;

  /// Emits an action that can be handled on the UI layer.
  /// Use [BlocActionsListener] for handling this action on the UI layer.
  Future<TResult?> emitUiAction<TResult>(TAction action) async {
    if (isClosed) {
      assert(false, 'Cannot emit UI actions after bloc\'s closure!');
      return null;
    }

    final blocAction = _BlocAction<TAction>(action);

    _controller.add(blocAction);

    /// We have to wait until the next microtask is completed so the UI can
    /// get the actionCompleter.
    /// If it didn't happen, the future will just be resolved immediately
    /// with a null result.
    await Future.delayed(Duration.zero);

    if (!blocAction._isCompleterRequested) {
      /// If no completable listener is there, just dispose the action and exit
      /// (regular listeners will still be able to handle action).
      blocAction.dispose();
      return null;
    }

    final result = await blocAction._completer.future;

    if (result == null) {
      return null;
    }

    if (result is! TResult) {
      assert(
        false,
        'The return type of this action was not a ${TResult.runtimeType}, but ${result.runtimeType}',
      );
      return null;
    }

    return result;
  }

  @override
  Future<void> close() {
    _controller.close();
    return super.close();
  }
}
