import 'package:flutter/foundation.dart';

class AlertsRefreshNotifier {
  static final ValueNotifier<int> _version = ValueNotifier<int>(0);

  static ValueListenable<int> get listenable => _version;

  static void bump() {
    _version.value = _version.value + 1;
  }
}
