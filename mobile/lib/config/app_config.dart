class AppConfig {
  const AppConfig._();

  /// Production API by default. Override for local development:
  /// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`
  /// (Android emulator) or `http://127.0.0.1:3000` (desktop).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://upworkproposalapi.lyanethiopia.com',
    // defaultValue: 'http://192.168.1.4:3000',
  );
}
