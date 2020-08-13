import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_disposebag/flutter_disposebag.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with DisposeBagMixin {
  final controller = StreamController<int>();

  @override
  void initState() {
    super.initState();

    Stream.periodic(const Duration(milliseconds: 500), (i) => i)
        .listen((event) {})
        .disposedBy(bag);

    controller.stream.listen((event) {}).disposedBy(bag);
    controller.disposedBy(bag);
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
