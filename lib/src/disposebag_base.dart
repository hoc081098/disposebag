import 'dart:async';

class DisposeBag {
  final _resources = <dynamic>{}; // <StreamSubscription | Sink>{}
  bool _isDisposed = false;
  bool _isDisposing = false;

  DisposeBag([Iterable<dynamic> disposables = const []]) {
    _addAll(disposables);
  }

  void _addAll(Iterable<dynamic> disposables) {
    for (final item in disposables) {
      _addOne(item);
    }
  }

  /// Add one item to resouces, only add if item is [StreamSubscription] or item is [Sink]
  bool _addOne(dynamic item) {
    if (item == null) {
      return false;
    }

    if (item is StreamSubscription || item is Sink) {
      return _resources.add(item);
    }

    return false;
  }

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

  /// Returns true if this resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Returns the number of currently held Disposables.
  int get length => _isDisposed ? 0 : _resources.length;

  /// Adds a disposable to this container or disposes it if the container has been disposed.
  Future<bool> add(dynamic disposable) async {
    if (_isDisposed || _isDisposing) {
      await _disposeOne(disposable);
      return false;
    } else {
      return _addOne(disposable);
    }
  }

  /// Atomically adds the given array of Disposables to the container or disposes them all if the container has been disposed.
  Future<bool> addAll(Iterable<dynamic> disposables) async {
    if (_isDisposed || _isDisposing) {
      await Future.wait(disposables.map(_disposeOne));
      return false;
    } else {
      _addAll(disposables);
      return true;
    }
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
  Future<void> clear() async {
    if (_isDisposed || _isDisposing) {
      return;
    }

    /// Start dispose
    _isDisposing = true;

    /// Await dispose
    await Future.wait(_resources.map(_disposeOne).where((v) => v != null));

    /// End dispose
    _isDisposing = false;
    _resources.clear();
  }

  /// Dispose the resource, the operation should be idempotent.
  Future<void> dispose() async {
    if (_isDisposed || _isDisposing) {
      return;
    }

    /// Start dispose
    _isDisposing = true;

    /// Await dispose
    final tasks = _resources.map(_disposeOne).where((v) => v != null).toList();
    for (var t in tasks) {
      await t;
    }

    /// End dispose
    _isDisposing = false;
    _isDisposed = true;
  }
}
