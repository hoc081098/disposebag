import 'dart:async';

import 'package:disposebag/disposebag.dart';
import 'package:test/test.dart';

void main() {
  group('DisposeBag', () {
    //   test('A', () async {
    //     final subject = PublishSubject<int>();

    //     var disposeBag = DisposeBag(
    //       [
    //         Observable.periodic(const Duration(milliseconds: 500), (i) => i)
    //             .listen(subject.add),
    //         subject.listen(print),
    //         subject,
    //       ],
    //     );

    //     await Future.delayed(const Duration(seconds: 3));

    //     await disposeBag.dispose();
    //     print('[DISPOSED]');
    //     expect(disposeBag.isDisposed, isTrue);

    //     expect(await disposeBag.add(subject), isFalse);

    //     expect(
    //       await disposeBag.add(
    //         Stream.periodic(
    //           const Duration(microseconds: 1),
    //           (i) => i,
    //         ).listen(print),
    //       ),
    //       isFalse,
    //     );

    //     await Future.delayed(const Duration(seconds: 3));
    //     print('[DONE]');
    //   });

    //   test('B', () async {
    //     final subject = PublishSubject<int>();

    //     var disposeBag = DisposeBag(
    //       [
    //         Observable.periodic(const Duration(milliseconds: 500), (i) => i)
    //             .listen(subject.add),
    //         subject.listen(print),
    //         subject,
    //       ],
    //     );

    //     await Future.delayed(const Duration(seconds: 3));

    //     await disposeBag.clear();
    //     print('[CLEARED]');
    //     expect(disposeBag.isDisposed, isFalse);

    //     await disposeBag.add(
    //       Observable.periodic(const Duration(milliseconds: 500), (i) => i)
    //           .listen(print),
    //     );

    //     await Future.delayed(const Duration(seconds: 2));
    //     await disposeBag.clear();
    //     print('[CLEARED]');
    //     await Future.delayed(const Duration(seconds: 2));
    //     print('[DONE]');
    //   });

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
          ).listen(null),
        );

        await Future.delayed(const Duration(milliseconds: 100 * 10));

        expect(count, 5);
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
        ).listen(null);

        await Future.delayed(const Duration(milliseconds: 100 * 10));
        expect(count, 5);
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
            }
          },
        ).listen(null);

        await Future.delayed(const Duration(milliseconds: 100 * 10));
        expect(count, 5);
        expect(controller.isClosed, isTrue);
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
  });
}
