part of 'ui_actionable_bloc_mixin.dart';

/// Widget that allows to handle [UiActionableBlocMixin]'s actions on the UI level.
///
/// ---
///
/// ### TL;DR
///
/// Whenever [UiActionableBlocMixin.emitUiAction] is executed, [listener] will be called.
/// In [listener] you can perform any UI action: show a bottom sheet, snackbar, perform navigation etc.
/// Optionally, you can even return a result back from [UiActionableBlocMixin.emitUiAction].
///
/// ### How do I use it?
///
/// This widget can be used very similarly to [BlocListener],
/// and it can even be one of the children of a [MultiBlocListener].
///
///  ```dart
///  /// Somewhere in the UI, under the BlocProvider of LoginCubit.
///  @override
///  Widget build(BuildContext context) {
///     // Or add it to the listeners list of a MultiBlocListener
///     return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>(
///       listener: (context, state, action) {
///         final user = action.user;
///         /* Navigate the user further ... */
///       },
///       child: ...,
///     );
///  }
///  ```
///
/// ### Passing the result back to the bloc
///
/// If you'd like to pass the UI result back to the bloc,
/// you can use the [BlocActionsListener.completable] constructor
/// that has a slightly different callback:
///
///  ```dart
///  /// Somewhere in the UI, under the BlocProvider of LoginCubit.
///  @override
///  Widget build(BuildContext context) {
///     return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>(
///       listener: (context, state, action, completeAction) {
///         final loginConfirmation = LoginConfirmationBottomSheet.show(
///           context,
///           forUser: action.user,
///         );
///
///         completeAction(loginConfirmation);
///       },
///       child: ...,
///     );
///  }
///  ```
///
/// ### Does this listener work with [Cubit]s?
///
/// Yes, it works with both [Bloc]s and [Cubit]s.
///
/// ### How is it different from [BlocListener]s?
///
/// [BlocListener]s work with [Bloc.state]s while [BlocActionsListener] listens
/// to actions emitted by [UiActionableBlocMixin.emitUiAction].
final class BlocActionsListener<
    TBloc extends UiActionableBlocMixin<TState, TAction>,
    TState,
    TAction> extends SingleChildStatefulWidget {
  /// Regular constructor, allows to perform UI actions using a callback ([listener]).
  const BlocActionsListener({
    Key? key,
    this.bloc,
    required this.listener,
    super.child,
  })  : completableListener = null,
        super(key: key);

  /// Allows to perform UI actions and pass results back to blocs using a callback ([listener]).
  const BlocActionsListener.completable({
    Key? key,
    this.bloc,
    required BlocCompletableUiActionCallback<TState, TAction> listener,
    super.child,
  })  : listener = null,
        completableListener = listener,
        super(key: key);

  /// A concrete bloc you'd like to listen to. If it is not provided, the widget will
  /// automatically try to find a bloc of the given type using `context.read<TBloc>()`.
  final TBloc? bloc;

  /// Executed on [UiActionableBlocMixin.emitUiAction].
  /// Check out the description of [BlocActionsListener] for detailed documentation.
  final BlocUiActionCallback<TState, TAction>? listener;

  /// Executed on [UiActionableBlocMixin.emitUiAction], allows to complete actions with results.
  /// Check out the description of [BlocActionsListener] for detailed documentation.
  final BlocCompletableUiActionCallback<TState, TAction>? completableListener;

  @override
  State<BlocActionsListener<TBloc, TState, TAction>> createState() =>
      _BlocActionsListenerState<TBloc, TState, TAction>();
}

class _BlocActionsListenerState<
        TBloc extends UiActionableBlocMixin<TState, TAction>, TState, TAction>
    extends SingleChildState<BlocActionsListener<TBloc, TState, TAction>> {
  TBloc? _currentBloc;

  StreamSubscription? _subscription;

  /// Store this list to complete any uncompleted actions
  /// (in case there was a completable listener that never actually completed an action).
  final _actions = <_BlocAction<TAction>>[];

  void _onAction(_BlocAction<TAction> action, TBloc bloc) {
    _actions.add(action);

    final listener = widget.listener;
    if (listener != null) {
      listener(context, bloc.state, action.action);
    }

    final completableListener = widget.completableListener;
    if (completableListener != null) {
      final completer = action.getActionCompleter();
      completableListener(context, bloc.state, action.action, completer);
    }
  }

  /// Is executed whenever a new bloc is provided as a parameter ([didUpdateWidget])
  /// or whenever a dependency changes, e.g. whenever the top level [BlocProvider]
  /// is changed for a reason ([didChangeDependencies]).
  void _onBlocDependencyChanged([TBloc? widgetBloc]) {
    final newBloc = widgetBloc ?? context.read<TBloc>();

    /// Resubscribe only in case the bloc changed.
    if (_currentBloc == newBloc) {
      return;
    }

    _currentBloc = newBloc;

    _subscription?.cancel();
    _subscription =
        newBloc._actionStream.listen((action) => _onAction(action, newBloc));
  }

  @override
  void didUpdateWidget(
    covariant BlocActionsListener<TBloc, TState, TAction> oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    _onBlocDependencyChanged(widget.bloc);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onBlocDependencyChanged();
  }

  @override
  void dispose() {
    for (final action in _actions) {
      if (!action._completer.isCompleted) {
        action.dispose();
      }
    }

    _subscription?.cancel();

    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return child ?? const SizedBox();
  }
}
