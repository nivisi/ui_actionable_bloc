part of 'ui_actionable_bloc_mixin.dart';

/// Typedef for the callback of [BlocActionsListener.listener].
typedef BlocUiActionCallback<TState, TAction> = void Function(
  BuildContext context,
  TState state,
  TAction action,
);

/// Typedef for the callback of [BlocCompletableActionsListener.listener].
typedef BlocCompletableUiActionCallback<TState, TAction> = void Function(
  BuildContext context,
  TState state,
  TAction action,
  void Function(dynamic result) completeAction,
);
