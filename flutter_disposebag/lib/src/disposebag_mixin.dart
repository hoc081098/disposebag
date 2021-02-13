import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// A mixin that provides the [DisposeBag] that helps disposing Streams and closing Sinks.
@optionalTypeArgs
mixin DisposeBagMixin<T extends StatefulWidget> on State<T> {
  Completer<bool>? _mockBagDisposed;

  /// Set mock [DisposeBag] for testing purpose.
  /// Returns a [Future] that completes when [DisposeBag.dispose] completes.
  @visibleForTesting
  Future<bool> setMockBag(DisposeBag bag) {
    _bag = bag;
    return (_mockBagDisposed = Completer<bool>()).future;
  }

  //
  //
  //

  DisposeBag? _bag;

  /// Get [DisposeBag]
  @protected
  DisposeBag get bag {
    if (!mounted) {
      throw StateError('Invalid when getting bag after disposed.');
    }
    return _bag ??= DisposeBag();
  }

  @override
  void dispose() {
    final future = _bag?.dispose();
    _bag = null;

    if (future != null) {
      _mockBagDisposed?.complete(future);
    }

    super.dispose();
  }
}
