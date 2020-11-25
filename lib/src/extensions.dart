import 'dart:async';

import 'disposebag.dart';

/// [disposedBy] extension method for [StreamSubscription]
extension StreamSubscriptionDisposedByExtension<T> on StreamSubscription<T> {
  /// Adds this `StreamSubscription` to bag
  /// or cancel it if the bag has been disposed.
  Future<bool> disposedBy(DisposeBag bag) => bag.add(this);
}

/// [disposedBy] extension method for [Sink]
extension SinkDisposedByExtension<T> on Sink<T> {
  /// Adds this `Sink` to bag
  /// or close it if the bag has been disposed.
  Future<bool> disposedBy(DisposeBag bag) => bag.add(this);
}

/// [disposedBy] extension method for [Iterable] of [StreamSubscription]s
extension StreamSubscriptionIterableDisposedByExtension<T>
    on Iterable<StreamSubscription<T>> {
  /// Adds this `StreamSubscription`s to bag
  /// or cancel it if the bag has been disposed.
  Future<bool> disposedBy(DisposeBag bag) => bag.addAll(this);
}

/// [disposedBy] extension method for [Iterable] of [Sink]s
extension SinkIterableDisposedByExtension<T> on Iterable<Sink<T>> {
  /// Adds this `Sink`s to bag
  /// or close it if the bag has been disposed.
  Future<bool> disposedBy(DisposeBag bag) => bag.addAll(this);
}
