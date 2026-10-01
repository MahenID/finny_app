import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Koneksi ke penyedia AI dengan format OpenAI-compatible Chat Completions.
class AiService {
  AiService({
    required String baseUrl,
    required String apiKey,
    String model = '',
    http.Client? client,
    Duration timeout = const Duration(seconds: 60),
  }) : _baseUrl = baseUrl.trim(),
       _apiKey = apiKey.trim(),
       _model = model.trim(),
       _client = client ?? http.Client(),
       _timeout = timeout;

  final String _baseUrl;
  final String _apiKey;
  final String _model;
  final http.Client _client;
  final Duration _timeout;
  Future<String>? _discoveredModel;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
  };

  Future<String> complete(String prompt) async {
    try {
      final endpoint = _completionEndpoint();
      final model = await _resolveModel(endpoint);
      final response = await _client
          .post(
            endpoint,
            headers: _headers,
            body: jsonEncode({
              'model': model,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'stream': false,
            }),
          )
          .timeout(_timeout);

      _checkStatus(response.statusCode);
      return _readText(_readJson(response));
    } on TimeoutException {
      throw const AiException('AI terlalu lama merespons. Silakan coba lagi.');
    } on http.ClientException {
      // Jangan sertakan URL request atau kredensial dalam pesan error.
      throw const AiException(
        'Tidak dapat menghubungi AI. Periksa koneksi dan URL penyedia.',
      );
    }
  }

  Uri _completionEndpoint() {
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw const AiException(
        'URL AI belum diatur atau tidak valid. Isi AI_BASE_URL di secrets.json.',
      );
    }

    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.endsWith('/messages') ||
        path.endsWith('/responses') ||
        path.contains(':generateContent')) {
      throw const AiException(
        'Gunakan URL API yang kompatibel dengan /chat/completions.',
      );
    }

    return uri.replace(
      path: path.endsWith('/chat/completions')
          ? path
          : '$path/chat/completions',
      fragment: '',
    );
  }

  Future<String> _resolveModel(Uri endpoint) async {
    if (_model.isNotEmpty) return _model;

    try {
      return await (_discoveredModel ??= _discoverModel(endpoint));
    } catch (_) {
      // Kegagalan sementara tidak boleh terkunci dalam cache.
      _discoveredModel = null;
      rethrow;
    }
  }

  Future<String> _discoverModel(Uri endpoint) async {
    final basePath = endpoint.path.substring(
      0,
      endpoint.path.length - '/chat/completions'.length,
    );
    final response = await _client
        .get(endpoint.replace(path: '$basePath/models'), headers: _headers)
        .timeout(_timeout);

    if (response.statusCode == 401 ||
        response.statusCode == 403 ||
        response.statusCode == 429 ||
        response.statusCode >= 500) {
      _checkStatus(response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic models;
      try {
        models = _readJson(response)['data'];
      } on AiException {
        throw _missingModel();
      }
      if (models is List) {
        for (final model in models) {
          if (model is Map && _isChatModel(model)) {
            return (model['id'] as String).trim();
          }
        }
      }
    }

    throw _missingModel();
  }

  bool _isChatModel(Map model) {
    final id = model['id'];
    if (id is! String || id.trim().isEmpty || model['active'] == false) {
      return false;
    }

    final architecture = model['architecture'];
    final modalities = architecture is Map
        ? architecture['output_modalities']
        : null;
    if (modalities is List) return modalities.contains('text');

    // /models dapat memuat model audio, gambar, dan embedding juga.
    final lowerId = id.toLowerCase();
    return ![
      'embed',
      'whisper',
      'tts',
      'transcrib',
      'rerank',
      'moderation',
      'guard',
      'dall-e',
      'image',
      'stable-diffusion',
      'flux',
    ].any(lowerId.contains);
  }

  AiException _missingModel() => const AiException(
    'Model AI tidak dapat dipilih otomatis. Isi AI_MODEL di secrets.json '
    'dengan nama model chat dari penyedia Anda.',
  );

  void _checkStatus(int status) {
    if (status >= 200 && status < 300) return;
    if (status == 401 || status == 403) {
      throw const AiException(
        'API key AI tidak valid atau belum memiliki akses. '
        'Periksa AI_API_KEY dan izin model Anda.',
      );
    }
    if (status == 429) {
      throw const AiException(
        'Batas penggunaan AI tercapai. Periksa kuota atau coba lagi nanti.',
      );
    }
    if (status == 400 || status == 404 || status == 422) {
      throw const AiException(
        'URL atau model AI belum sesuai. Periksa AI_BASE_URL dan AI_MODEL.',
      );
    }
    throw AiException('AI sedang tidak tersedia ($status). Coba lagi nanti.');
  }

  Map<String, dynamic> _readJson(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // Pesan penyedia tidak ditampilkan agar tidak membocorkan kredensial.
    }
    throw const AiException('Respons AI tidak sesuai format Chat Completions.');
  }

  String _readText(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is List && choices.isNotEmpty && choices.first is Map) {
      final message = choices.first['message'];
      final content = message is Map ? message['content'] : null;
      if (content is String && content.trim().isNotEmpty) {
        return content.trim();
      }
      if (content is List) {
        final text = content
            .whereType<Map>()
            .where((part) => part['type'] == 'text' && part['text'] is String)
            .map((part) => part['text'] as String)
            .join('\n')
            .trim();
        if (text.isNotEmpty) return text;
      }
    }
    throw const AiException(
      'AI tidak memberikan jawaban teks. Coba lagi nanti.',
    );
  }

  void dispose() => _client.close();
}

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}
