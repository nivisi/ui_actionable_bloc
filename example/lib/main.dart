import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_actionable_bloc/ui_actionable_bloc.dart';

void main() {
  runApp(const UiActionableBlocExample());
}

class MyCubit extends Cubit<MyState>
    with UiActionableBlocMixin<MyState, MyAction> {
  MyCubit() : super(MyState());

  Future<void> onButtonPressed() async {
    const action = MyAction(['First', 'Second', 'Third']);
    final result = emitUiAction<String>(action);

    debugPrint('Cubit: $result');
  }
}

class MyState {}

class MyAction {
  const MyAction(this.options);

  final List<String> options;
}

class UiActionableBlocExample extends StatelessWidget {
  const UiActionableBlocExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: BlocProvider(
        create: (context) => MyCubit(),
        child: Scaffold(
          appBar: AppBar(),
          body: Column(
            children: [
              const Center(
                child: Text('Hello World!'),
              ),
              MultiBlocListener(
                listeners: [
                  BlocActionsListener<MyCubit, MyState, MyAction>.completable(
                    listener: (context, state, action, completer) async {
                      final availableActions = action.options
                          .map(
                            (e) => CupertinoActionSheetAction(
                              onPressed: () {
                                Navigator.of(context).pop(e);
                              },
                              child: Text(e),
                            ),
                          )
                          .toList();

                      final result = await showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return CupertinoActionSheet(
                            title: const Text('Select'),
                            actions: availableActions,
                          );
                        },
                      );

                      completer(result);
                    },
                  ),
                ],
                child: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: context.read<MyCubit>().onButtonPressed,
                      child: const Text('Press me!'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
