# ui_actionable_bloc [![pub version][pub-version-img]][pub-version-url]

🎬 A mixin on [`Bloc`](https://pub.dev/packages/bloc) that allows to perform UI actions and get results back.

## Getting started

### Install the package

```yaml
dependencies:
  ui_actionable_bloc: ^1.0.0
```

### Add the mixin

```dart
class LoginCubit extends Cubit<LoginCubitState> with UiActionableBlocMixin<LoginCubitState, LoginAction> {

...

}
```

### Add a listener

```dart
/// Somewhere in the UI, under the BlocProvider of LoginCubit:
@override
Widget build(BuildContext context) {
  return BlocActionsListener<LoginCubit, LoginCubitState, LoginAction>(
    listener: (context, state, action) {
      // Handle LoginAction here!
    },
    child: ...,
  );
}
```
### Emit actions!

```dart
Future<void> login() async {
  try {
    final user = await _loginUseCase();

    await emitUiAction(LoginAction.navigateHome(user));
    // This 👆 will trigger the `listener` callback from above.
  } catch (e, s) {
    // Handle error
  }
}
```

## Passing the result back to the Bloc

You can pass the result of the UI action back to the Bloc. For example, you can show an OTP pop up or a new route with text input after sending an OTP:

1. Await the result of `emitUiAction`:
   ```dart
   await _sendOtpUseCase();

   // Otp will land here once the action is completed in a listener!
   final otp = await emitUiAction(OtpAction.requestOtpInput(user));

   if (otp is! String) {
     /// User did not input the OTP.
     return;
   }

   await _validateOtpUseCase(otp);
   ```
2. Use `BlocActionsListener.completable` that has a slightly different `listener` callback:

   ```dart
   @override
   Widget build(BuildContext context) {
     return BlocActionsListener<OtpCubit, OtpCubitState, OtpAction>.completable(
       listener: (context, state, action, actionCompleter) {
         final otpInput = await Navigator.of(context).push(OtpInputRoute());

         // This will complete the emitUiAction future.
         actionCompleter(otpInput);
       },
       child: ...,
     );
   }
   ```

## FAQ

### Why?

Sometimes we need to perform a UI action in the middle of a Bloc method. For example, get user input, like an OTP code after sending an SMS. Usually `BlocListener`s help us with this. We listen to a change in the state and, based on certain condition, we perform a UI action. We need several methods to do this: one for triggering an OTP, another for completing the flow after the OTP is entered.

However, it is not always convenient. What do we do with the data in the state after a UI action is performed? What if it will be accessed after a UI action is performed? Do we need to clear it beforehand or let it remain there? It is unclear because these actions depend on the same data that is used by the UI.

Although it can be resolved with one-time UI Actions.

### Does it work with Cubits?

Yes, it works with both `Bloc`s and `Cubit`s.

### How is `BlocActionsListener` different from `BlocListener`s?

`BlocListener`s work with `Bloc.state`s while `BlocActionsListener` listens to actions emitted by `emitUiAction`.

### Where do I put a `BlocActionsListener`?

`BlocActionsListener` can be used in the same way as regular `BlocListener`s are used. You can even add `BlocActionsListener`s to a `MultiBlocListener`.

### What if I don't complete an emitted action?

For regular `BlocActionsListener`, you don't have to worry about completing an action. It `emitUiAction` is immediately completed with a `null` in this case. For `BlocActionsListener.completable` though, make sure you complete your action with some result. Otherwise it will be stuck.

Actions received by a `BlocActionsListener` will be automatically completed when this listener is disposed.

<!-- References -->
[pub-version-img]: https://img.shields.io/badge/pub-v1.0.0-0175c2?logo=flutter
[pub-version-url]: https://pub.dev/packages/ui_actionable_bloc
