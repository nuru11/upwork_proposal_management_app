import 'dart:js_interop';
import 'package:web/web.dart';

extension type _NavigatorPwa(Navigator _) implements Navigator {
  @JS('standalone')
  external bool? get standalone;
}

bool get shouldShowIosPwaInstallHint {
  final ua = window.navigator.userAgent;
  final isIos =
      ua.contains('iPhone') || ua.contains('iPad') || ua.contains('iPod');
  if (!isIos) return false;

  final displayStandalone =
      window.matchMedia('(display-mode: standalone)').matches;
  final navigatorStandalone = _NavigatorPwa(window.navigator).standalone == true;
  return !displayStandalone && !navigatorStandalone;
}
