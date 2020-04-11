import 'dart:async';

import 'package:disposebag/src/disposebag_base.dart';

///
extension StreamSubscriptionDisposedByExtension<T> on StreamSubscription<T> {
  ///
  Future<bool> disposedBy(DisposeBag bag) => bag.add(this);
}

///
extension SinkDisposedByExtension<T> on Sink<T> {
  ///
  Future<bool> disposedBy(DisposeBag bag) => bag.add(this);
}
