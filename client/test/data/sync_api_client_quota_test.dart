import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noo/data/services/sync_api_client.dart';
import 'package:noo/domain/entities/sync_config.dart';

SyncApiClient _client(MockClientHandler handler) => SyncApiClient(
      config: const SyncConfig(
        enabled: true,
        serverUrl: 'https://relay.test',
        username: 'amy',
        password: 'password123',
        deviceId: 'device-a',
      ),
      client: MockClient(handler),
    );

void main() {
  group('RelayUsage', () {
    test('reads the quota and what it is measured against', () {
      final usage = RelayUsage.fromJson({
        'packets': 3,
        'bytes': 1000,
        'devices': [],
        'blobs': 1,
        'blob_bytes': 500,
        'used_bytes': 1500,
        'quota_bytes': 3000,
      });
      expect(usage.hasQuota, isTrue);
      expect(usage.usedBytes, 1500);
      expect(usage.quotaFraction, 0.5);
    });

    test('a relay without used_bytes or a quota still reads', () {
      final usage = RelayUsage.fromJson(
          {'packets': 3, 'bytes': 1000, 'devices': [], 'blob_bytes': 500});
      expect(usage.usedBytes, 1500, reason: 'packets plus blobs');
      expect(usage.hasQuota, isFalse);
      expect(usage.quotaFraction, 0);
    });
  });

  group('RelayStorageFullException', () {
    test('a quota refusal names what is used and what fits', () {
      final e = RelayStorageFullException.fromBody(jsonEncode({
        'detail': 'Storage quota exceeded: using 10485760 of 20971520 bytes',
      }));
      expect(e.limit, RelayStorageLimit.quota);
      expect(e.usedBytes, 10485760);
      expect(e.quotaBytes, 20971520);
      expect(e.statusCode, 507);
      expect(e.toString(), contains('10.0 MB of 20.0 MB used'));
    });

    test('a full server disk is not the user\'s quota', () {
      final e = RelayStorageFullException.fromBody(
          jsonEncode({'detail': 'The server is out of storage space'}));
      expect(e.limit, RelayStorageLimit.serverDisk);
      expect(e.toString(), contains('sync again later'));
    });

    test('the stream cap and unknown details keep the relay\'s words', () {
      expect(
          RelayStorageFullException.fromBody(jsonEncode(
                  {'detail': 'Too many device streams: the limit is 256'}))
              .limit,
          RelayStorageLimit.streams);
      final other = RelayStorageFullException.fromBody('not json');
      expect(other.limit, RelayStorageLimit.other);
      expect(other.toString(), contains('not json'));
    });

    test('any 507 from the relay arrives as one', () async {
      final client = _client((_) async => http.Response(
          jsonEncode({
            'detail': 'Storage quota exceeded: using 5 of 4 bytes',
          }),
          507));
      await expectLater(
          client.getUsage(),
          throwsA(isA<RelayStorageFullException>()
              .having((e) => e.limit, 'limit', RelayStorageLimit.quota)));
    });
  });

  group('register', () {
    test('answers the quota the account comes with', () async {
      final client = _client((req) async {
        expect(req.url.path, '/api/v2/auth/register/');
        expect(jsonDecode(req.body),
            {'username': 'amy', 'password': 'password123'});
        return http.Response(
            jsonEncode({
              'message': 'User registered successfully',
              'quota_bytes': 20971520,
            }),
            201);
      });
      expect(await client.register(), 20971520);
    });

    test('an older relay that does not say answers null', () async {
      final client = _client((_) async => http.Response(
          jsonEncode({'message': 'User registered successfully'}), 201));
      expect(await client.register(), isNull);
    });

    Future<String> refusal(int status, Map<String, String> body,
        {String? retryAfter}) async {
      final client = _client((_) async => http.Response(jsonEncode(body), status,
          headers: {if (retryAfter != null) 'retry-after': retryAfter}));
      try {
        await client.register();
      } on RelayRegistrationException catch (e) {
        expect(e.statusCode, status);
        return e.toString();
      }
      fail('register did not throw');
    }

    test('turns refusals into sentences', () async {
      expect(await refusal(403, {'detail': 'Registration is closed'}),
          contains('does not accept sign-ups'));
      expect(
          await refusal(403, {
            'detail': 'Registration is closed: this server has reached its '
                'account limit'
          }),
          contains('account limit'));
      expect(await refusal(409, {'detail': 'Username already exists'}),
          'That user name is already taken.');
      expect(await refusal(422, {'detail': 'too short'}),
          contains('3–50 characters'));
      expect(
          await refusal(
              429,
              {
                'detail': 'Too many accounts registered from this address; '
                    'retry in 86400 seconds'
              },
              retryAfter: '86400'),
          'Too many accounts have been registered from this network today. '
          'Try again in 24 hours.');
      expect(
          await refusal(429, {'detail': 'Too many attempts'},
              retryAfter: '30'),
          'Too many attempts. Try again in 30 seconds.');
      expect(await refusal(500, {'detail': 'boom'}),
          'Registration failed (HTTP 500): boom');
    });
  });
}
