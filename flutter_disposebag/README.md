# flutter_disposebag

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

[![Pub](https://img.shields.io/pub/v/flutter_disposebag)](https://pub.dev/packages/flutter_disposebag)

*   A package to help disposing Streams and closing Sinks easily for Flutter.
*   Automatically disposes `StreamSubscription` and closes `Sink` when disposing `State<T>`.

## Usage

A simple usage example:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with DisposeBagMixin {
  final controller = StreamController<int>();

  @override
  void initState() {
    super.initState();

    Stream.periodic(const Duration(milliseconds: 500), (i) => i)
        .listen((event) {})
        .disposedBy(bag);

    controller.stream.listen((event) {}).disposedBy(bag);
    controller.disposedBy(bag);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/disposebag/issues/new
