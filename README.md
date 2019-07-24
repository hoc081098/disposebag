A library for Dart developers.

Created from templates made available by Stagehand under a BSD-style
[license](https://github.com/dart-lang/stagehand/blob/master/LICENSE).

## Usage

A simple usage example:

```dart
import 'package:disposebag/disposebag.dart';
import 'dart:async';

main() async {
  final controller1 = StreamController<int>();
  final controller2 = StreamController<int>();
  final periodict = Stream.periodic(
    const Duration(milliseconds: 100),
    (int i) => i,
  );

  // Create dispose bag with diposables list
  final bag = DisposeBag([
    controller1,
    controller2,
  ]);

  // Add single subscription
  bag.add(periodict.listen(controller1.add));

  // Add many 
  bag.addAll([
    controller1.stream.listen(print),
    controller2.stream.listen(print),
  ]);

  await bag.dispose();
  print("Bag disposed. It's all good");
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/disposebag/issues/new
