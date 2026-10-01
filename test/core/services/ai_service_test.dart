import 'dart:async';
import 'dart:convert';

import 'package:finance1/core/services/ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response answer([Object? content = 'Rangkuman keuangan 📊']) =>
    jsonResponse({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    });

Matcher aiError(String text) => isA<AiException>().having(
  (error) => error.message,
  'message',
  contains(text),
);

void main() {
  test('uses provider base path, bearer auth, and selected model', () async {
    final service = AiService(
      baseUrl: ' https://provider.example/openai/v1///?tenant=finny ',
      apiKey: ' test-api-key ',
      model: ' vendor-chat ',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/openai/v1/chat/completions');
        expect(request.url.queryParameters, {'tenant': 'finny'});
        expect(request.headers['Authorization'], 'Bearer test-api-key');
        expect(request.headers['Content-Type'], 'application/json');
        expect(jsonDecode(request.body), {
          'model': 'vendor-chat',
          'messages': [
            {'role': 'user', 'content': 'Analisa transaksi saya'},
          ],
          'stream': false,
        });
        return answer();
      }),
    );
    addTearDown(service.dispose);

    expect(
      await service.complete('Analisa transaksi saya'),
      'Rangkuman keuangan 📊',
    );
  });

  test('accepts a complete endpoint without appending it twice', () async {
    final service = AiService(
      baseUrl: 'https://provider.example/api/v1/chat/completions/',
      apiKey: 'test-api-key',
      model: 'chat-model',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/chat/completions');
        return answer();
      }),
    );
    addTearDown(service.dispose);
    await service.complete('Halo');
  });

  test(
    'discovers a text model and caches it for subsequent messages',
    () async {
      var discoveries = 0;
      var completions = 0;
      final service = AiService(
        baseUrl: 'https://provider.example/api/v1/chat/completions',
        apiKey: 'test-api-key',
        client: MockClient((request) async {
          if (request.method == 'GET') {
            discoveries++;
            expect(request.url.path, '/api/v1/models');
            expect(request.headers['Authorization'], 'Bearer test-api-key');
            return jsonResponse({
              'data': [
                {'id': 'text-embedding-large'},
                {'id': 'whisper-audio'},
                {'id': 'old-chat', 'active': false},
                {
                  'id': 'paint-model',
                  'architecture': {
                    'output_modalities': ['image'],
                  },
                },
                {'id': 'chat-alpha'},
                {'id': 'chat-beta'},
              ],
            });
          }
          completions++;
          expect(jsonDecode(request.body)['model'], 'chat-alpha');
          return answer();
        }),
      );
      addTearDown(service.dispose);

      await service.complete('Pertanyaan pertama');
      await service.complete('Pertanyaan kedua');
      expect(discoveries, 1);
      expect(completions, 2);
    },
  );

  test('asks for AI_MODEL when the provider has no model list', () async {
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'test-api-key',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        return http.Response('Not found', 404);
      }),
    );
    addTearDown(service.dispose);
    await expectLater(service.complete('Halo'), throwsA(aiError('AI_MODEL')));
  });

  test('failed discovery is retried on the next request', () async {
    var discoveries = 0;
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'test-api-key',
      client: MockClient((request) async {
        if (request.method == 'GET') {
          discoveries++;
          if (discoveries == 1) return http.Response('Temporary error', 503);
          return jsonResponse({
            'data': [
              {'id': 'chat-model'},
            ],
          });
        }
        return answer();
      }),
    );
    addTearDown(service.dispose);

    await expectLater(service.complete('Halo'), throwsA(aiError('503')));
    expect(await service.complete('Coba lagi'), 'Rangkuman keuangan 📊');
    expect(discoveries, 2);
  });

  for (final status in [401, 403, 429, 500]) {
    test('handles HTTP $status without exposing the response body', () async {
      final service = AiService(
        baseUrl: 'https://provider.example/v1',
        apiKey: 'test-api-key',
        model: 'chat-model',
        client: MockClient((_) async => http.Response('test-api-key', status)),
      );
      addTearDown(service.dispose);

      await expectLater(
        service.complete('Halo'),
        throwsA(
          isA<AiException>().having(
            (error) => error.message,
            'safe message',
            isNot(contains('test-api-key')),
          ),
        ),
      );
    });
  }

  test('rejects empty choices and malformed JSON safely', () async {
    var requests = 0;
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'test-api-key',
      model: 'chat-model',
      client: MockClient((_) async {
        requests++;
        return requests == 1
            ? jsonResponse({'choices': []})
            : http.Response('<html>Gateway error</html>', 200);
      }),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.complete('Halo'),
      throwsA(aiError('jawaban teks')),
    );
    await expectLater(
      service.complete('Halo'),
      throwsA(aiError('format Chat Completions')),
    );
  });

  test('reads text content parts while ignoring nontext content', () async {
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'test-api-key',
      model: 'chat-model',
      client: MockClient(
        (_) async => answer([
          {'type': 'text', 'text': 'Ringkasan'},
          {'type': 'image_url', 'image_url': 'https://example.com/image'},
          {'type': 'text', 'text': 'Tips hemat'},
        ]),
      ),
    );
    addTearDown(service.dispose);
    expect(await service.complete('Halo'), 'Ringkasan\nTips hemat');
  });

  test('supports local providers without an API key', () async {
    final service = AiService(
      baseUrl: 'http://localhost:1234/v1',
      apiKey: '',
      model: 'local-model',
      client: MockClient((request) async {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return answer();
      }),
    );
    addTearDown(service.dispose);
    await service.complete('Halo');
  });

  test(
    'invalid URLs and unsupported API formats never send a request',
    () async {
      for (final url in [
        '',
        'provider.example/v1',
        'ftp://provider.example/v1',
        'https://provider.example/v1/messages',
        'https://provider.example/v1/responses',
        'https://provider.example/v1/models/chat:generateContent',
      ]) {
        final service = AiService(
          baseUrl: url,
          apiKey: 'test-api-key',
          model: 'chat-model',
          client: MockClient((_) async => fail('Unexpected HTTP request')),
        );
        addTearDown(service.dispose);
        await expectLater(
          service.complete('Halo'),
          throwsA(isA<AiException>()),
        );
      }
    },
  );

  test('request timeout returns an actionable message', () async {
    final pendingResponse = Completer<http.Response>();
    final service = AiService(
      baseUrl: 'https://provider.example/v1',
      apiKey: 'test-api-key',
      model: 'chat-model',
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) => pendingResponse.future),
    );
    addTearDown(() {
      pendingResponse.complete(answer());
      service.dispose();
    });
    await expectLater(
      service.complete('Halo'),
      throwsA(aiError('terlalu lama')),
    );
  });
}
