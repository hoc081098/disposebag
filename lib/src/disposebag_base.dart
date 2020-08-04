import 'dart:async';

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

/// Represents the result of disposing or clearing.
enum BagResult {
  /// Disposed successfully.
  disposedSuccess,

  /// Cleared successfully.
  clearedSuccess,

  /// Disposed unsuccessfully.
  disposedFailure,

  /// Cleared unsuccessfully.
  clearedFailure,
}

/// Logs the result of disposing or clearing.
/// By default, prints the result to the console.
typedef Logger = void Function(
  BagResult result,
  Set<dynamic> resources, [
  Object error,
  StackTrace stackTrace,
]);

void _defaultLogger(
  BagResult result,
  Set<dynamic> resources, [
  Object? error,
  StackTrace? stackTrace,
]) {
  switch (result) {
    case BagResult.disposedSuccess:
      print(' ↓ Disposed successfully: ');
      break;
    case BagResult.clearedSuccess:
      print(' ↓ Cleared successfully: ');
      break;
    case BagResult.disposedFailure:
      print(' ↓ Disposed unsuccessfully: ');
      print('    → Error: ${error!}');
      if (stackTrace != null) {
        print('    → StackTrace: $stackTrace');
      }
      break;
    case BagResult.clearedFailure:
      print(' ↓ Cleared unsuccessfully: ');
      print('    → Error: ${error!}');
      if (stackTrace != null) {
        print('    → StackTrace: $stackTrace');
      }
      break;
  }

  print(resources.mapIndexed((i, e) => '   $i → $e').join('\n'));
}

class _Pair<T, R> {
  final T first;
  final R second;

  const _Pair(this.first, this.second);
}

extension _MapIndexedIterableExtension<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) sync* {
    var index = 0;
    for (final item in this) {
      yield mapper(index++, item);
    }
  }
}

extension _WhereNotNullIterableExtension<T> on Iterable<T?> {
  Iterable<T> whereNotNull() sync* {
    for (final item in this) {
      if (item != null) {
        yield item;
      }
    }
  }
}

enum _Operation { clear, dispose }

extension on _Operation {
  BagResult toResult({
    Object? error,
    StackTrace? stackTrace,
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

/// Class that helps closing sinks and canceling stream subscriptions
class DisposeBag {
  /// Enabled logger
  final bool loggerEnabled;

  /// Logger that logs disposed resources
  final Logger? logger;
  final _resources = <dynamic>{}; // <StreamSubscription | Sink>{}
  bool _isDisposed = false;
  bool _isDisposing = false;

  /// Construct a [DisposeBag] with [disposables] iterable
  DisposeBag([
    Iterable<dynamic> disposables = const [],
    this.loggerEnabled = true,
    this.logger = _defaultLogger,
  ]) {
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
  Future<dynamic>? _disposeOne(dynamic disposable) {
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

  Future<bool> _clear(_Operation _operation) async {
    if (_isDisposed || _isDisposing) {
      return false;
    }

    /// Start dispose
    _isDisposing = true;

    try {
      /// Await dispose
      final pairs = _resources
          .map((r) => _Pair(_disposeOne(r), r))
          .where((pair) => pair.first != null)
          .toList(growable: false);

      final futures = pairs.map((pair) => pair.first!);
      await Future.wait(futures);

      _resources.clear();

      if (loggerEnabled) {
        final resources = pairs.map((pair) => pair.second).toSet();
        logger?.call(_operation.toResult(), UnmodifiableSetView(resources));
      }

      return true;
    } catch (e, s) {
      if (loggerEnabled) {
        logger?.call(_operation.toResult(error: e, stackTrace: s), disposables);
      }
      return false;
    } finally {
      /// End dispose
      _isDisposing = false;
    }
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
      final futures = disposables.map(_disposeOne).whereNotNull();
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
  Future<bool> clear() => _clear(_Operation.clear);

  /// Dispose the resource, the operation should be idempotent.
  Future<bool> dispose() async {
    final result = await _clear(_Operation.dispose);
    if (result) {
      _isDisposed = true;
    }
    return result;
  }
}
