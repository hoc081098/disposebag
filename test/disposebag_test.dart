import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:test/test.dart';

void main() {
  group('DisposeBag', () {
    group('DisposeBag.add', () {
      test('DisposeBag.add.subscription', () async {
        final stream =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);

        final bag = DisposeBag();

        var count = 0;
        await bag.add(
          stream.asyncMap(
            (_) async {
              ++count;
              if (count == 5) {
                await bag.dispose();
              }
            },
          ).listen(
            expectAsync1(
              (_) {},
              count: 4,
            ),
          ),
        );
      });

      test('DisposeBag.add.subscription.isDisposed', () async {
        final stream =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);

        final bag = DisposeBag();
        await bag.dispose();

        var count = 0;
        StreamSubscription subscription;
        subscription = stream.asyncMap(
          (_) async {
            ++count;
            if (count == 5) {
              await bag.add(subscription);
            }
          },
        ).listen(
          expectAsync1(
            (_) {},
            count: 4,
          ),
        );
      });

      test('DisposeBag.add.sink', () async {
        final controller = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag();

        await bag.add(controller);
        await bag.dispose();

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
        final stream =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag();
        await bag.dispose();

        var count = 0;
        StreamSubscription subscription;
        subscription = stream.asyncMap(
          (_) async {
            ++count;
            if (count == 5) {
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
            count: 4,
          ),
        );
      });

      test('DisposeBag.addAll', () async {
        final stream =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);
        final controller = StreamController<int>()..stream.listen(null);

        final bag = DisposeBag();

        var count = 0;
        await bag.addAll(
          [
            stream.asyncMap(
              (_) async {
                ++count;
                if (count == 5) {
                  await bag.dispose();
                  expect(controller.isClosed, isTrue);
                }
              },
            ).listen(
              expectAsync1(
                (_) {},
                count: 4,
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

        expect(await bag.delete(subscription), isTrue);
        expect(await bag.delete(controller), isTrue);

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

        expect(await bag.delete(subscription), isFalse);
        expect(await bag.delete(controller), isFalse);
      });
    });

    group('DisposeBag.remove', () {
      test('DisposeBag.remove', () async {
        final stream =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);
        final controller = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag([controller]);

        expect(await bag.remove(controller), isTrue);
        expect(controller.isClosed, isTrue);

        var count = 0;
        StreamSubscription subscription;
        subscription = stream.asyncMap((_) async {
          ++count;
          if (count == 5) {
            expect(await bag.remove(subscription), isTrue);
          }
        }).listen(
          expectAsync1(
            (_) {},
            count: 4,
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

        expect(await bag.remove(subscription), isFalse);
        expect(await bag.remove(controller), isFalse);
      });
    });

    group('DisposeBag.clear', () {
      test('DisposeBag.clear', () async {
        final completer = Completer<void>();

        final stream1 =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);
        final controller1 = StreamController<int>()..stream.listen(null);
        final bag = DisposeBag([controller1]);

        var count1 = 0;
        await bag.add(
          stream1.asyncMap((_) async {
            ++count1;
            if (count1 == 5) {
              await bag.clear();
              expect(controller1.isClosed, isTrue);
              completer.complete();
            }
          }).listen(
            expectAsync1(
              (_) {},
              count: 4,
            ),
          ),
        );

        await completer.future;
        // Reuse bag

        final stream2 =
            Stream.periodic(const Duration(milliseconds: 100)).take(10);
        final controller2 = StreamController<int>()..stream.listen(null);
        await bag.add(controller2);

        var count2 = 0;
        await bag.add(
          stream2.asyncMap((_) async {
            ++count2;
            if (count2 == 5) {
              await bag.clear();
              expect(controller2.isClosed, isTrue);
            }
          }).listen(
            expectAsync1(
              (_) {},
              count: 4,
            ),
          ),
        );
      });
    });
  });
}
