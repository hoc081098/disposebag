import 'package:meta/meta.dart';

import 'exceptions.dart';

/// DisposeBag base interface.
abstract class DisposeBagBase {
  //
  // State of bag.
  //

  /// Returns true if this bag has been disposed.
  bool get isDisposed;

  /// Returns true if this bag is clearing.
  bool get isClearing;

  /// Returns the number of currently held Disposables.
  /// Return `0` if this bag has been disposed or is disposing.
  int get length;

  /// Gets all disposable or empty set if this bag has been disposed or is disposing.
  @visibleForTesting
  Set<Object> get disposables;

  //
  // Add methods.
  //

  /// Adds a disposable to this container or disposes it if this bag has been disposed or is disposing.
  ///
  /// [disposable] must be a [StreamSubscription] or a [Sink].
  ///
  /// Returns true if [disposable] was added successfully.
  Future<bool> add(Object disposable);

  /// Atomically adds the given iterable of Disposables to this bag
  /// or disposes them all if this bag has been disposed or is disposing.
  ///
  /// [disposables] must be an [Iterable] of [StreamSubscription]s or a [Sink]s.
  Future<void> addAll(Iterable<Object> disposables);

  //
  // Remove methods.
  //

  /// Removes and **disposes** the given disposable if it is part of this container.
  ///
  /// [disposable] must be a [StreamSubscription] or a [Sink].
  ///
  /// Returns a [Future] completes with `true` if [disposable] was in this bag, and `false` if not.
  /// The method has no effect if [disposable] was not in this bag.
  /// See [DisposeBagBase.delete].
  ///
  /// Throws [DisposedException] or [ClearingException] if this bag has been disposed or is disposing.
  Future<bool> remove(Object disposable);

  /// Removes **(but does not dispose)** the given disposable if it is part of this container.
  ///
  /// [disposable] must be a [StreamSubscription] or a [Sink].
  ///
  /// Returns `true` if [disposable] was in this bag, and `false` if not.
  /// The method has no effect if [disposable] was not in this bag.
  ///
  /// Throws [DisposedException] or [ClearingException] if this bag has been disposed or is disposing.
  bool delete(Object disposable);

  //
  // Clear and dispose.
  //

  /// Atomically clears the container, then disposes all the previously contained Disposables.
  /// This method can be called multiple times.
  ///
  /// Throws [DisposedException] or [ClearingException] if this bag has been disposed or is disposing.
  Future<void> clear();

  /// Dispose the resource, the operation should be called once time.
  ///
  /// Throws [DisposedException] or [ClearingException] if this bag has been disposed or is disposing.
  Future<void> dispose();
}
