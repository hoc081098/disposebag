import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart';

/// An command object representing the invocation of a named method.
@immutable
class MethodCall {
  /// Creates a [MethodCall] representing the invocation of [method] with the
  /// specified [arguments].
  const MethodCall(this.method, [this.arguments]);

  /// The name of the method to be called.
  final String method;

  /// The arguments for the method.
  ///
  /// Must be a valid value for the [MethodCodec] used.
  final dynamic arguments;

  @override
  String toString() => 'MethodCall{method: $method, arguments: $arguments}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MethodCall &&
          runtimeType == other.runtimeType &&
          method == other.method &&
          arguments == other.arguments;

  @override
  int get hashCode => method.hashCode ^ arguments.hashCode;
}

mixin MethodCallsMixin on Object {
  final trueFuture = Future.value(true);

  final calls = <MethodCall>[];

  MethodCall get call => calls.single;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDisposeBag with MethodCallsMixin implements DisposeBag {
  @override
  Future<bool> add(disposable) {
    calls.add(MethodCall('add', disposable));
    return trueFuture;
  }

  @override
  Future<bool> addAll(Iterable disposables) {
    calls.add(MethodCall('addAll', disposables));
    return trueFuture;
  }

  @override
  Future<bool> dispose() {
    calls.add(const MethodCall('dispose'));
    return trueFuture;
  }
}

class MockSink with MethodCallsMixin implements Sink<int> {
  @override
  Future<void> close() {
    calls.add(const MethodCall('close'));
    return trueFuture;
  }
}

class MockStreamSubscription
    with MethodCallsMixin
    implements StreamSubscription<int> {
  Future<void> Function()? whenCancel;

  @override
  Future<void> cancel() {
    calls.add(const MethodCall('cancel'));
    return whenCancel?.call() ?? trueFuture;
  }
}
