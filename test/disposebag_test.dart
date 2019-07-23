import 'package:rxdart/rxdart.dart';
import 'package:disposebag/disposebag.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    test('A', () async {
      final subject = PublishSubject<int>();

      var disposeBag = DisposeBag(
        [
          Observable.periodic(const Duration(milliseconds: 500), (i) => i)
              .listen(subject.add),
          subject.listen(print),
          subject,
        ],
      );

      await Future.delayed(const Duration(seconds: 3));

      await disposeBag.dispose();
      print('[DISPOSED]');
      expect(disposeBag.isDisposed, isTrue);

      expect(await disposeBag.add(subject), isFalse);

      expect(
        await disposeBag.add(
          Stream.periodic(
            const Duration(microseconds: 1),
            (i) => i,
          ).listen(print),
        ),
        isFalse,
      );

      await Future.delayed(const Duration(seconds: 3));
      print('[DONE]');
    });

    test('B', () async {
      final subject = PublishSubject<int>();

      var disposeBag = DisposeBag(
        [
          Observable.periodic(const Duration(milliseconds: 500), (i) => i)
              .listen(subject.add),
          subject.listen(print),
          subject,
        ],
      );

      await Future.delayed(const Duration(seconds: 3));

      await disposeBag.clear();
      print('[CLEARED]');
      expect(disposeBag.isDisposed, isFalse);

      await disposeBag.add(
        Observable.periodic(const Duration(milliseconds: 500), (i) => i)
            .listen(print),
      );

      await Future.delayed(const Duration(seconds: 2));
      await disposeBag.clear();
      print('[CLEARED]');
      await Future.delayed(const Duration(seconds: 2));
      print('[DONE]');
    });
  });
}
