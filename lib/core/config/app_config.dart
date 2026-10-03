/// Central place for environment-specific configuration.
///
/// The previous codebase hardcoded `http://10.0.2.2:5000` (the Android
/// emulator's loopback alias) in two separate service files, which meant
/// video calling could never work on a real device or in production.
///
/// Pass the real token-server URL at build/run time with:
///   flutter run --dart-define=TOKEN_SERVER_URL=https://your-server.example.com
class AppConfig {
  AppConfig._();

  static const String tokenServerUrl = String.fromEnvironment(
    'TOKEN_SERVER_URL',
    // Falls back to the emulator loopback for local development only.
    defaultValue: 'http://10.0.2.2:5000',
  );

  /// Agora App ID for the CARE-O project.
  static const String agoraAppId = 'c42dc544cc2b44abbec5ac1986d6a072';
}
