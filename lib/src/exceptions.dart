import '../disposebag.dart';

/// Bag was disposed.
class DisposedException implements Exception {
  /// Reference to [DisposeBag].
  final DisposeBag bag;

  /// Construct a [DisposedException] with [bag].
  DisposedException(this.bag);

  @override
  String toString() => '$bag was disposed, try to use new instance instead';
}

/// Bag is clearing.
class ClearingException implements Exception {
  /// Reference to [DisposeBag].
  final DisposeBag bag;

  /// Construct a [ClearingException] with [bag].
  ClearingException(this.bag);

  @override
  String toString() => '$bag is clearing, try to await it done';
}
