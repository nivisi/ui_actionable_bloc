part of 'ui_actionable_bloc_mixin.dart';

/// A helper that uses a [Completer]
/// to provide results to the [UiActionableBlocMixin.emitUiAction] method.
final class _BlocAction<TAction> {
  _BlocAction(this.action);

  final TAction action;

  final Completer _completer = Completer();

  /// Indicated whether [getActionCompleter] was already called earlier, for example,
  /// by another [BlocActionsListener] in the widget tree.
  bool _isCompleterRequested = false;

  /// This is the handler that the UI receives from the [BlocUiActionCallback.getActionCompleter] method.
  void _actionCompleter(dynamic result) {
    if (_completer.isCompleted) {
      /// Warn devs that actionCompleter is executed more than once.
      assert(false, 'Completer was already completed');
      return;
    }

    _completer.complete(result);
  }

  /// Returns a callback that can complete the [_completer].
  void Function(dynamic result) getActionCompleter() {
    assert(
      !_isCompleterRequested,
      'Subscribing to action actionCompleter twice can potentially lead to bugs since a completer cannot be completed more than once.',
    );

    _isCompleterRequested = true;

    return _actionCompleter;
  }

  /// Completes the completer with a null result in case it wasn't completed earlier.
  void dispose() {
    if (_completer.isCompleted) {
      return;
    }

    getActionCompleter()(null);
  }
}
