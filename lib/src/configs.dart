import '../disposebag.dart';

/// Global configs for dispose bag.
class DisposeBagConfigs {
  /// Logger that logs disposed resources.
  /// Can be set to `null` to disable logging.
  static Logger? logger = disposeBagDefaultLogger;
}
