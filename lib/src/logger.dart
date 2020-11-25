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

/// Default `DisposeBag` logger
final Logger defaultLogger = (result, resources, [error, stackTrace]) {
  switch (result) {
    case BagResult.disposedSuccess:
      print(' ↓ Disposed successfully: ');
      break;
    case BagResult.clearedSuccess:
      print(' ↓ Cleared successfully: ');
      break;
    case BagResult.disposedFailure:
      print(' ↓ Disposed unsuccessfully: ');
      print('    → Error: $error');
      print('    → StackTrace: $stackTrace');
      break;
    case BagResult.clearedFailure:
      print(' ↓ Cleared unsuccessfully: ');
      print('    → Error: $error');
      print('    → StackTrace: $stackTrace');
      break;
  }

  print(resources.mapIndexed((i, e) => '   $i → $e').join('\n'));
};

extension _IterableExtensions<T> on Iterable<T> {
  Iterable<R> mapIndexed<R>(R Function(int, T) mapper) sync* {
    var index = 0;
    for (final item in this) {
      yield mapper(index++, item);
    }
  }
}
