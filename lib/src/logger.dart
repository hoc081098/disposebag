import 'package:collection/collection.dart' show IterableExtension;

import 'disposebag.dart';

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
  DisposeBag bag,
  BagResult result,
  Set<dynamic> resources, [
  Object? error,
  StackTrace? stackTrace,
]);

/// Default `DisposeBag` logger
final Logger defaultLogger = (bag, result, resources, [error, stackTrace]) {
  switch (result) {
    case BagResult.disposedSuccess:
      print(' ↓ Disposed successfully → $bag: ');
      break;
    case BagResult.clearedSuccess:
      print(' ↓ Cleared successfully → $bag: ');
      break;
    case BagResult.disposedFailure:
      print(' ↓ Disposed unsuccessfully → $bag: ');
      print('    → Error: $error');
      print('    → StackTrace: $stackTrace');
      break;
    case BagResult.clearedFailure:
      print(' ↓ Cleared unsuccessfully → $bag: ');
      print('    → Error: $error');
      print('    → StackTrace: $stackTrace');
      break;
  }

  print(resources.mapIndexed((i, e) => '   $i → $e').join('\n'));
};
