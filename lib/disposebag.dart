/// ## Helper disposing Streams and closing Sinks
/// ![Pub](https://img.shields.io/pub/v/disposebag)
/// ### Author: [Petrus Nguyễn Thái Học](https://github.com/hoc081098)
///
/// ### Usage example
///
/// ```dart
/// final controller = StreamController<int>();
/// final bag = DisposeBag([
///     controller,
///     controller.stream.listen(controller1.add)
/// ]);
/// // Dispose all stream subscriptions, close all stream controllers
/// await bag.dispose();
/// print("Bag disposed. It's all good");
/// ```
library disposebag;

export 'src/disposebag_base.dart';
