import 'package:disposebag/disposebag.dart';
import 'dart:async';

List<dynamic> get _disposables {
  final controllers = <StreamController>[
    StreamController<int>()..add(1)..add(2),
    StreamController<int>(sync: true)..add(3)..add(4),
    StreamController<int>.broadcast()..add(5)..add(6),
    StreamController<String>.broadcast(sync: true)..add('7')..add('8'),
  ];
  final subscriptions = <StreamSubscription>[
    Stream.periodic(const Duration(milliseconds: 100), (i) => i)
        .listen((data) => print('[1] $data')),
    Stream.periodic(const Duration(milliseconds: 10), (i) => i)
        .listen((data) => print('[2] $data')),
    for (int i = 0; i < controllers.length; i++)
      controllers[i].stream.listen((data) => print('[${i + 3}] $data')),
  ];
  return [...controllers, ...subscriptions];
}

void main() async {
  final bag = DisposeBag(_disposables);
  await Future.delayed(const Duration(seconds: 2));
  await bag.dispose();

  await Future.delayed(const Duration(seconds: 2));
  print("Bag disposed. It's all good");
}
