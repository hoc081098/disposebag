import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';
import 'package:flutter_test/flutter_test.dart';

final key = GlobalKey<_MyWidgetState>();
const buttonKey = Key('button_key');

class MyWidget extends StatefulWidget {
  final DisposeBag disposeBag;

  MyWidget({this.disposeBag}) : super(key: key);

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> with DisposeBagMixin {
  Future<bool> disposed;

  @override
  void initState() {
    super.initState();
    disposed = setMockBag(widget.disposeBag);

    Stream.periodic(const Duration(milliseconds: 100), (i) => i)
        .listen(null)
        .disposedBy(bag);
    StreamController<int>.broadcast().disposedBy(bag);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Title'),
        ),
        body: Center(
          child: MaterialButton(
            key: buttonKey,
            onPressed: () {},
            child: Text('Clicked me'),
          ),
        ),
      ),
    );
  }
}

void main() {
  group('DisposeBagMixin', () {
    DisposeBag disposeBag;

    setUp(() {
      disposeBag = DisposeBag();
    });

    testWidgets('DisposeBagMixin.disposed', (tester) async {
      final myWidget = MyWidget(disposeBag: disposeBag);
      await tester.pumpWidget(myWidget);

      final disposed = key.currentState.disposed;

      final button = find.byKey(buttonKey);
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(disposeBag.length, 2);

      await tester.pumpWidget(Container());
      await tester.runAsync(() => disposed);

      expect(disposeBag.isDisposed, isTrue);
    });
  });
}
