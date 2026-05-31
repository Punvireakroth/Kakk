import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:kakk/services/exchange_rate_service.dart';

void main() {
  late ExchangeRateService service;

  setUp(() {
    service = ExchangeRateService();
    service.clearCache();
    service.testClient = null;
  });

  test('same currency returns 1.0 without HTTP', () async {
    var httpCalled = false;
    service.testClient = MockClient((_) async {
      httpCalled = true;
      return http.Response('{}', 200);
    });

    final result = await service.fetchExchangeRate('USD', 'usd');
    expect(result.isSuccess, isTrue);
    expect(result.rate, 1.0);
    expect(httpCalled, isFalse);
  });

  test('cache returns rate without second HTTP call', () async {
    var callCount = 0;
    service.testClient = MockClient((request) async {
      callCount++;
      return http.Response(
        json.encode({
          'result': 'success',
          'rates': {'KHR': 4100.0, 'EUR': 0.92},
        }),
        200,
      );
    });

    final first = await service.fetchExchangeRate('USD', 'KHR');
    final second = await service.fetchExchangeRate('USD', 'KHR');

    expect(first.isSuccess, isTrue);
    expect(first.rate, 4100.0);
    expect(second.isSuccess, isTrue);
    expect(second.rate, 4100.0);
    expect(callCount, 1);
  });

  test('API error body returns error result', () async {
    service.testClient = MockClient((_) async {
      return http.Response(
        json.encode({'result': 'error', 'error-type': 'invalid-key'}),
        200,
      );
    });

    final result = await service.fetchExchangeRate('USD', 'KHR');
    expect(result.isSuccess, isFalse);
    expect(result.error, contains('API error'));
  });

  test('404 response returns currency not supported error', () async {
    service.testClient = MockClient((_) async {
      return http.Response('Not found', 404);
    });

    final result = await service.fetchExchangeRate('INVALID', 'KHR');
    expect(result.isSuccess, isFalse);
    expect(result.error, contains('not supported'));
  });

  test('convert multiplies amount by fetched rate', () async {
    service.testClient = MockClient((_) async {
      return http.Response(
        json.encode({
          'result': 'success',
          'rates': {'KHR': 4000.0},
        }),
        200,
      );
    });

    final result = await service.convert(
      amount: 10,
      from: 'USD',
      to: 'KHR',
    );

    expect(result.isSuccess, isTrue);
    expect(result.convertedAmount, 40000.0);
    expect(result.rate, 4000.0);
  });
}
