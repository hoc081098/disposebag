import 'dart:async' show Future, StreamSink, StreamSubscription;

import 'package:collection/collection.dart'
    show UnmodifiableSetView, IterableNullableExtension;
import 'package:disposebag/disposebag.dart';
import 'package:meta/meta.dart' show visibleForTesting;

import 'disposebag_base.dart';
import 'exceptions.dart';
import 'logger.dart';

enum _Operation { clear, dispose }

extension on _Operation {
  BagResult toResultWith({
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

void _guardType(Object disposable) {
  ArgumentError.checkNotNull(disposable, 'disposable');

  if (!(disposable is StreamSubscription || disposable is Sink)) {
    throw ArgumentError.value(
        disposable, 'disposable', 'must be a StreamSubscription or a Sink');
  }
}

void _guardTypeMany(Iterable<Object> disposable) =>
    disposable.forEach(_guardType);

Future<void>? _wait(List<Future<void>> futures) {
  if (futures.isEmpty) {
    return null;
  }
  if (futures.length == 1) {
    return futures[0];
  }
  return Future.wait(futures, eagerError: true);
}

/// Returns a 5 character long hexadecimal string generated from
/// [Object.hashCode]'s 20 least-significant bits.
String _shortHash(Object? object) =>
    object.hashCode.toUnsigned(20).toRadixString(16).padLeft(5, '0');

/// Evaluates a lazy iterable.
///
/// Known non-lazy types are returned directly instead.
Iterable<E> _evaluateIterable<E>(Iterable<E> iterable) {
  if (iterable is! List && iterable is! Set) {
    iterable = iterable.toList(growable: false);
  }
  return iterable;
}

/// Class that helps closing sinks and canceling stream subscriptions
class DisposeBag implements DisposeBagBase {
  final String? _tag;
  Set<Object>? _resources; // <StreamSubscription | Sink>{}
  bool _isClearing = false;

  /// Construct a [DisposeBag] with [disposables] iterable.
  /// [disposables] must be an [Iterable] of [StreamSubscription]s or a [Sink]s.
  ///
  /// [tag] used for debugging purpose (eg. logger, toString, ...).
  DisposeBag([
    Iterable<Object> disposables = const <Object>[],
    String? tag,
  ]) : _tag = tag {
    disposables = _evaluateIterable(disposables);
    _guardTypeMany(disposables);
    _resources = Set.of(disposables);
  }

  @override
  String toString() =>
      'DisposeBag${_tag == null ? '' : '#$_tag'}#${_shortHash(this)}';

  //
  // Internal
  //

  Set<Object>? _validResourcesOrNull() =>
      isDisposed || _isClearing ? null : _resources!;

  /// Can throws
  Set<Object> _validResourcesOrThrows() {
    if (isDisposed) {
      throw DisposedException(this);
    }
    if (_isClearing) {
      throw ClearingException(this);
    }
    return _resources!;
  }

  /// Cancel [StreamSubscription] or close [Sink]
  static Future<dynamic>? _disposeOne(Object disposable) {
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

  static Future<void>? _disposeByType<T extends Object>(
      Iterable<Object> resources) {
    return _wait(resources
        .whereType<T>()
        .map(_disposeOne)
        .whereNotNull()
        .toList(growable: false));
  }

  Future<void> _clear(_Operation operation) async {
    final resources = _validResourcesOrThrows();
    _isClearing = true;

    try {
      await _disposeByType<StreamSubscription>(resources);
      await _disposeByType<Sink>(resources);

      DisposeBagConfigs.logger?.call(
        this,
        operation.toResultWith(),
        UnmodifiableSetView(resources),
      );

      resources.clear();
      if (operation == _Operation.dispose) {
        // mask as disposed
        _resources = null;
      }
    } catch (e, s) {
      DisposeBagConfigs.logger?.call(
        this,
        operation.toResultWith(error: e, stackTrace: s),
        UnmodifiableSetView(resources),
        e,
        s,
      );
      rethrow;
    } finally {
      _isClearing = false;
    }
  }

  //
  // Public
  //

  @override
  bool get isDisposed => _resources == null;

  @override
  bool get isClearing => _isClearing;

  @override
  int get length => _validResourcesOrNull()?.length ?? 0;

  @override
  @visibleForTesting
  Set<Object> get disposables =>
      Set.unmodifiable(_validResourcesOrNull() ?? const <Object>{});

  @override
  Future<bool> add(Object disposable) async {
    _guardType(disposable);

    final resources = _validResourcesOrNull();
    if (resources == null) {
      await _disposeOne(disposable);
      return false;
    }
    return resources.add(disposable);
  }

  @override
  Future<void> addAll(Iterable<Object> disposables) async {
    disposables = _evaluateIterable(disposables);
    _guardTypeMany(disposables);

    final resources = _validResourcesOrNull();
    if (resources == null) {
      await _disposeByType<StreamSubscription>(disposables);
      return _disposeByType<Sink>(disposables);
    }
    resources.addAll(disposables);
  }

  @override
  Future<bool> remove(Object disposable) async {
    final removed = delete(disposable);
    if (removed) {
      await _disposeOne(disposable);
    }
    return removed;
  }

  @override
  bool delete(Object disposable) {
    _guardType(disposable);

    return _validResourcesOrThrows().remove(disposable);
  }

  @override
  Future<void> clear() => _clear(_Operation.clear);

  @override
  Future<void> dispose() => _clear(_Operation.dispose);
}
