import 'dart:async';

import 'package:disposebag/disposebag.dart';

List<Object> get _disposables {
  final controllers = <StreamController>[
    StreamController<int>()
      ..add(1)
      ..add(2),
    StreamController<int>(sync: true)
      ..add(3)
      ..add(4),
    StreamController<int>.broadcast()
      ..add(5)
      ..add(6),
    StreamController<String>.broadcast(sync: true)
      ..add('7')
      ..add('8'),
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

  // add & addAll
  await bag.add(Stream.value(1).listen(null));
  await bag.addAll([
    Stream.value(2).listen(null),
    Stream.periodic(const Duration(seconds: 1)).listen(null),
  ]);

  // disposedBy
  await Stream.value(3).listen(null).disposedBy(bag);
  await StreamController<int>.broadcast().disposedBy(bag);
  await StreamController<int>.broadcast(sync: true).disposedBy(bag);

  // await before clearing
  await Future.delayed(const Duration(seconds: 1));
  await bag.clear();
  await bag.clear();
  await bag.clear();

  // adding after clearing
  await Future.delayed(const Duration(seconds: 1));
  await Stream.periodic(const Duration(milliseconds: 100), (i) => i)
      .listen(print)
      .disposedBy(bag);

  // await before disposing
  await Future.delayed(const Duration(seconds: 2));
  await bag.dispose();
  print("Bag disposed: ${bag.isDisposed}. It's all good");
  await Future.delayed(const Duration(seconds: 2));
}
