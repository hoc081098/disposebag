import 'package:disposebag/disposebag.dart';
import 'dart:async';

void main() async {
  final controller1 = StreamController<int>();
  final controller2 = StreamController<int>();
  final periodic = Stream.periodic(
    const Duration(milliseconds: 100),
    (int i) => i,
  );

  final bag = DisposeBag([
    controller1,
    controller2,
    periodic.listen(controller1.add),
    controller1.stream.listen((i) => print('Periodic $i')),
    controller2.stream.listen((i) => print('Controller2 $i')),
  ]);

  for (var i = 0; i < 100; i++) {
    controller2.add(i);
  }

  /// Delay to see output
  await Future.delayed(const Duration(seconds: 3));

  /// Dispose all stream subscriptions, close all stream controllers
  await bag.dispose();
  print("Bag disposed. It's all good");

  /// Controllers is closed
  print(controller1.isClosed);
  print(controller2.isClosed);

  /// Cannot add event to controllers
  try {
    controller1.add(1);
  } catch (e) {
    print(e);
  }
  try {
    controller2.add(3);
  } catch (e) {
    print(e);
  }

  /// Delay to see output
  await Future.delayed(const Duration(seconds: 2));
  print('Done');
}
