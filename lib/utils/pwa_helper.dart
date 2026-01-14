
// Main entry point
import 'dart:ui';
import 'pwa_helper_stub.dart'
    if (dart.library.html) 'pwa_helper_web.dart';

class PwaInstallManager {
  final PwaHelper _helper = PwaHelper();

  Future<void> init(VoidCallback onStateChange) => _helper.init(onStateChange);
  bool get canInstall => _helper.canInstall;
  Future<void> promptInstall() => _helper.installApp();
}
