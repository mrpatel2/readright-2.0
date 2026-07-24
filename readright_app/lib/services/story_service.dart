import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

/// Talks to the thin backend proxy that holds the OpenAI key server-side.
/// The Flutter app never sees or embeds the API key — see backend/server.js.
class StoryService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:8787';
    // Android emulator can't reach host "localhost" directly; it maps
    // 10.0.2.2 to the host machine. iOS simulator and desktop share the
    // host network, so localhost works there.
    if (Platform.isAndroid) return 'http://10.0.2.2:8787';
    return 'http://localhost:8787';
  }

  Future<String> generateStory({
    required List<String> words,
    String? theme,
    String? gradeLevel,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/story'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'words': words,
        if (theme != null) 'theme': theme,
        if (gradeLevel != null) 'gradeLevel': gradeLevel,
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Story generation failed (${response.statusCode}).';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['error'] is String) message = body['error'] as String;
      } catch (_) {
        // Non-JSON error body (e.g. the proxy is unreachable) — keep the default message.
      }
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['story'] as String;
  }
}
