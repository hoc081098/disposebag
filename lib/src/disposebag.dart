import 'dart:async' show Future, StreamSink, StreamSubscription;

import 'package:collection/collection.dart' show UnmodifiableSetView;
import 'package:meta/meta.dart' show visibleForTesting;

import 'logger.dart' show BagResult, defaultLogger;

enum _Operation { clear, dispose }

extension on _Operation {
  // ignore: missing_return
  BagResult toResultWith({
    Object error,
    StackTrace stackTrace,
  }) {
    if (error == null && stackTrace == null) {
      switch (this) {
        case _Operation.clear:
          return BagResult.clearedSuccess;
        case _Operation.dispose:
          return BagResult.disposedSuccess;
      }
    } else {
      switch (this) {
        case _Operation.clear:
          return BagResult.clearedFailure;
        case _Operation.dispose:
          return BagResult.disposedFailure;
      }
    }
  }
}

void _guardType(dynamic disposable) {
  if (disposable == null) {
    throw ArgumentError.notNull('disposable');
  }
  if (!(disposable is StreamSubscription || disposable is Sink)) {
    throw ArgumentError.value(
        disposable, 'disposable', 'must be a StreamSubscription or a Sink');
  }
}

void _guardTypeMany(Iterable<dynamic> disposable) =>
    disposable.forEach(_guardType);

/// Class that helps closing sinks and canceling stream subscriptions
class DisposeBag {
  static final _nullFuture = Future<void>.value(null);

  /// Logger that logs disposed resources
  static var logger = defaultLogger;

  final _resources = <dynamic>{}; // <StreamSubscription | Sink>{}
  bool _isDisposed = false;
  bool _isDisposing = false;

  /// Construct a [DisposeBag] with [disposables] iterable
  DisposeBag([Iterable<dynamic> disposables = const []])
      : assert(disposables != null) {
    _guardTypeMany(disposables);
    _resources.addAll(disposables);
  }

  /// Cancel [StreamSubscription] or close [Sink]
  Future<dynamic> _disposeOne(dynamic disposable) {
    if (disposable is StreamSubscription) {
      return disposable.cancel();
    }
    if (disposable is StreamSink) {
      return disposable.close();
    }
    if (disposable is Sink) {
      disposable.close();
    }
    return _nullFuture;
  }

  Future<void> _disposeByType<T>() {
    final futures = [
      for (final r in _resources)
        if (r is T) _disposeOne(r)
    ];

    if (futures.isEmpty) {
      return _nullFuture;
    }
    if (futures.length == 1) {
      return futures[0];
    }
    return Future.wait(futures, eagerError: true);
  }

  Future<bool> _clear(_Operation operation) async {
    if (_isDisposed || _isDisposing) {
      return false;
    }
    _isDisposing = true;

    try {
      await _disposeByType<StreamSubscription>();
      await _disposeByType<Sink>();

      logger?.call(
        operation.toResultWith(),
        UnmodifiableSetView(_resources),
      );

      _resources.clear();
      if (operation == _Operation.dispose) {
        _isDisposed = true;
      }

      return true;
    } catch (e, s) {
      logger?.call(
        operation.toResultWith(error: e, stackTrace: s),
        UnmodifiableSetView(_resources),
        e,
        s,
      );
      return false;
    } finally {
      _isDisposing = false;
    }
  }

  /// Returns true if this resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns the number of currently held Disposables.
  int get length => _resources.length;

  /// Get all disposable
  @visibleForTesting
  Set<dynamic> get disposables => UnmodifiableSetView({..._resources});

  /// Adds a disposable to this container or disposes it if the container has been disposed.
  Future<bool> add(dynamic disposable) async {
    _guardType(disposable);

    if (_isDisposed || _isDisposing) {
      await _disposeOne(disposable);
      return false;
    }

    return _resources.add(disposable);
  }

  /// Atomically adds the given array of Disposables to the container or disposes them all if the container has been disposed.
  Future<bool> addAll(Iterable<dynamic> disposables) async {
    _guardTypeMany(disposables);

    if (_isDisposed || _isDisposing) {
      await Future.wait(disposables.map(_disposeOne));
      return false;
    }

    _resources.addAll(disposables);
    return true;
  }

  /// Removes and disposes the given disposable if it is part of this container.
  Future<bool> remove(dynamic disposable) async {
    _guardType(disposable);

    if (await delete(disposable)) {
      await _disposeOne(disposable);
      return true;
    }

    return false;
  }

  /// Removes (but does not dispose) the given disposable if it is part of this container.
  Future<bool> delete(dynamic disposable) async {
    _guardType(disposable);

    if (_isDisposed || _isDisposing) {
      return false;
    }

    return _resources.remove(disposable);
  }

  /// Atomically clears the container, then disposes all the previously contained Disposables.
  Future<bool> clear() => _clear(_Operation.clear);

  /// Dispose the resource, the operation should be idempotent.
  Future<bool> dispose() => _clear(_Operation.dispose);
}
