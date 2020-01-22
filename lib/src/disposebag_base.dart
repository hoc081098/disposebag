import 'dart:async';

import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

typedef Logger = void Function(Set<dynamic> resources);

void _defaultLogger(Set<dynamic> resources) {
  print(' ↓ Disposed: ');
  print(resources.mapIndexed((i, e) => '   $i → $e').join('\n'));
}

extension _MapIndexedIterableExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) sync* {
    var index = 0;
    for (final item in this) {
      yield mapper(index++, item);
    }
  }
}

/// Class that helps closing sinks and canceling stream subscriptions
class DisposeBag {
  /// Enabled logger
  final bool loggerEnabled;

  /// Logger that logs disposed resources
  final Logger logger;
  final _resources = <dynamic>{}; // <StreamSubscription | Sink>{}
  bool _isDisposed = false;
  bool _isDisposing = false;

  /// Construct a [DisposeBag] with [disposables] iterable
  DisposeBag([
    Iterable<dynamic> disposables = const [],
    this.loggerEnabled = true,
    this.logger = _defaultLogger,
  ])  : assert(loggerEnabled != null),
        assert(logger != null) {
    _addAll(disposables);
  }

  void _addAll(Iterable<dynamic> disposables) {
    for (final item in disposables) {
      _addOne(item);
    }
  }

  /// Add one item to resources, only add if item is [StreamSubscription] or item is [Sink]
  bool _addOne(dynamic item) {
    if (item == null) {
      return false;
    }

    if (item is StreamSubscription || item is Sink) {
      return _resources.add(item);
    }

    return false;
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
      return null;
    }
    return null;
  }

  Future<void> _clear() async {
    if (_isDisposed || _isDisposing) {
      return;
    }

    /// Start dispose
    _isDisposing = true;

    /// Await dispose
    final futures =
        Set.of(_resources).map(_disposeOne).where((future) => future != null);
    await Future.wait(futures);
    if (loggerEnabled) {
      logger(UnmodifiableSetView(_resources));
    }

    /// End dispose
    _isDisposing = false;
    _resources.clear();
  }

  /// Returns true if this resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns the number of currently held Disposables.
  int get length => _resources.length;

  /// Get all disposable
  @visibleForTesting
  Set<dynamic> get disposables => UnmodifiableSetView(_resources);

  /// Adds a disposable to this container or disposes it if the container has been disposed.
  Future<bool> add(dynamic disposable) async {
    if (_isDisposed || _isDisposing) {
      await _disposeOne(disposable);
      return false;
    }
    return _addOne(disposable);
  }

  /// Atomically adds the given array of Disposables to the container or disposes them all if the container has been disposed.
  Future<bool> addAll(Iterable<dynamic> disposables) async {
    if (_isDisposed || _isDisposing) {
      final futures =
          disposables.map(_disposeOne).where((future) => future != null);
      await Future.wait(futures);
      return false;
    }
    _addAll(disposables);
    return true;
  }

  /// Removes and disposes the given disposable if it is part of this container.
  Future<bool> remove(dynamic disposable) async {
    if (await delete(disposable)) {
      await _disposeOne(disposable);
      return true;
    }
    return false;
  }

  /// Removes (but does not dispose) the given disposable if it is part of this container.
  Future<bool> delete(dynamic disposable) async {
    if (_isDisposed || _isDisposing) {
      return false;
    }
    return _resources.remove(disposable);
  }

  /// Atomically clears the container, then disposes all the previously contained Disposables.
  Future<void> clear() => _clear();

  /// Dispose the resource, the operation should be idempotent.
  Future<void> dispose() async {
    await _clear();
    _isDisposed = true;
  }
}
