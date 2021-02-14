import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:test/test.dart';

import 'mocks.dart';

Stream<int> _getPeriodicStream() =>
    Stream.periodic(const Duration(milliseconds: 100), (i) => i).take(10);

const _maxCount = 5;

void main() {
  group('DisposeBag', () {
    group('DisposeBag.add', () {
      test('DisposeBag.add.subscription', () async {
        final stream = _getPeriodicStream();

        final bag = DisposeBag();

        var count = 0;
        await bag.add(
          stream.asyncMap(
            (_) async {
              ++count;
              if (count == _maxCount) {
                await bag.dispose();
              }
            },
          ).listen(
            expectAsync1(
              (_) {},
              count: _maxCount - 1,
            ),
          ),
        );
      });

      test('DisposeBag.add.subscription.isDisposed', () async {
        final stream = _getPeriodicStream();

        final bag = DisposeBag();
        await bag.dispose();

        var count = 0;
        late StreamSubscription subscription;
        subscription = stream.asyncMap(
          (_) async {
            ++count;
            if (count == _maxCount) {
              await bag.add(subscription);
            }
          },
        ).listen(
          expectAsync1(
            (_) {},
            count: _maxCount - 1,
          ),
        );
      });

      test('DisposeBag.add.sink', () async {
        final controller = StreamController<int>()..stream.listen(null);
        final sink = MockSink();
        final bag = DisposeBag();

        await bag.add(sink);
        await bag.add(controller);
        await bag.dispose();

        expect(sink.call, const MethodCall('close'));
        expect(controller.isClosed, true);
      });

      test('DisposeBag.add.sink.isDisposed', () async {
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag();
        await bag.dispose();

        expect(await bag.add(controller), false);
        expect(controller.isClosed, true);
      });
    });

    group('DisposeBag.addAll', () {
      test('DisposeBag.addAll.isDisposed', () async {
        final stream = _getPeriodicStream();
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag();
        await bag.dispose();

        var count = 0;
        late StreamSubscription subscription;
        subscription = stream.asyncMap(
          (_) async {
            ++count;
            if (count == _maxCount) {
              await bag.addAll(
                [
                  subscription,
                  controller,
                ],
              );
              expect(controller.isClosed, isTrue);
            }
          },
        ).listen(
          expectAsync1(
            (_) {},
            count: _maxCount - 1,
          ),
        );
      });

      test('DisposeBag.addAll', () async {
        final stream = _getPeriodicStream();
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag();

        var count = 0;
        await bag.addAll(
          [
            stream.asyncMap(
              (_) async {
                ++count;
                if (count == _maxCount) {
                  await bag.dispose();
                  expect(controller.isClosed, isTrue);
                }
              },
            ).listen(
              expectAsync1(
                (_) {},
                count: _maxCount - 1,
              ),
            ),
            controller,
          ],
        );
      });
    });

    group('DisposeBag.delete', () {
      test('DisposeBag.delete', () async {
        final subscription = Stream.empty().listen(null);
        final controller = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag([subscription, controller]);

        expect(bag.delete(subscription), isTrue);
        expect(bag.delete(controller), isTrue);

        expect(controller.isClosed, isFalse);
        expect(bag.length, 0);
      });

      test('DisposeBag.delete.isDisposed', () async {
        final subscription = Stream.empty().listen(null);
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag([subscription, controller]);
        await bag.dispose();

        expect(bag.length, 0);
        expect(controller.isClosed, isTrue);

        expect(
            () => bag.delete(subscription), throwsA(isA<DisposedException>()));
        expect(() => bag.delete(controller), throwsA(isA<DisposedException>()));
      });
    });

    group('DisposeBag.remove', () {
      test('DisposeBag.remove', () async {
        final stream = _getPeriodicStream();
        final controller = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag([controller]);

        expect(await bag.remove(controller), isTrue);
        expect(controller.isClosed, isTrue);

        var count = 0;
        late StreamSubscription subscription;
        subscription = stream.asyncMap((_) async {
          ++count;
          if (count == _maxCount) {
            expect(await bag.remove(subscription), isTrue);
          }
        }).listen(
          expectAsync1(
            (_) {},
            count: _maxCount - 1,
          ),
        );
        await bag.add(subscription);
      });

      test('DisposeBag.remove.isDisposed', () async {
        final subscription = Stream.empty().listen(null);
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag([subscription, controller]);
        await bag.dispose();

        expect(bag.length, 0);
        expect(controller.isClosed, isTrue);

        final throwsDisposedException = throwsA(
          isA<DisposedException>().having((e) => e.toString(), 'toString',
              '$bag was disposed, try to use new instance instead.'),
        );
        expect(bag.remove(subscription), throwsDisposedException);
        expect(bag.remove(controller), throwsDisposedException);
      });
    });

    group('DisposeBag.clear', () {
      test('DisposeBag.clear', () async {
        final completer = Completer<void>();

        final stream1 = _getPeriodicStream();
        final controller1 = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag([controller1]);

        var count1 = 0;
        await bag.add(
          stream1.asyncMap((_) async {
            ++count1;
            if (count1 == _maxCount) {
              await bag.clear();
              expect(controller1.isClosed, isTrue);
              completer.complete();
            }
          }).listen(
            expectAsync1(
              (_) {},
              count: _maxCount - 1,
            ),
          ),
        );

        await completer.future;
        // Reuse bag

        final completer2 = Completer<void>();
        final stream2 = _getPeriodicStream();
        final controller2 = StreamController<int>()..stream.listen(null);
        await bag.add(controller2);

        var count2 = 0;
        await bag.add(
          stream2.asyncMap((_) async {
            ++count2;
            if (count2 == _maxCount) {
              await bag.clear();
              completer2.complete();
            }
          }).listen(
            expectAsync1(
              (_) {},
              count: _maxCount - 1,
            ),
          ),
        );

        await completer2.future;
        expect(controller2.isClosed, isTrue);
      });

      test('DisposeBag.clear.isClearing', () {
        final disposeBag = DisposeBag([
          Stream.value(1).listen(null),
          Stream.value(2).listen(null),
        ]);

        expect(disposeBag.isClearing, isFalse);
        disposeBag.clear();
        expect(disposeBag.isClearing, isTrue);

        expect(
          disposeBag.clear(),
          throwsA(isA<ClearingException>().having(
              (e) => e.toString(),
              'toString',
              '$disposeBag is clearing, try to await for completion.')),
        );
      });
    });

    group('DisposeBag.guardType', () {
      test('DisposeBag.add', () {
        // expect(() => DisposeBag().add(null), throwsArgumentError);
        expect(() => DisposeBag().add(1), throwsArgumentError);
      });

      test('DisposeBag.addAll', () {
        // expect(
        //   () => DisposeBag().addAll(
        //     [
        //       null,
        //       Stream.value(1).listen(null),
        //     ],
        //   ),
        //   throwsArgumentError,
        // );

        expect(
          () => DisposeBag().addAll(
            [
              1,
              Stream.value(1).listen(null),
            ],
          ),
          throwsArgumentError,
        );
      });

      test('DisposeBag.constructor', () {
        expect(
          () => DisposeBag([
            1,
            Stream.value(1).listen(null),
          ]),
          throwsArgumentError,
        );

        // expect(
        //   () => DisposeBag([
        //     null,
        //     Stream.value(1).listen(null),
        //   ]),
        //   throwsArgumentError,
        // );
      });
    });

    test('DisposeBag.disposables', () {
      final disposeBag = DisposeBag();
      disposeBag.addAll([
        Stream.value(1).listen((event) {}),
        Stream.value(2).listen((event) {}),
        Stream.value(3).listen((event) {}),
      ]);
      expect(disposeBag.disposables.length, 3);
      disposeBag.disposables.forEach(
        (s) => expect(
          s,
          const TypeMatcher<StreamSubscription<int>>(),
        ),
      );
    });

    test('DisposeBag.isDisposed', () async {
      final disposeBag = DisposeBag([
        Stream.value(1).listen((event) {}),
        Stream.value(2).listen((event) {}),
        Stream.value(3).listen((event) {}),
      ]);
      await disposeBag.dispose();
      expect(disposeBag.disposables, isEmpty);
      expect(disposeBag.isDisposed, isTrue);
    });

    test('DisposeBag.dispose.failed', () async {
      final disposeBag = DisposeBag();
      final mockStreamSubscription = MockStreamSubscription();

      mockStreamSubscription.whenCancel = () => Future.error(Exception());

      await disposeBag.add(mockStreamSubscription);
      expect(disposeBag.dispose(), throwsA(isException));
      expect(disposeBag.isDisposed, false);
    });

    test('DisposeBag.clear.failed', () async {
      final disposeBag = DisposeBag();
      final mockStreamSubscription = MockStreamSubscription();

      mockStreamSubscription.whenCancel = () => Future.error(Exception());

      await disposeBag.add(mockStreamSubscription);
      expect(disposeBag.clear(), throwsA(isException));
    });

    test('issue #2', () async {
      final bag = DisposeBag();

      final controller = StreamController<int>(
        onCancel: () => Future.delayed(
          const Duration(milliseconds: 10),
        ),
      );

      await controller.disposedBy(bag);
      await controller.stream.listen(null).disposedBy(bag);

      await Stream.periodic(const Duration(milliseconds: 1), (i) => i)
          .map((i) => i + 1)
          .where((i) => i.isEven)
          .listen(controller.add)
          .disposedBy(bag);

      await bag.dispose();
    });
  });

  group('Extensions', () {
    late MockDisposeBag bag;

    setUp(() => bag = MockDisposeBag());

    test('StreamSubscription.disposedBy', () {
      final subscription = Stream.value(1).listen(null);
      subscription.disposedBy(bag);
      expect(bag.call, MethodCall('add', subscription));
    });

    test('Sink.disposedBy', () {
      final controller = StreamController<void>();
      controller.disposedBy(bag);
      expect(bag.call, MethodCall('add', controller));
    });

    test('Iterable<StreamSubscription>.disposedBy', () {
      final subscription1 = Stream.value(1).listen(null);
      final subscription2 = Stream.value(1).listen(null);

      final subscriptions = [subscription1, subscription2];
      subscriptions.disposedBy(bag);

      expect(bag.call, MethodCall('addAll', subscriptions));
    });

    test('Iterable<Sink>.disposedBy', () {
      final controller1 = StreamController<void>();
      final controller2 = StreamController<void>();

      final sinks = [controller1, controller2];
      sinks.disposedBy(bag);

      expect(bag.call, MethodCall('addAll', sinks));
    });
  });
}
