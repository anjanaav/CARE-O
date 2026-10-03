import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// Fetches Agora RTC tokens from the token server.
///
/// This replaces the two previous duplicate implementations
/// (`services/api_service.dart` using Dio and `services/agora_service.dart`
/// using `http`) that both hit the same hardcoded emulator URL.
class AgoraTokenService {
  const AgoraTokenService();

  Future<String?> fetchToken(String channelName) async {
    final uri = Uri.parse('${AppConfig.tokenServerUrl}/generateToken')
        .replace(queryParameters: {'channelName': channelName});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['token'] as String?;
      }
      return null;
    } catch (_) {
      // Network/parse errors surface as a null token; callers show an
      // error state rather than crashing the call screen.
      return null;
    }
  }
}
