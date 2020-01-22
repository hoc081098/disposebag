# disposebag

### Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Pub](https://img.shields.io/pub/v/disposebag)
[![codecov](https://codecov.io/gh/hoc081098/disposebag/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/disposebag)
[![Build Status](https://travis-ci.org/hoc081098/disposebag.svg?branch=master)](https://travis-ci.org/hoc081098/disposebag)

A package to help disposing Streams and closing Sinks

## Usage

A simple usage example:

```dart
import 'package:disposebag/disposebag.dart';
import 'dart:async';

main() async {
  final controllers = <StreamController>[];
  final subscriptions = <StreamSubscription>[];
 
  final bag = DisposeBag([...subscriptions, ...controllers]);
  await bag.dispose();
  
  print("Bag disposed. It's all good");
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/disposebag/issues/new
