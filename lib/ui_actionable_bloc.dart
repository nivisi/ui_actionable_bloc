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
///    class LoginCubit extends Cubit<LoginState> with UiActionableBlocMixin<LoginState, LoginAction> {
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
///        await emitUiAction(LoginAction.navigateHome());
///      } catch (e, s) {
///        // Handle error
///      }
///    }
///    ```
/// 4. If you need to return a result back back to the [emitUiAction], do this
///    ```dart
///    /// Bloc
///    Future<void> login() async {
///      try {
///        final user = await _loginUseCase();
///
///        // Or whatever you need from the UI:
///        final loginConfirmed = await emitUiAction(LoginAction.confirmLogin(user));
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
///       return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>.completable(
///         listener: (context, state, action, actionCompleter) {
///           final loginConfirmation = await LoginConfirmationBottomSheet.show(context, forUser: action.user);
///
///           // This will resolve the emitUiAction future.
///           actionCompleter(loginConfirmation);
///         },
///         child: ...,
///       );
///    }
///    ```
library ui_actionable_bloc;

import 'package:flutter_bloc/flutter_bloc.dart';

export 'src/ui_actionable_bloc_mixin.dart'
    hide BlocUiActionCallback, BlocCompletableUiActionCallback;
