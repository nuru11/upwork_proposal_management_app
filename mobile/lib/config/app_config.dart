class AppConfig {
  const AppConfig._();

  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000`
  ///
  /// Defaults to Android emulator loopback. Use `http://127.0.0.1:3000` on
  /// desktop, or your machine LAN IP on a physical device.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
