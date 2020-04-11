import 'dart:async';

import 'package:disposebag/src/disposebag_base.dart';

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
