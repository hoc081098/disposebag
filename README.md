# disposebag

## Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)

![Dart CI](https://github.com/hoc081098/disposebag/workflows/Dart%20CI/badge.svg)
[![Codacy Badge](https://api.codacy.com/project/badge/Grade/335930f9b71d4564b5523ccc788663f9)](https://app.codacy.com/manual/hoc081098/disposebag?utm_source=github.com&utm_medium=referral&utm_content=hoc081098/disposebag&utm_campaign=Badge_Grade_Dashboard)
[![Pub](https://img.shields.io/pub/v/disposebag)](https://pub.dev/packages/disposebag)
[![Pub](https://img.shields.io/pub/v/disposebag?include_prereleases)](https://pub.dev/packages/disposebag)
[![codecov](https://codecov.io/gh/hoc081098/disposebag/branch/master/graph/badge.svg)](https://codecov.io/gh/hoc081098/disposebag)
[![Build Status](https://travis-ci.org/hoc081098/disposebag.svg?branch=master)](https://travis-ci.org/hoc081098/disposebag)
[![GitHub](https://img.shields.io/github/license/hoc081098/disposebag?color=4EB1BA)](https://opensource.org/licenses/MIT)
[![Style](https://img.shields.io/badge/style-pedantic-40c4ff.svg)](https://github.com/dart-lang/pedantic)

A package helps to cancel StreamSubscriptions and close Sinks.

## Usage

A simple usage example:

```dart
import 'package:disposebag/disposebag.dart';
import 'dart:async';

main() async {
  final controllers = <StreamController>[];
  final subscriptions = <StreamSubscription>[];

  final bag = DisposeBag([...subscriptions, ...controllers]);

  await Stream.value(3).listen(null).disposedBy(bag);
  await StreamController<int>.broadcast().disposedBy(bag);
  await StreamController<int>.broadcast(sync: true).disposedBy(bag);

  await bag.dispose();
  print("Bag disposed. It's all good");
}
```

### API

## 1. Add, addAll

```dart
Future<bool> DisposeBag.add(StreamSubscription);
Future<bool> DisposeBag.add(Sink);
Future<void> DisposeBag.addAll(Iterable<StreamSubscription>);
Future<void> DisposeBag.addAll(Iterable<Sink>);

// extension methods
Future<bool> StreamSubscription.disposedBy(DisposeBag);
Future<bool> Sink.disposedBy(DisposeBag);
Future<void> Iterable<StreamSubscription>.disposedBy(DisposeBag);
Future<void> Iterable<Sink>.disposedBy(DisposeBag);
```

## 2. Delete (removes but does not dispose)

```dart
bool delete(StreamSubscription);
bool delete(Sink);
```

## 3. Remove (removes and disposes)

```dart
Future<bool> remove(StreamSubscription);
Future<bool> remove(Sink);
```

## 4. Clear, dispose

```dart
Future<void> clear();
Future<void> dispose();
```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/hoc081098/disposebag/issues/new
