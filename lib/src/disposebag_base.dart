import 'dart:async';

class DisposeBag {
  final List<dynamic> _list = [];
  bool _isDisposed = false;
  bool _isDisposing = false;

  DisposeBag([List<dynamic> disposables = const []]) {
    _addAll(disposables);
  }

  void _addAll(List disposables) {
    for (final item in disposables) {
      _addOne(item);
    }
  }

  void _addOne(item) {
    if (item is StreamSubscription || item is Sink) {
      _list.add(item);
    }
  }

  Future<dynamic> _disposeOne(dynamic disposable) async {
    if (disposable is StreamSubscription) {
      return disposable.cancel();
    }
    if (disposable is StreamSink) {
      return disposable.close();
    }
    if (disposable is Sink) {
      disposable.close();
    }
    return null;
  }

  /// Dispose the resource, the operation should be idempotent.
  Future<void> dispose() async {
    if (_isDisposed || _isDisposing) {
      return;
    }

    /// Start dispose
    _isDisposing = true;

    /// Await dispose
    await Future.wait(_list.map(_disposeOne).where((v) => v != null));

    /// End dispose
    _isDisposing = false;
    _isDisposed = true;
  }

  /// Returns true if this resource has been disposed.
  bool get isDisposed => _isDisposed;

  /// Adds a disposable to this container or disposes it if the container has been disposed.
  Future<bool> add(dynamic disposable) async {
    if (_isDisposed || _isDisposing) {
      await _disposeOne(disposable);
      return false;
    } else {
      _addOne(disposable);
      return true;
    }
  }

  /// Atomically adds the given array of Disposables to the container or disposes them all if the container has been disposed.
  Future<bool> addAll(List<dynamic> disposables) async {
    if (_isDisposed || _isDisposing) {
      await Future.wait(disposables.map(_disposeOne));
      return false;
    } else {
      _addAll(disposables);
      return true;
    }
  }

  Future<void> clear() async {
    if (_isDisposed || _isDisposing) {
      return;
    }

    /// Start dispose
    _isDisposing = true;

    /// Await dispose
    await Future.wait(_list.map(_disposeOne).where((v) => v != null));

    /// End dispose
    _isDisposing = false;
    _list.clear();
  }
}
